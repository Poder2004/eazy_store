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

  Widget _buildDebtorCard(DebtorResponse debtor) {
    double debtAmount =
        double.tryParse(debtor.currentDebt?.toString() ?? '0') ?? 0.0;

    return Card(
      color: _kCardColor,
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10.0),
        onTap: () {
          Get.to(() => DebtorDetailScreen(debtor: debtor));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            debtor.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            debtor.phone,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey[500],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // ✨ ใช้ Wrap เพื่อให้ข้อความไหลลงบรรทัดใหม่ได้ถ้าฟอนต์ใหญ่
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        Text(
                          'ค้าง ',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                        Text(
                          debtAmount.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const Text(
                          ' บาท',
                          style: TextStyle(fontSize: 13, color: Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // ปุ่มชำระเงิน
              SizedBox(
                height: 32,
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
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    elevation: debtAmount > 0 ? 1 : 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  // ✨ ใช้ FittedBox หุ้มข้อความ เพื่อไม่ให้ปุ่มแตกเวลาฟอนต์ขยาย
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'ชำระเงิน',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ),
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
                      vertical: 4,
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
