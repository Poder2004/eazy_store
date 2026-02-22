import 'package:flutter/material.dart';
import 'package:get/get.dart';

// --- Imports ไฟล์ของคุณ ---
import 'package:eazy_store/page/debt/debtorDetail/debtor_detail.dart';
import 'package:eazy_store/menu_bar/bottom_navbar.dart';
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
      height: 48,
      decoration: BoxDecoration(
        color: _kSearchFillColor,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.grey.shade300, width: 1.0),
      ),
      child: Obx(() => TextField(
        controller: controller.searchController,
        onChanged: controller.onSearchChanged,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'ค้นหารายชื่อ หรือเบอร์โทร',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10.0,
            horizontal: 12.0,
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          // ปุ่มกากบาทลบคำค้นหา
          suffixIcon: controller.searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: controller.clearSearch,
                )
              : null,
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
        ),
      )),
    );
  }

  Widget _buildSearchResultsDropdown() {
    return Obx(() {
      if (!controller.showDropdown.value) return const SizedBox.shrink();

      return Positioned(
        top: 60,
        left: 0,
        right: 0,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 250),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: controller.searchResults.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Text("ไม่พบข้อมูล", textAlign: TextAlign.center),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: controller.searchResults.length,
                  separatorBuilder: (ctx, i) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final item = controller.searchResults[i];
                    return ListTile(
                      title: Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(item.phone),
                      trailing: const Icon(
                        Icons.search,
                        size: 18,
                        color: Colors.grey,
                      ), 
                      onTap: () => controller.selectFromDropdown(item),
                    );
                  },
                ),
        ),
      );
    });
  }

  Widget _buildDebtorCard(DebtorResponse debtor) {
    double debtAmount = double.tryParse(debtor.currentDebt?.toString() ?? '0') ?? 0.0;

    return Card(
      color: _kCardColor,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
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
                  ),
                  Text(
                    debtor.phone,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'ค้าง ',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      Text(
                        debtAmount.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.red,
                        ),
                      ),
                      const Text(
                        ' บาท',
                        style: TextStyle(fontSize: 16, color: Colors.red),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      // อัปเดตการนำทางเป็น GetX ให้เข้ากับโปรเจกต์
                      Get.to(() => DebtorDetailScreen(debtor: debtor));
                    },
                    child: Row(
                      children: const [
                        Text(
                          'รายละเอียดเพิ่มเติม',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color.fromARGB(255, 0, 119, 255),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                SizedBox(
                  height: 35,
                  child: ElevatedButton(
                    onPressed: () => controller.goToPaymentScreen(debtor),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPayButtonColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      elevation: 3,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: const Text(
                      'ชำระเงิน',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: _kBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: controller.fetchAllDebtors,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Stack(
            children: [
              // --- Layer ล่าง: เนื้อหาหลัก ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 70), // เว้นที่ให้ Search Bar
                  const Text(
                    'รายชื่อทั้งหมด',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Expanded(
                    child: Obx(() {
                      if (controller.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (controller.allDebtors.isEmpty) {
                        return const Center(
                          child: Text("ยังไม่มีรายการค้างชำระ (หรือค้นหาไม่เจอ)"),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 5, bottom: 20),
                        itemCount: controller.allDebtors.length,
                        itemBuilder: (context, index) {
                          return _buildDebtorCard(controller.allDebtors[index]);
                        },
                      );
                    }),
                  ),
                ],
              ),

              // --- Layer บน: Search Bar และ Dropdown ---
              Column(
                children: [_buildSearchBar(), _buildSearchResultsDropdown()],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Obx(() => BottomNavBar(
        currentIndex: controller.selectedIndex.value,
        onTap: controller.onItemTapped,
      )),
    );
  }
}