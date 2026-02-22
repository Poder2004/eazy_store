import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/page/menu_bar/bottom_navbar.dart';
import 'package:eazy_store/model/response/product_response.dart';
import 'package:eazy_store/page/product/product_detail/product_detail.dart';
import 'package:eazy_store/page/sale_producct/scanBarcode/scan_barcode.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ----------------------------------------------------------------------
// 1. Controller: จัดการ Logic การดึงข้อมูลและค้นหา
// ----------------------------------------------------------------------
class PriceController extends GetxController {
  var isLoading = true.obs;
  var products = <ProductResponse>[].obs;
  var filteredProducts = <ProductResponse>[].obs;
  var selectedIndex = 2.obs; // หน้าเช็คราคาเป็น Index 2

  // เพิ่ม Controller สำหรับช่องค้นหา
  final TextEditingController searchCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchPriceData();
  }

  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }

  // 🚀 ดึงข้อมูลสินค้า
  Future<void> fetchPriceData() async {
    isLoading.value = true;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;

      if (shopId != 0) {
        List<ProductResponse> list = await ApiProduct.getProductsByShop(shopId);

        // 🔥 แก้ไขตรงนี้: กรองเอาเฉพาะสินค้าที่ไม่ได้ถูกซ่อน (status == true) มาแสดง
        list = list.where((p) => p.status == true).toList();

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

  // 📷 ฟังก์ชันเปิดกล้อง
  Future<void> openScanner() async {
    var result = await Get.to(() => const ScanBarcodePage());
    if (result != null && result is String) {
      searchCtrl.text = result; // ใส่ค่าในช่องค้นหา
      searchProduct(result); // สั่งค้นหาทันที
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

    const Color primaryColor = Color(0xFF6B8E23); // สีเขียวมะกอก
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
            // --- 🔍 ส่วนช่องค้นหา + ปุ่มสแกน ---
            _buildSearchBar(controller, primaryColor),
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
                    final product = controller.filteredProducts[index];

                    return InkWell(
                      onTap: () async {
                        // ✨ 1. เติม async
                        var result = await Get.to(
                          // ✨ 2. ใส่ await รอรับค่า result
                          () => const ProductDetailScreen(),
                          arguments: product,
                          transition: Transition.rightToLeft,
                        );

                        // ✨ 3. ถ้า result ส่งกลับมาเป็น true (แปลว่าเพิ่งลบสินค้าไป) ให้รีเฟรชหน้าเช็คราคาใหม่
                        if (result == true) {
                          controller.fetchPriceData();
                        }
                      },
                      borderRadius: BorderRadius.circular(15),
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

  // 🔍 Widget ค้นหา (เพิ่มปุ่มสแกน)
  Widget _buildSearchBar(PriceController controller, Color primaryColor) {
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
          hintText: 'ค้นหาชื่อสินค้า หรือ สแกนบาร์โค้ด...',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          // ✨ เพิ่มปุ่มสแกน
          suffixIcon: IconButton(
            icon: Icon(Icons.qr_code_scanner_outlined, color: primaryColor),
            onPressed: controller.openScanner,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
        ),
      ),
    );
  }

  // 📦 Widget Card แสดงราคา (เน้นราคาตัวใหญ่)
  Widget _buildPriceCard(ProductResponse product, Color primaryColor) {
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
          // 1. รูปสินค้า
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

          // 2. ชื่อและรหัส
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
                const SizedBox(height: 4),
                Text(
                  "รหัส: ${product.productCode ?? '-'}",
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),

          // 3. ราคา (Highlight)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${product.sellPrice.toStringAsFixed(0)}', // แสดงราคาจำนวนเต็ม
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                ),
              ),
              const Text(
                'บาท',
                style: TextStyle(
                  fontSize: 12,
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
