import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/menu_bar/bottom_navbar.dart';
import 'package:eazy_store/model/request/product_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ----------------------------------------------------------------------
// 1. Controller: จัดการ Logic (อยู่ภายในหน้าเดียวกัน)
// ----------------------------------------------------------------------
class StockController extends GetxController {
  var isLoading = true.obs;
  var products = <Product>[].obs; // ข้อมูลดิบจากฐานข้อมูล
  var filteredProducts = <Product>[].obs; // ข้อมูลที่ใช้แสดงผล (รองรับการค้นหา)
  var selectedIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchStockData();
  }

  // 🚀 ฟังก์ชันดึงข้อมูลสต็อกและเรียงลำดับจากน้อยไปมาก
  Future<void> fetchStockData() async {
    isLoading.value = true;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;

      if (shopId != 0) {
        List<Product> list = await ApiProduct.getProductsByShop(shopId);

        // ✨ เรียงลำดับ: สินค้าที่สต็อกน้อยที่สุด (หรือหมด) จะอยู่บนสุด
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

  // 🔍 ฟังก์ชันค้นหาสินค้า (กรองจากรายชื่อที่มีอยู่)
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

  void changeTab(int index) {
    selectedIndex.value = index;
  }
}

// ----------------------------------------------------------------------
// 2. The View: หน้าจอ UI
// ----------------------------------------------------------------------
class CheckStockScreen extends StatelessWidget {
  const CheckStockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ลงทะเบียน Controller ใช้งานในหน้านี้
    final StockController controller = Get.put(StockController());

    // กำหนดสีธีมพรีเมียม
    const Color primaryColor = Color(0xFF6B8E23);
    const Color warningColor = Color(0xFFFFCC00);
    const Color backgroundColor = Color(0xFFF7F7F7);

    return Scaffold(
      backgroundColor: backgroundColor,
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
          // ปุ่มรีเฟรชข้อมูล
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
            // --- ส่วน Search Bar ---
            _buildSearchBar(controller),
            const SizedBox(height: 15),

            // --- ส่วนรายการสินค้า ---
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
                    return _buildProductCard(
                      controller.filteredProducts[index],
                      warningColor,
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      // --- Bottom Navigation Bar ---
      bottomNavigationBar: Obx(
        () => BottomNavBar(
          currentIndex: controller.selectedIndex.value,
          onTap: controller.changeTab,
        ),
      ),
    );
  }

  // 🔍 Widget สำหรับแถบค้นหา
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
        onChanged: controller.searchProduct, // ค้นหาทันทีที่พิมพ์
        decoration: const InputDecoration(
          hintText: 'ค้นหาชื่อสินค้า...',
          hintStyle: TextStyle(color: Colors.grey),
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12.0),
        ),
      ),
    );
  }

  // 📦 Widget สำหรับ Card รายการสินค้าแต่ละชิ้น
  Widget _buildProductCard(Product product, Color warningColor) {
    // เงื่อนไขแจ้งเตือนสินค้าใกล้หมด (สต็อก <= 10)
    final bool isLowStock = product.stock <= 10;
    final bool isOutOfStock = product.stock == 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // 1. รูปภาพสินค้าจาก URL ใน DB
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

            // 2. รายละเอียดสินค้า
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
                      // เปลี่ยนสีตามสถานะสต็อก
                      color: isOutOfStock
                          ? Colors.red
                          : (isLowStock ? Colors.orange : Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),

            // 3. สัญลักษณ์แจ้งเตือน
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
