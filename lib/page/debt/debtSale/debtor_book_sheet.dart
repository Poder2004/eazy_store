import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../model/response/debtor_response.dart';
import 'debt_sale_controller.dart';

const Color _kPrimaryColor = Color(0xFF2563EB);
const Color _kBgColor = Color(0xFFF4F7FA);

/// สมุดลูกหนี้ — Popup รายชื่อลูกหนี้ทั้งหมดของร้าน เรียงตามตัวอักษร เลือกได้ทันที
class DebtorBookSheet {
  static void show(DebtSaleController controller) {
    Get.bottomSheet(
      _DebtorBookBody(controller: controller),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      ignoreSafeArea: false,
    );
  }
}

class _DebtorBookBody extends StatelessWidget {
  final DebtSaleController controller;

  const _DebtorBookBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    // เผื่อพื้นที่คีย์บอร์ด และจำกัดความสูงไม่เกิน 85% ของจอ
    final double keyboardInset = mediaQuery.viewInsets.bottom;
    final double maxHeight = mediaQuery.size.height * 0.85;

    return MediaQuery(
      // คุมสเกลฟอนต์ ไม่ให้ผู้ใช้ที่ตั้งฟอนต์ใหญ่มากทำให้เลย์เอาต์ล้น
      data: mediaQuery.copyWith(
        textScaler: MediaQuery.textScalerOf(
          context,
        ).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.2),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHandle(),
              _buildHeader(context),
              _buildSearchField(),
              const SizedBox(height: 8),
              Flexible(child: _buildList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 6),
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 8, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kPrimaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: _kPrimaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // ใช้ Expanded กันข้อความล้นบนจอแคบ
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "สมุดลูกหนี้",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Obx(
                  () => Text(
                    controller.isLoadingBook.value
                        ? "กำลังโหลดรายชื่อ..."
                        : "ทั้งหมด ${controller.allDebtors.length} คน",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: "โหลดรายชื่อใหม่",
            onPressed: () => controller.loadAllDebtors(forceRefresh: true),
            icon: Icon(Icons.refresh_rounded, color: Colors.grey.shade600),
          ),
          IconButton(
            tooltip: "ปิด",
            onPressed: () => Get.back(),
            icon: Icon(Icons.close_rounded, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: controller.bookSearchController,
        onChanged: controller.filterBook,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: "ค้นหาชื่อหรือเบอร์โทรในสมุด...",
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
          suffixIcon: Obx(() {
            // กำลังถามเซิร์ฟเวอร์ (กรณีค้นไม่เจอในเครื่อง)
            if (controller.isSearchingBook.value) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            if (controller.bookKeyword.value.isEmpty) {
              return const SizedBox.shrink();
            }
            return IconButton(
              icon: const Icon(Icons.cancel_rounded, color: Colors.grey),
              onPressed: () {
                controller.bookSearchController.clear();
                controller.filterBook("");
              },
            );
          }),
          filled: true,
          fillColor: _kBgColor,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return Obx(() {
      if (controller.isLoadingBook.value && controller.allDebtors.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (controller.bookError.value.isNotEmpty) {
        return _buildEmptyState(
          icon: Icons.cloud_off_rounded,
          message: controller.bookError.value,
          actionLabel: "ลองใหม่อีกครั้ง",
          onAction: () => controller.loadAllDebtors(forceRefresh: true),
        );
      }

      if (controller.bookResults.isEmpty) {
        return _buildEmptyState(
          icon: Icons.person_search_rounded,
          message: controller.allDebtors.isEmpty
              ? "ยังไม่มีลูกหนี้ในร้านนี้\nกดปุ่ม \"สร้างลูกหนี้ใหม่\" เพื่อเพิ่มลูกหนี้"
              : "ไม่พบลูกหนี้ที่ค้นหา",
        );
      }

      final grouped = controller.groupedBookResults();
      final letters = grouped.keys.toList();

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
        itemCount: letters.length,
        itemBuilder: (context, index) {
          final String letter = letters[index];
          final List<DebtorResponse> items = grouped[letter]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // หัวข้อตัวอักษร
              Container(
                width: double.infinity,
                color: _kBgColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                child: Text(
                  letter,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _kPrimaryColor,
                  ),
                ),
              ),
              ...items.map((debtor) => _buildDebtorTile(debtor)),
            ],
          );
        },
      );
    });
  }

  Widget _buildDebtorTile(DebtorResponse debtor) {
    final double remain = debtor.creditLimit - debtor.currentDebt;
    final bool isSelected =
        controller.selectedDebtor?.debtorId == debtor.debtorId;

    // ใช้ Row เองแทน ListTile เพื่อคุมความสูงได้ ไม่ overflow เวลาตัวเลข/ฟอนต์ใหญ่
    return Material(
      color: isSelected ? _kPrimaryColor.withOpacity(0.06) : Colors.white,
      child: InkWell(
        onTap: () => controller.selectDebtorFromBook(debtor),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: _kPrimaryColor.withOpacity(0.1),
                backgroundImage: debtor.imgDebtor.isNotEmpty
                    ? NetworkImage(debtor.imgDebtor)
                    : null,
                child: debtor.imgDebtor.isEmpty
                    ? Text(
                        debtor.name.isNotEmpty
                            ? debtor.name[0].toUpperCase()
                            : "?",
                        style: const TextStyle(
                          color: _kPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // ชื่อ + เบอร์โทร (ยืดตามพื้นที่ที่เหลือ)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debtor.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      debtor.phone,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // ยอดคงเหลือ จำกัดความกว้างและย่อฟอนต์อัตโนมัติถ้าตัวเลขยาว
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "คงเหลือ",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        "${remain.toInt()} ฿",
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: remain > 0
                              ? Colors.green.shade600
                              : Colors.red.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // เครื่องหมายถูก วางแนวนอน ไม่ดันความสูงของแถว
              if (isSelected) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.check_circle_rounded,
                  color: _kPrimaryColor,
                  size: 18,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              label: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }
}
