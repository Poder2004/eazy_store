import 'package:flutter/material.dart';
import 'package:get/get.dart';

// --- Imports ไฟล์ของคุณ ---
import 'package:eazy_store/page/debt/debtorDetail/debtor_detail.dart';
import 'package:eazy_store/page/menu_bar/bottom_navbar.dart';
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

    return Card(
      color: _kCardColor,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(16.0), // ปรับ Padding ให้ดูโปร่งขึ้น
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    debtor.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    debtor.phone,
                    style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 6),
                  // ✨ เปลี่ยนจากการใช้ Row มาใช้ Wrap เพื่อให้ข้อความไหลลงบรรทัดใหม่ได้ถ้าฟอนต์ใหญ่
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      Text(
                        'ค้าง ',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      Text(
                        debtAmount.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const Text(
                        ' บาท',
                        style: TextStyle(fontSize: 16, color: Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () {
                      Get.to(() => DebtorDetailScreen(debtor: debtor));
                    },
                    // ✨ ลบ Row ทิ้งไปเลย ให้เหลือแค่ Text และขีดเส้นใต้ให้รู้ว่ากดได้ (ป้องกัน Overflow)
                    child: const Text(
                      'รายละเอียดเพิ่มเติม',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color.fromARGB(255, 0, 119, 255),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // ส่วนปุ่มชำระเงิน
            Column(
              children: [
                SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () => controller.goToPaymentScreen(debtor),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPayButtonColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    // ✨ ใช้ FittedBox หุ้มข้อความ เพื่อไม่ให้ปุ่มแตกเวลาฟอนต์ขยาย
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'ชำระเงิน',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
            _buildPaginationControls(),
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
