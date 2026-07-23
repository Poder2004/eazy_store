import 'package:flutter/material.dart';
import 'package:get/get.dart';

// --- Imports ไฟล์ของคุณ ---
import 'package:eazy_store/page/debt/debtorDetail/debtor_detail.dart';
import 'package:eazy_store/page/menu_bar/bottom_navbar.dart';
import 'package:eazy_store/widgets/pagination_controls.dart';
import '../../../model/response/debtor_response.dart';

// --- Import Controller ---
import 'debt_ledger_controller.dart';

// กำหนดสีหลัก
const Color _kPrimaryColor = Color(0xFF6B8E23);
const Color _kBackgroundColor = Color(0xFFF7F7F7);
const Color _kSearchFillColor = Color(0xFFEFEFEF);
const Color _kCardColor = Color(0xFFFFFFFF);
const Color _kPayButtonColor = Color(0xFF8BC34A);

class DebtLedgerScreen extends StatelessWidget {
  DebtLedgerScreen({super.key});

  // เรียกใช้ Controller
  final DebtLedgerController controller = Get.put(DebtLedgerController());

  // --- Widgets ---
  Widget _buildSearchBar() {
    return Container(
      // ✨ ปลดล็อก height: 48 ออก ปล่อยให้ Container ขยายตามขนาด Font
      decoration: BoxDecoration(
        color: _kSearchFillColor,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.grey.shade300, width: 1.0),
      ),
      child: TextField(
        controller: controller.searchController,
        onChanged: controller.onSearchChanged,
        style: const TextStyle(color: Colors.black87, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'ค้นหารายชื่อ หรือเบอร์โทร',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12.0,
            horizontal: 12.0,
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: Obx(
            () => controller.isSearchEmpty.value
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: controller.clearSearch,
                  ),
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          isDense: true, // ให้ช่องไม่สูงเกินไป
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        // ✨ ห่อด้วย FittedBox ป้องกันปัญหาตัวหนังสือล้นจอ (Right Overflow)
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ส่วนเลือกจำนวนรายการต่อหน้า
              Row(
                children: [
                  const Text(
                    "แสดง: ",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Container(
                    width: 45,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Obx(
                      () => TextField(
                        controller:
                            TextEditingController(
                                text: controller.itemsPerPage.value.toString(),
                              )
                              ..selection = TextSelection.collapsed(
                                offset: controller.itemsPerPage.value
                                    .toString()
                                    .length,
                              ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        onSubmitted: (val) {
                          int? limit = int.tryParse(val);
                          if (limit != null && limit > 0) {
                            controller.updateLimit(limit);
                          }
                        },
                      ),
                    ),
                  ),
                  PopupMenuButton<int>(
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey,
                      size: 24,
                    ),
                    onSelected: (int value) => controller.updateLimit(value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 10, child: Text('10')),
                      const PopupMenuItem(value: 20, child: Text('20')),
                      const PopupMenuItem(value: 50, child: Text('50')),
                    ],
                  ),
                  const Text(
                    "รายการ",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(width: 20), // เพิ่มระยะกันชน
              // ปุ่มเลื่อนหน้า
              Obx(
                () => Row(
                  children: [
                    IconButton(
                      onPressed: controller.currentPage.value > 1
                          ? () => controller.changePage(
                              controller.currentPage.value - 1,
                            )
                          : null,
                      icon: const Icon(Icons.arrow_back_ios, size: 18),
                    ),
                    Text(
                      "${controller.currentPage.value} / ${controller.totalPages.value}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed:
                          controller.currentPage.value <
                              controller.totalPages.value
                          ? () => controller.changePage(
                              controller.currentPage.value + 1,
                            )
                          : null,
                      icon: const Icon(Icons.arrow_forward_ios, size: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebtorCard(DebtorResponse debtor) {
    double debtAmount =
        double.tryParse(debtor.currentDebt?.toString() ?? '0') ?? 0.0;
    final initial = debtor.name.isNotEmpty ? debtor.name.characters.first : '?';

    // ทั้งการ์ดกดเพื่อดูรายละเอียดได้เลย (ตัดลิงก์ "รายละเอียดเพิ่มเติม" ที่กินที่ออก)
    // ปุ่ม "ชำระเงิน" แยกเป็นการกระทำหลักต่างหาก
    return InkWell(
      onTap: () => Get.to(() => DebtorDetailScreen(debtor: debtor)),
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _kCardColor,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _kPrimaryColor.withOpacity(0.1),
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _kPrimaryColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    debtor.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 11, color: Colors.grey[500]),
                      const SizedBox(width: 3),
                      Text(
                        debtor.phone,
                        style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '฿${debtAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 5),
                SizedBox(
                  height: 26,
                  child: ElevatedButton(
                    onPressed: debtAmount > 0
                        ? () => controller.goToPaymentScreen(debtor)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPayButtonColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade500,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7.0),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'ชำระเงิน',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'บัญชีคนค้างชำระ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        backgroundColor: _kBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      // ✨ หุ้ม MediaQuery จำกัดการขยายฟอนต์
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: MediaQuery.textScalerOf(
            context,
          ).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.2),
        ),
        child: Column(
          children: [
            // 1. ส่วน Search Bar วางถาวรด้านบน
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10,
              ),
              child: _buildSearchBar(),
            ),

            // 2. เนื้อหารายการลูกหนี้
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.fetchAllDebtors,
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.allDebtors.isEmpty) {
                    return const Center(child: Text("ไม่พบข้อมูลลูกหนี้"));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 8,
                    ),
                    itemCount: controller.allDebtors.length,
                    itemBuilder: (context, index) {
                      return _buildDebtorCard(controller.allDebtors[index]);
                    },
                  );
                }),
              ),
            ),

            // 3. ส่วน Pagination Controls วางไว้ล่างสุดเหนือ Navbar
            PaginationControls(
              currentPage: controller.currentPage,
              totalPages: controller.totalPages,
              itemsPerPage: controller.itemsPerPage,
              updateLimit: controller.updateLimit,
              changePage: controller.changePage,
              primaryColor: _kPrimaryColor,
              isLoading: controller.isLoading,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3,
        onTap: (index) {
          controller.changeTab(index);
        },
      ),
    );
  }
}
