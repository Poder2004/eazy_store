import 'package:eazy_store/page/menu_bar/bottom_navbar.dart';
import 'package:eazy_store/page/product/add_product/add_product.dart';
import 'package:eazy_store/page/product/add_stock/add_stock.dart';
import 'package:eazy_store/page/%E0%B8%A2%E0%B8%B1%E0%B8%87%E0%B9%84%E0%B8%A1%E0%B9%88%E0%B9%84%E0%B8%94%E0%B9%89%E0%B8%97%E0%B8%B3/buy_products.dart';
import 'package:eazy_store/page/product/check_price_and_stock/check_price.dart';
import 'package:eazy_store/page/product/check_price_and_stock/check_stock.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ----------------------------------------------------------------------
// 1. Controller: จัดการข้อมูลร้านค้าและ Tab
// ----------------------------------------------------------------------
class HomeController extends GetxController {
  var currentIndex = 0.obs;
  var shopName = "กำลังโหลด...".obs;
  var shopId = 0.obs;
  var dailyTotal =
      "12,450.00".obs; // ตัวอย่างยอดขาย (สามารถดึงจาก API ได้ในอนาคต)

  @override
  void onInit() {
    super.onInit();
    loadShopData();
  }

  // ดึงข้อมูลร้านค้าที่ผู้ใช้เลือกมาจาก SharedPreferences
  void loadShopData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    shopId.value = prefs.getInt('shopId') ?? 0;
    shopName.value = prefs.getString('shopName') ?? "ยังไม่ได้เลือกร้าน";
    print("🏠 ปัจจุบันจัดการร้าน: ${shopName.value} (ID: ${shopId.value})");
  }

  void changeTab(int index) {
    currentIndex.value = index;
  }
}

// ----------------------------------------------------------------------
// 2. The View: หน้าจอหลัก (HomePage)
// ----------------------------------------------------------------------
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // กำหนดสีตามธีมพรีเมียมของคุณ
    const Color headerBgColor = Color(0xFFE55D30); // ส้มเข้ม
    const Color scaffoldBgColor = Color(0xFFF7F7F7); // พื้นหลังเทาอ่อน
    const Color iconColor = Color(0xFF64DD17); // เขียวสดใส

    final HomeController controller = Get.put(HomeController());

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- 1. ส่วน Header (ชื่อร้านที่ดึงมาจาก SharedPreferences) ---
            _buildHeader(context, controller, headerBgColor: headerBgColor),

            // --- 2. ส่วนเมนูรายการ ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  _buildMenuTile(
                    icon: Icons.add_circle_outline,
                    iconColor: iconColor,
                    title: "เพิ่มสินค้า",
                    subtitle: "สร้างรายการสินค้าใหม่สำหรับร้านนี้",
                    onTap: () => Get.to(() => const AddProductScreen()),
                  ),
                  _buildMenuTile(
                    icon: Icons.inventory_2_outlined,
                    iconColor: Colors.blue.shade600,
                    title: "เพิ่มสต็อกสินค้า",
                    subtitle: "เติมจำนวนสินค้าในคลัง",
                    onTap: () => Get.to(() => const AddStockScreen()),
                  ),
                  _buildMenuTile(
                    icon: Icons.local_offer_outlined,
                    iconColor: Colors.orange.shade700,
                    title: "เช็คราคาสินค้า",
                    subtitle: "สแกนเพื่อดูราคาขายปัจจุบัน",
                    onTap: () => Get.to(() => const CheckPriceScreen()),
                  ),
                  _buildMenuTile(
                    icon: Icons.fact_check_outlined,
                    iconColor: Colors.purple.shade600,
                    title: "เช็คสต็อกสินค้า",
                    subtitle: "ตรวจสอบยอดคงเหลือรายชิ้น",
                    onTap: () => Get.to(() => const CheckStockScreen()),
                  ),
                  _buildMenuTile(
                    icon: Icons.receipt_long,
                    iconColor: Colors.teal.shade500,
                    title: "สั่งซื้อสินค้า",
                    subtitle: "รายการจัดซื้อและประวัติการสั่ง",
                    onTap: () => Get.to(() => const BuyProductsScreen()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // --- 3. Bottom Navigation Bar ---
      bottomNavigationBar: Obx(
        () => BottomNavBar(
          currentIndex: controller.currentIndex.value,
          onTap: controller.changeTab,
        ),
      ),
    );
  }

  // --- Widget 1: Header (ใช้ Obx เพื่อแสดงชื่อร้านค้าแบบ Dynamic) ---
  Widget _buildHeader(
    BuildContext context,
    HomeController controller, {
    required Color headerBgColor,
  }) {
    final double topContainerHeight = MediaQuery.of(context).size.height * 0.38;

    return Container(
      width: double.infinity,
      height: topContainerHeight,
      decoration: BoxDecoration(
        color: headerBgColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 60,
            left: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ยินดีต้อนรับเข้าสู่",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                // ✨ แสดงชื่อร้านค้าที่เลือกมา
                Obx(
                  () => Text(
                    controller.shopName.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: _buildDailyReportCard(controller),
          ),
        ],
      ),
    );
  }

  // --- Widget 2: Daily Report Card ---
  Widget _buildDailyReportCard(HomeController controller) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(Icons.trending_up, color: Colors.red.shade400, size: 28),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Obx(
                () => Text(
                  "฿ ${controller.dailyTotal.value}",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
              ),
              const Spacer(),
              _buildSmallBar(25, Colors.grey.shade200),
              _buildSmallBar(45, Colors.red.shade300),
              _buildSmallBar(60, Colors.red.shade600),
              _buildSmallBar(35, Colors.grey.shade200),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "อัปเดตล่าสุดเมื่อสักครู่",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBar(double height, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      height: height,
      width: 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // --- Widget 3: Menu Tile (List Item Style) ---
  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 15,
        ),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D2D),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
      ),
    );
  }
}
