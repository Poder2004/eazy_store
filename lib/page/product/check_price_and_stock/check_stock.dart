import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/menu_bar/bottom_navbar.dart';
import 'package:eazy_store/model/request/product_model.dart';
import 'package:eazy_store/page/product/product_detail/product_detail.dart';
import 'package:eazy_store/sale_producct/scan_barcode.dart';
// ⚠️ อย่าลืม Import หน้าสแกนของคุณ
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ----------------------------------------------------------------------
// 1. Controller
// ----------------------------------------------------------------------
class StockController extends GetxController {
  var isLoading = true.obs;
  var products = <Product>[].obs;
  var filteredProducts = <Product>[].obs;
  var selectedIndex = 0.obs;

  // เพิ่ม Controller สำหรับช่องค้นหา เพื่อให้เราสั่งใส่ข้อความได้
  final TextEditingController searchCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchStockData();
  }

  Future<void> fetchStockData() async {
    // ... (โค้ดเดิมของคุณ) ...
    isLoading.value = true;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;

      if (shopId != 0) {
        List<Product> list = await ApiProduct.getProductsByShop(shopId);
        list.sort((a, b) => a.stock.compareTo(b.stock));
        products.assignAll(list);
        filteredProducts.assignAll(list);
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "โหลดข้อมูลล้มเหลว: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void searchProduct(String query) {
    if (query.isEmpty) {
      filteredProducts.assignAll(products);
    } else {
      var result = products
          .where(
            (p) =>
                p.name.toLowerCase().contains(query.toLowerCase()) ||
                (p.barcode != null && p.barcode!.contains(query)),
          ) // เพิ่มค้นหาด้วยบาร์โค้ด
          .toList();
      filteredProducts.assignAll(result);
    }
  }

  // ✨ ฟังก์ชันเปิดกล้องสแกน
  Future<void> openScanner() async {
    // ไปหน้าสแกนและรอรับค่ากลับ (result)
    var result = await Get.to(() => const ScanBarcodePage());

    if (result != null && result is String) {
      // 1. ใส่ค่าลงในช่องค้นหา
      searchCtrl.text = result;
      // 2. สั่งค้นหาทันที
      searchProduct(result);
    }
  }

  void changeTab(int index) => selectedIndex.value = index;

  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }
}

// ----------------------------------------------------------------------
// 2. The View
// ----------------------------------------------------------------------
class CheckStockScreen extends StatelessWidget {
  const CheckStockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final StockController controller = Get.put(StockController());
    const Color primaryColor = Color(0xFF6B8E23);
    const Color warningColor = Color(0xFFFFCC00);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          'เช็คสต็อกสินค้า',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: controller.fetchStockData,
            icon: const Icon(Icons.refresh, color: primaryColor),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            _buildSearchBar(
              controller,
              primaryColor,
            ), // ส่ง primaryColor ไปด้วย
            const SizedBox(height: 15),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }
                if (controller.filteredProducts.isEmpty) {
                  return const Center(
                    child: Text("ไม่พบข้อมูลสินค้าในร้านนี้"),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: controller.filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = controller.filteredProducts[index];
                    return InkWell(
                      onTap: () {
                        Get.to(
                          () => ProductDetailScreen(),
                          arguments: product,
                          transition: Transition.rightToLeft,
                        );
                      },
                      borderRadius: BorderRadius.circular(15),
                      child: _buildProductCard(product, warningColor),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () => BottomNavBar(
          currentIndex: controller.selectedIndex.value,
          onTap: controller.changeTab,
        ),
      ),
    );
  }

  // ✨ ปรับปรุงช่องค้นหาให้มีปุ่มสแกน
  Widget _buildSearchBar(StockController controller, Color primaryColor) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller.searchCtrl, // ผูก Controller
        onChanged: controller.searchProduct,
        decoration: InputDecoration(
          hintText: 'ค้นหาชื่อสินค้า หรือ บาร์โค้ด...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          // ✨ เพิ่มปุ่มสแกนด้านขวา
          suffixIcon: IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.black87),
            onPressed: controller.openScanner, // เรียกฟังก์ชันเปิดกล้อง
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product, Color warningColor) {
    // ... (ส่วนนี้เหมือนเดิมเป๊ะๆ ไม่ต้องแก้) ...
    final bool isLowStock = product.stock <= 10;
    final bool isOutOfStock = product.stock == 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                product.imgProduct,
                width: 65,
                height: 65,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.image_not_supported,
                  size: 40,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'คงเหลือ ${product.stock} ${product.unit}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isOutOfStock
                          ? Colors.red
                          : (isLowStock ? Colors.orange : Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
            if (isLowStock)
              Icon(
                Icons.warning_amber_rounded,
                color: isOutOfStock ? Colors.red : warningColor,
                size: 30,
              ),
          ],
        ),
      ),
    );
  }
}
