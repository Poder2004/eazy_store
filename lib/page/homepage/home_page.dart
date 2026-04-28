import 'package:eazy_store/page/homepage/home_controller.dart';
import 'package:eazy_store/page/menu_bar/bottom_navbar.dart';
import 'package:eazy_store/page/product/add_product/add_product.dart';
import 'package:eazy_store/page/product/add_stock/add_stock.dart';
import 'package:eazy_store/page/product/checkStock/check_stock.dart';
import 'package:eazy_store/page/product/check_price/check_price.dart';
import 'package:eazy_store/page/sale_producct/sale/checkout_controller.dart';
import 'package:eazy_store/page/sale_producct/sale/checkout_page.dart';
import 'package:eazy_store/page/sale_producct/scanBarcode/scan_barcode.dart';
import 'package:eazy_store/page/order_products/buyProducts/buy_products.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color headerBgColor = Color(0xFFE55D30);
    const Color scaffoldBgColor = Color(0xFFF8FAFC);
    const Color iconColor = Color(0xFF10B981);

    final HomeController controller = Get.put(HomeController());

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      // ✨ เคล็ดลับ: จำกัดการขยายฟอนต์ไม่เกิน 1.3 เท่า ป้องกัน UI แตก
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: MediaQuery.textScalerOf(
            context,
          ).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.3),
        ),
        child: RefreshIndicator(
          onRefresh: () async => controller.fetchTodaySales(),
          color: headerBgColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // --- ส่วน Header สีแดง + กล่องยอดขาย ---
                _buildHeader(context, controller, headerBgColor: headerBgColor),

                // --- ส่วนเมนูด้านล่าง ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 20,
                      ), // เพิ่มระยะห่างให้ไม่ชิดกล่องขาวเกินไป
                      _buildScanToSellCard(context),
                      const SizedBox(height: 25),
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
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          controller.changeTab(index);
        },
      ),
    );
  }

  // ✨ โครงสร้าง Header แบบใหม่ที่คำนวณความสูงอัตโนมัติ หมดปัญหาทับซ้อน
  Widget _buildHeader(
    BuildContext context,
    HomeController controller, {
    required Color headerBgColor,
  }) {
    final CheckoutController checkoutCtrl =
        Get.isRegistered<CheckoutController>()
        ? Get.find<CheckoutController>()
        : Get.put(CheckoutController());

    return Stack(
      children: [
        // 1. พื้นหลังสีแดง (จะมีความสูงเท่ากับ Column ลบด้วยระยะที่เราให้มันเหลื่อม)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 60, // ปล่อยให้การ์ดสีขาวห้อยทะลุลงมา 60px
          child: Container(
            decoration: BoxDecoration(
              color: headerBgColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
          ),
        ),

        // 2. เนื้อหาหลัก (ตัวนี้จะดันความสูงของ Header ทั้งหมดอัตโนมัติ)
        SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- ส่วนต้อนรับ และ ไอคอนตะกร้า ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "ยินดีต้อนรับเข้าสู่",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // ใช้ Wrap ป้องกันข้อความชื่อร้านยาวจนแตก
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Obx(
                                () => Text(
                                  controller.shopName.value,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "เฮง เฮง เฮง รวยๆ",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () => Get.to(() => const CheckoutPage()),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.shopping_basket,
                              color: Color(0xFF10B981),
                              size: 28,
                            ),
                          ),
                          Obx(() {
                            int itemCount = checkoutCtrl.cartItems.length;
                            if (itemCount == 0) return const SizedBox.shrink();
                            return Positioned(
                              right: -2,
                              top: -7,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  '$itemCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- ส่วนกล่องยอดขาย (ซ้อนทับกรอบสีแดงลงมา) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildDailyReportCard(controller),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyReportCard(HomeController controller) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "ยอดขายรวมวันนี้",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Obx(
                () => Icon(
                  controller.isTrendUp.value
                      ? Icons.trending_up
                      : Icons.trending_down,
                  color: controller.isTrendUp.value
                      ? Colors.green.shade500
                      : Colors.red.shade400,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ✨ ห่อด้วย Expanded + FittedBox ป้องกันตัวเลขยอดขายยาวทะลุกราฟ
              Expanded(
                child: Obx(
                  () => FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "฿ ${controller.formattedTotal}",
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Obx(() {
                final color = controller.isTrendUp.value
                    ? Colors.green.shade400
                    : Colors.red.shade400;
                return Row(
                  children: [
                    _buildSmallBar(25, Colors.grey.shade200),
                    _buildSmallBar(45, color.withOpacity(0.4)),
                    _buildSmallBar(60, color),
                    _buildSmallBar(35, Colors.grey.shade200),
                  ],
                );
              }),
            ],
          ),
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
                  color: const Color(0xFF10B981),
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
                  color: const Color(0xFFF59E0B),
                  icon: Icons.info_outline_rounded,
                ),
              ],
            ),
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

  Widget _buildSummaryItem({
    required String label,
    required RxString value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              // ✨ ห่อด้วย Flexible ป้องกันคำยาวเกิน
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // ✨ ใช้ FittedBox เพื่อบีบตัวเลขหากฟอนต์ใหญ่เกินไป
          Obx(
            () => FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "฿ ${value.value}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanToSellCard(BuildContext context) {
    final HomeController homeController = Get.find<HomeController>();
    return InkWell(
      onTap: () async {
        var barcode = await Get.to(() => const ScanBarcodePage());
        if (barcode != null && barcode is String) {
          CheckoutController checkoutCtrl =
              Get.isRegistered<CheckoutController>()
              ? Get.find()
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
          color: const Color(0xFF38BDF8),
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
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
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
