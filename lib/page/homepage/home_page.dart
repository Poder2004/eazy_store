import 'package:eazy_store/api/api_dashboad.dart';
import 'package:eazy_store/page/menu_bar/bottom_navbar.dart';
import 'package:eazy_store/page/product/add_product/add_product.dart';
import 'package:eazy_store/page/product/add_stock/add_stock.dart';
import 'package:eazy_store/page/product/checkStock/check_stock.dart';
import 'package:eazy_store/page/product/check_price/check_price.dart';
import 'package:eazy_store/page/sale_producct/sale/checkout_controller.dart';
import 'package:eazy_store/page/sale_producct/sale/checkout_page.dart';
import 'package:eazy_store/page/sale_producct/scanBarcode/scan_barcode.dart';
import 'package:eazy_store/page/wait_coming/buy_products.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ----------------------------------------------------------------------
// 1. Controller: จัดการข้อมูลร้านค้าและยอดขายแยกประเภท
// ----------------------------------------------------------------------
class HomeController extends GetxController {
  var currentIndex = 0.obs;
  var shopName = "กำลังโหลด...".obs;
  var shopId = 0.obs;

  // ตัวแปรสำหรับยอดขาย (แยกประเภท)
  var dailyTotal = "0".obs; // ยอดขายรวม (Revenue)
  var actualPaid = "0".obs; // เงินที่ได้รับจริง (Cash/Transfer)
  var debtAmount = "0".obs; // ค้างชำระเพิ่ม (New Debt)
  var isSalesLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadShopData();
  }

  void loadShopData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    shopId.value = prefs.getInt('shopId') ?? 0;
    shopName.value = prefs.getString('shopName') ?? "ยังไม่ได้เลือกร้าน";
    if (shopId.value != 0) fetchTodaySales();
  }

  Future<void> fetchTodaySales() async {
    isSalesLoading.value = true;
    try {
      DateTime now = DateTime.now();
      String todayStr = DateFormat('yyyy-MM-dd').format(now);

      final summary = await ApiDashboad.getSalesSummary(
        shopId.value,
        todayStr,
        todayStr,
      );

      if (summary != null) {
        final f = NumberFormat('#,##0');
        dailyTotal.value = f.format(summary.totalRevenue);
        actualPaid.value = f.format(summary.actualPaid);
        debtAmount.value = f.format(summary.debtAmount);
      }
    } catch (e) {
      print("Error fetching today sales: $e");
    } finally {
      isSalesLoading.value = false;
    }
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
    const Color headerBgColor = Color(0xFFE55D30); // ส้มอิฐ
    const Color scaffoldBgColor = Color(0xFFF8FAFC);
    const Color iconColor = Color(0xFF10B981);

    final HomeController controller = Get.put(HomeController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.shopId.value != 0) controller.fetchTodaySales();
    });

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: RefreshIndicator(
        onRefresh: () async => controller.fetchTodaySales(),
        color: headerBgColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // --- 1. ส่วน Header และ Report Card ---
              _buildHeader(context, controller, headerBgColor: headerBgColor),

              // --- 2. ส่วนเมนูรายการ ---
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    _buildScanToSellCard(context),
                    const SizedBox(height: 16),
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
                      iconColor: Colors.orange.shade600,
                      title: "เช็คราคาสินค้า",
                      subtitle: "สแกนเพื่อดูราคาขายปัจจุบัน",
                      onTap: () => Get.to(() => const CheckPriceScreen()),
                    ),
                    _buildMenuTile(
                      icon: Icons.fact_check_outlined,
                      iconColor: Colors.purple.shade500,
                      title: "เช็คสต็อกสินค้า",
                      subtitle: "ตรวจสอบยอดคงเหลือรายชิ้น",
                      onTap: () => Get.to(() => const CheckStockScreen()),
                    ),
                    _buildMenuTile(
                      icon: Icons.receipt_long,
                      iconColor: Colors.teal.shade500,
                      title: "ทำใบสั่งสินค้า",
                      subtitle: "เลือกสินค้าและส่งออกเป็นไฟล์ PDF",
                      onTap: () => Get.to(() => const BuyProductsScreen()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Obx(
        () => BottomNavBar(
          currentIndex: controller.currentIndex.value,
          onTap: controller.changeTab,
        ),
      ),
    );
  }

  // ✨ ขยาย Header กลับไปกว้างและโปร่งสบายเหมือนเดิม
  Widget _buildHeader(
    BuildContext context,
    HomeController controller, {
    required Color headerBgColor,
  }) {
    // 🔥 ปรับความสูงกลับมาเป็น 0.38 เพื่อให้กล่องส้มมีพื้นที่มากขึ้น
    final double topContainerHeight = MediaQuery.of(context).size.height * 0.38;

    return SizedBox(
      width: double.infinity,
      height: topContainerHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            height: topContainerHeight - 50,
            decoration: BoxDecoration(
              color: headerBgColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ยินดีต้อนรับเข้าสู่",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Obx(
                  () => Text(
                    controller.shopName.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28, // ปรับให้ตัวใหญ่ขึ้นเล็กน้อย
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                  
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: -5,
            
            child: _buildDailyReportCard(controller),
          ),
        ],
      ),
    );
  }

  // ✨ นำกราฟแท่งแบบดั้งเดิมที่สวยงามกลับมา พร้อมผสมกับข้อมูลแบบใหม่
  Widget _buildDailyReportCard(HomeController controller) {
    return Container(
      padding: const EdgeInsets.all(25), // Padding เดิมที่สวยพอดี
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25), // รัศมีขอบโค้งเดิม
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- ส่วนบน: แบบดั้งเดิม (มีกราฟแท่ง) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "ยอดขายรวมวันนี้",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              // เอากลับมา: ไอคอนลูกศรสีแดงมุมขวาบน
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
                    fontSize: 32, // ตัวเลขใหญ่ชัดเจนแบบเก่า
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const Spacer(),
              // เอากลับมา: กราฟแท่ง 4 แท่ง สวยๆ
              _buildSmallBar(25, Colors.grey.shade200),
              _buildSmallBar(45, Colors.red.shade300),
              _buildSmallBar(60, Colors.red.shade600),
              _buildSmallBar(35, Colors.grey.shade200),
            ],
          ),

          // --- ส่วนล่าง: ข้อมูลรับเงินจริงและค้างชำระ (เพิ่มเข้ามาใหม่แบบเนียนๆ) ---
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Divider(color: Color(0xFFF1F5F9), thickness: 1.5, height: 1),
          ),
          IntrinsicHeight(
            child: Row(
              children: [
                _buildSummaryItem(
                  label: "รับเงินจริง",
                  value: controller.actualPaid,
                  color: const Color(0xFF10B981), // สีเขียว
                  icon: Icons.check_circle_outline_rounded,
                ),
                const VerticalDivider(
                  color: Color(0xFFF1F5F9),
                  thickness: 1.5,
                  width: 30,
                ),
                _buildSummaryItem(
                  label: "ค้างชำระ",
                  value: controller.debtAmount,
                  color: const Color(0xFFF59E0B), // สีส้ม
                  icon: Icons.info_outline_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✨ ฟังก์ชันกราฟแท่งเดิมที่เอามาใช้ใหม่
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

  Widget _buildSummaryItem({
    required String label,
    required RxString value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Obx(
            () => Text(
              "฿ ${value.value}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✨ ปุ่มสแกนเพื่อขาย (ปรับให้โค้งและมีแสงเงาสวยขึ้น)
  Widget _buildScanToSellCard(BuildContext context) {
    final HomeController homeController = Get.find<HomeController>();
    return InkWell(
      onTap: () async {
        var barcode = await Get.to(() => const ScanBarcodePage());
        if (barcode != null && barcode is String) {
          CheckoutController checkoutCtrl =
              Get.isRegistered<CheckoutController>()
              ? Get.find<CheckoutController>()
              : Get.put(CheckoutController());
          Get.to(() => const CheckoutPage());
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await checkoutCtrl.checkShopAndLoadData();
            await checkoutCtrl.fetchFreshProducts();
            checkoutCtrl.addProductByBarcode(barcode);
            homeController.changeTab(2);
          });
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF38BDF8), // สีฟ้าน้ำทะเล
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF38BDF8).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "สแกนเพื่อขาย",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "เริ่มการขายด้วยบาร์โค้ดทันที",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white70,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  // ✨ เมนูย่อยต่างๆ ปรับแสงเงาให้ดูเป็นระเบียบ
  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02), // เงาบางมากๆ
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: Color(0xFF1E293B),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: Colors.grey,
        ),
      ),
    );
  }
}
