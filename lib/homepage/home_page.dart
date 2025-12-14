import 'package:eazy_store/menu_bar/bottom_navbar.dart';
import 'package:eazy_store/page/add_product.dart';
import 'package:eazy_store/page/add_stock.dart';
import 'package:eazy_store/page/buy_products.dart';
import 'package:eazy_store/page/check_price.dart';
import 'package:eazy_store/page/check_stock.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// เนื่องจาก BottomNavBar ไม่ปรากฏในภาพที่ 1 แต่โค้ดเดิมมี ผมจึง Comment Out ส่วนนี้
// import '../menu_bar/bottom_navbar.dart';

// ส่วน Controller และ Theme Color ยังคงไว้ตามเดิม
class HomeController extends GetxController {
  var currentIndex = 0.obs;

  void changeTab(int index) {
    currentIndex.value = index;
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  
  int get _selectedIndex => 0;
  

void _onItemTapped(int index) {
    setState(() {
      var _selectedIndex = index;
    });
    print('Tab tapped: $index');
  }
  @override
  Widget build(BuildContext context) {
    // กำหนดสีตามภาพ: สีแดง/ส้มเข้มที่ใช้ใน Header
    const Color headerBgColor = Color(0xFFE55D30);
    // กำหนดสีตามภาพ: สีพื้นหลัง (ในภาพส่วนใหญ่เป็นสีขาว แต่ใช้สีพื้นของ Scaffold เป็นสีขาว/อ่อน)
    const Color scaffoldBgColor = Color(0xFFF7F7F7); // สีพื้นหลังที่อ่อนกว่า
    // กำหนดสีตามภาพ: สีเขียวที่ใช้ในไอคอน (ใกล้เคียงกับสีเขียวในภาพที่ 1)
    const Color iconColor = Color(0xFF64DD17);

    // ตัวแปรสำหรับข้อความ (ไม่ได้ใช้ในเวอร์ชั่นที่ตรงกับภาพ)
    // final Color textDark = const Color(0xFF2D2D2D);

    // Initializations
    final HomeController controller = Get.put(HomeController());

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      // ลบ SafeArea ออก เพื่อให้ Header สีส้มไปถึงขอบด้านบน
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- 1. ส่วน Header สีส้ม/แดง (ชื่อร้านและรายงานประจำวัน) ---
            _buildHeader(
              context,
              headerBgColor: headerBgColor,
            ),

            // --- 2. ส่วนเมนูรายการ (List Tile Style) ---
            // ใช้ Container เพื่อจัด Padding ในส่วนนี้
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  // 2.1 เพิ่มสินค้า
                  _buildMenuTile(
                    icon: Icons.add_circle_outline, // ใช้ Icon แทน Image.asset
                    iconColor: iconColor,
                    title: "เพิ่มสินค้า",
                    subtitle: "Create new product item",
                    onTap: () {
                      Get.to(() => const AddProductScreen());
                    },
                  ),
                  _divider(),
                  // 2.2 เพิ่มสต็อกสินค้า
                  _buildMenuTile(
                    icon: Icons.inventory_2_outlined,
                    iconColor: Colors.blue.shade600,
                    title: "เพิ่มสต็อกสินค้า",
                    subtitle: "Add inventory quantity",
                    onTap: () {
                      Get.to(() => const AddStockScreen());
                    },
                  ),
                  _divider(),
                  // 2.3 เช็คราคาสินค้า
                  _buildMenuTile(
                    icon: Icons.local_offer_outlined,
                    iconColor: Colors.orange.shade700,
                    title: "เช็คราคาสินค้า",
                    subtitle: "Scan to check prices",
                    onTap: () {
                      Get.to(() => const CheckPriceScreen());
                    },
                  ),
                  _divider(),
                  // 2.4 เช็คสต็อกสินค้า
                  _buildMenuTile(
                    icon: Icons.fact_check_outlined,
                    iconColor: Colors.purple.shade600,
                    title: "เช็คสต็อกสินค้า",
                    subtitle: "Verify current stock levels",
                    onTap: () {
                      Get.to(() => const CheckStockScreen());
                    },
                  ),
                  _divider(),
                  // 2.5 สั่งซื้อสินค้า
                  // รายการนี้ถูกแยกออกมาในโค้ดเดิม แต่ในภาพเป็นแค่ ListTile ธรรมดา
                  _buildMenuTile(
                    icon: Icons.receipt_long,
                    iconColor: Colors.teal.shade500,
                    title: "สั่งซื้อสินค้า",
                    subtitle: "Purchase orders",
                    onTap: () {
                      Get.to(() => const BuyProductsScreen());
                      print("กดปุ่มสั่งซื้อสินค้า");
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

       bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  // --- Widget 1: Header (ชื่อร้าน + รายงานประจำวัน) ---
  Widget _buildHeader(BuildContext context, {required Color headerBgColor}) {
    // หาความสูงที่เหลือจากการวาง Report Card (โดยประมาณ)
    final double topContainerHeight = MediaQuery.of(context).size.height * 0.35;

    return Container(
      width: double.infinity,
      height: topContainerHeight, // กำหนดความสูงตามภาพ
      decoration: BoxDecoration(
        color: headerBgColor,
      ),
      child: Stack(
        children: [
          // 1.1 Text ชื่อร้าน (ตำแหน่งตามภาพ)
          Positioned(
            top: 50,
            left: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "ร่ำรวย เงิน ทอง",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "ร้านจันทร์เพ็ญ",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // 1.2 "Slide to view"
          Positioned(
            top: 150, // ตำแหน่ง "Slide to view"
            right: 20,
            child: Text(
              "Slide to view",
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
          // 1.3 Card รายงานประจำวัน (ตำแหน่งอยู่ด้านล่างของ Header)
          Positioned(
            left: 20,
            right: 20,
            bottom: 0,
            child: _buildDailyReportCard(),
          ),
        ],
      ),
    );
  }

  // --- Widget 2: Daily Report Card (ยอดขายวันนี้) ---
  Widget _buildDailyReportCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "ยอดขายวันนี้",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              // Icon กราฟเล็กๆ
              Icon(
                Icons.trending_up,
                color: Colors.red.shade400,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "฿ 12,450.00",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const Spacer(),
              // แถบกราฟเล็กๆ (จำลอง)
              _buildSmallBar(20, Colors.grey.shade300),
              _buildSmallBar(40, Colors.red.shade400),
              _buildSmallBar(50, Colors.red.shade600),
              _buildSmallBar(30, Colors.grey.shade300),
              _buildSmallBar(15, Colors.grey.shade300),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "Updated: 10:30 AM",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Widget ช่วยสร้าง Bar เล็กๆ ใน Daily Report Card
  Widget _buildSmallBar(double height, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Container(
        height: height,
        width: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // --- Widget 3: Menu Tile (รายการเมนูแบบแถว) ---
  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8), // เพิ่มระยะห่างแนวตั้ง
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15), // มุมโค้งมนของ ListTile
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent, // ใช้ Material เพื่อให้มี InkWell effect
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10),
            child: Row(
              children: [
                // Icon วงกลม
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1), // สีจางๆ เป็นพื้นหลัง
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 30,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 15),
                // ข้อความหลักและข้อความรอง
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow Icon
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: Color(0xFF64DD17), // สีเขียวตามภาพ
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget ตัวแบ่ง (ถ้าต้องการ)
  Widget _divider() {
    return const SizedBox(height: 2);
  }
  
  void setState(Null Function() param0) {}
}
