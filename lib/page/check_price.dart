import 'package:eazy_store/api/api_product.dart';

import 'package:eazy_store/menu_bar/bottom_navbar.dart';
import 'package:eazy_store/model/request/product_model.dart';
import 'package:eazy_store/page/product_detail.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ----------------------------------------------------------------------
// 1. Controller: จัดการ Logic การดึงข้อมูลและค้นหา
// ----------------------------------------------------------------------
class PriceController extends GetxController {
  var isLoading = true.obs;
  var products = <Product>[].obs;
  var filteredProducts = <Product>[].obs;
  var selectedIndex = 2.obs; // หน้าเช็คราคาเป็น Index 2

  @override
  void onInit() {
    super.onInit();
    fetchPriceData();
  }

  // 🚀 ดึงข้อมูลสินค้าทั้งหมดจาก Shop เดียวกันกับหน้าเช็คสต็อก
  Future<void> fetchPriceData() async {
    isLoading.value = true;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;

      if (shopId != 0) {
        List<Product> list = await ApiProduct.getProductsByShop(shopId);
        // เรียงตามชื่อสินค้าเพื่อให้หาเจอง่ายขึ้น
        list.sort((a, b) => a.name.compareTo(b.name));

        products.assignAll(list);
        filteredProducts.assignAll(list);
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "โหลดข้อมูลราคาล้มเหลว: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // 🔍 ค้นหาสินค้า
  void searchProduct(String query) {
    if (query.isEmpty) {
      filteredProducts.assignAll(products);
    } else {
      var result = products
          .where(
            (p) =>
                p.name.toLowerCase().contains(query.toLowerCase()) ||
                (p.barcode != null && p.barcode!.contains(query)),
          )
          .toList();
      filteredProducts.assignAll(result);
    }
  }

  void changeTab(int index) {
    selectedIndex.value = index;
  }
}

// ----------------------------------------------------------------------
// 2. View: หน้าจอแสดงราคาสินค้า
// ----------------------------------------------------------------------
class CheckPriceScreen extends StatelessWidget {
  const CheckPriceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PriceController controller = Get.put(PriceController());

    const Color primaryColor = Color(0xFF6B8E23); // ใช้เขียวมะกอกให้เข้าธีมแอป
    const Color backgroundColor = Color(0xFFF7F7F7);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'เช็คราคาสินค้า',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: controller.fetchPriceData,
            icon: const Icon(Icons.refresh, color: primaryColor),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            // --- 🔍 ส่วนช่องค้นหา ---
            _buildSearchBar(controller),
            const SizedBox(height: 15),

            // --- 🏷️ รายการสินค้าพร้อมราคา ---
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }

                if (controller.filteredProducts.isEmpty) {
                  return const Center(child: Text("ไม่พบข้อมูลสินค้า"));
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: controller.filteredProducts.length,
                  itemBuilder: (context, index) {
                    // 1. ดึงข้อมูลสินค้าตัวที่ถูกเลือกออกมาไว้ในตัวแปร
                    final product = controller.filteredProducts[index];

                    // 2. ใช้ InkWell ห่อเพื่อให้กดได้และมี Effect
                    return InkWell(
                      onTap: () {
                        // 3. ใช้ Get.to เพื่อนำทางไปหน้ารายละเอียด และส่ง product ไปเป็น arguments
                        Get.to(
                          () => const ProductDetailScreen(),
                          arguments: product,
                          transition: Transition
                              .rightToLeft, // เพิ่ม Animation ให้ดูพรีเมียม
                        );
                      },
                      borderRadius: BorderRadius.circular(
                        15,
                      ), // ให้ขอบ Effect มนเท่ากับ Card
                      child: _buildPriceCard(product, primaryColor),
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

  // 🔍 Widget ค้นหา
  Widget _buildSearchBar(PriceController controller) {
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
          hintText: 'ค้นหาชื่อสินค้าหรือสแกนบาร์โค้ด...',
          hintStyle: TextStyle(color: Colors.grey),
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          suffixIcon: Icon(Icons.qr_code_scanner_outlined, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12.0),
        ),
      ),
    );
  }

  // 📦 Widget Card แสดงราคา (ปรับปรุงให้ราคาตัวใหญ่ชัดเจน)
  Widget _buildPriceCard(Product product, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. รูปสินค้า (Network Image)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              product.imgProduct,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[200],
                width: 70,
                height: 70,
                child: const Icon(Icons.image_outlined, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 15),

          // 2. ชื่อสินค้า
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "รหัส: ${product.productCode ?? '-'}",
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),

          // 3. ราคาสินค้า (ตัวหนาและใหญ่)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${product.sellPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                ),
              ),
              const Text(
                'บาท',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
