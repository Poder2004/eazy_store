import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/menu_bar/bottom_navbar.dart';
import 'package:eazy_store/model/request/product_model.dart';
import 'package:eazy_store/page/product_detail.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ----------------------------------------------------------------------
// 1. Controller: จัดการ Logic
// ----------------------------------------------------------------------
class StockController extends GetxController {
  var isLoading = true.obs;
  var products = <Product>[].obs;
  var filteredProducts = <Product>[].obs;
  var selectedIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchStockData();
  }

  Future<void> fetchStockData() async {
    isLoading.value = true;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;

      if (shopId != 0) {
        List<Product> list = await ApiProduct.getProductsByShop(shopId);
        list.sort((a, b) => a.stock.compareTo(b.stock)); // เรียงน้อยไปมาก
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
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
      filteredProducts.assignAll(result);
    }
  }

  void changeTab(int index) => selectedIndex.value = index;
}

// ----------------------------------------------------------------------
// 2. The View: หน้าจอ UI
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
            _buildSearchBar(controller),
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

                    // ✨ แก้ไขจุดนี้: ห่อด้วย InkWell เพื่อให้กดไปหน้า Detail
                    return InkWell(
                      onTap: () {
                        Get.to(
                          () => ProductDetailScreen(),
                          arguments: product, // ส่ง Object สินค้าไปทั้งก้อน
                          transition:
                              Transition.rightToLeft, // สไลด์หน้าจอแบบนุ่มนวล
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

  Widget _buildSearchBar(StockController controller) {
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
        onChanged: controller.searchProduct,
        decoration: const InputDecoration(
          hintText: 'ค้นหาชื่อสินค้า...',
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12.0),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product, Color warningColor) {
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
