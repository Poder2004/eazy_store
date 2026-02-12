import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eazy_store/api/api_product.dart';

// ----------------------------------------------------------------------
// 1. Model: โครงสร้างข้อมูลสินค้า
// ----------------------------------------------------------------------
class ProductItem {
  final String id;
  final String name;
  final double price;
  final String category;
  final IconData icon;
  RxBool isSelected;

  ProductItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.icon,
    bool selected = false,
  }) : isSelected = selected.obs;
}

// ----------------------------------------------------------------------
// 2. Controller: จัดการ Logic รายการสินค้าและหมวดหมู่
// ----------------------------------------------------------------------
class ManualListController extends GetxController {
  var isLoading = true.obs;
  
  // ข้อมูลสินค้า
  var allProducts = <ProductItem>[].obs;
  var filteredProducts = <ProductItem>[].obs;
  
  // ข้อมูลหมวดหมู่
  var categories = <String>["หมวดหมู่"].obs; 
  
  var searchQuery = "".obs;
  var selectedCategory = "หมวดหมู่".obs;

  @override
  void onInit() {
    super.onInit();
    fetchInitialData(); // ดึงข้อมูลทั้ง 2 อย่างพร้อมกัน
    
    // ตั้ง Worker ตรวจจับการค้นหาหรือเปลี่ยนหมวดหมู่
    debounce(searchQuery, (_) => filterProducts(), time: 300.milliseconds);
    ever(selectedCategory, (_) => filterProducts());
  }

  // ดึงข้อมูลเริ่มต้น
  Future<void> fetchInitialData() async {
    try {
      isLoading(true);
      
      // ดึงข้อมูลพร้อมกันแบบ Parallel
      await Future.wait([
        fetchCategories(),
        fetchProducts(),
      ]);

    } catch (e) {
      Get.snackbar("Error", "ไม่สามารถโหลดข้อมูลได้: $e", snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading(false);
    }
  }

  // 1. ดึงหมวดหมู่จาก API
  Future<void> fetchCategories() async {
    try {
      final categoryData = await ApiProduct.getCategories(); // ใช้ฟังก์ชันที่คุณมี
      if (categoryData.isNotEmpty) {
        // ล้างข้อมูลเก่า (คงเหลือคำว่า "หมวดหมู่") และเพิ่มชื่อจาก API
        categories.value = ["หมวดหมู่"];
        categories.addAll(categoryData.map((c) => c.name.toString()).toList());
      }
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  // 2. ดึงสินค้าที่ไม่มีบาร์โค้ด
  Future<void> fetchProducts() async {
    try {
      final List<dynamic> data = await ApiProduct.getNullBarcodeProducts(1); // shop_id = 1
      
      var products = data.map((item) => ProductItem(
        id: item['product_id'].toString(),
        name: item['name'] ?? "ไม่มีชื่อสินค้า",
        price: double.parse(item['price']?.toString() ?? "0"),
        category: item['category_name'] ?? "อื่นๆ",
        icon: Icons.inventory_2,
      )).toList();

      allProducts.assignAll(products);
      filterProducts();
    } catch (e) {
      rethrow;
    }
  }

  // การกรองข้อมูล
  void filterProducts() {
    var results = allProducts.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(searchQuery.value.toLowerCase());
      final matchesCategory = selectedCategory.value == "หมวดหมู่" || product.category == selectedCategory.value;
      return matchesSearch && matchesCategory;
    }).toList();
    
    filteredProducts.assignAll(results);
  }

  void toggleSelection(ProductItem product) {
    product.isSelected.value = !product.isSelected.value;
  }

  void goToCheckout() {
    final selectedItems = allProducts.where((p) => p.isSelected.value).toList();
    if (selectedItems.isEmpty) {
      Get.snackbar("แจ้งเตือน", "กรุณาเลือกสินค้าอย่างน้อย 1 ชิ้น", backgroundColor: Colors.orange, colorText: Colors.white);
    } else {
      print("ไปคิดเงิน: ${selectedItems.length} รายการ");
    }
  }
}

// ----------------------------------------------------------------------
// 3. The View: หน้าจอ UI
// ----------------------------------------------------------------------
class ManualListPage extends StatelessWidget {
  const ManualListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ManualListController controller = Get.put(ManualListController());
    final Color activeBlue = const Color(0xFF2979FF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Get.back(),
        ),
        title: const Text("สมุดสินค้าไม่มีบาร์โค้ด", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: Column(
        children: [
          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
              child: TextField(
                onChanged: (val) => controller.searchQuery.value = val,
                decoration: const InputDecoration(
                  hintText: "ค้นหาชื่อสินค้า",
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                ),
              ),
            ),
          ),

          // --- Category Dropdown ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                child: Obx(() => DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.selectedCategory.value,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    onChanged: (String? newValue) {
                      if (newValue != null) controller.selectedCategory.value = newValue;
                    },
                    // สร้างรายการ Dropdown จาก categories ที่โหลดมาจาก API
                    items: controller.categories.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                  ),
                )),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // --- Product List ---
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.filteredProducts.isEmpty) {
                return const Center(child: Text("ไม่พบรายการสินค้า"));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: controller.filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = controller.filteredProducts[index];
                  return _buildProductCard(product, activeBlue, controller);
                },
              );
            }),
          ),

          // --- Checkout Button ---
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: controller.goToCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                label: const Text("ไปคิดเงิน", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductItem product, Color activeColor, ManualListController controller) {
    return GestureDetector(
      onTap: () => controller.toggleSelection(product),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
              child: Icon(product.icon, size: 30, color: Colors.grey[600]),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 5),
                  Text("${product.price.toInt()} บาท", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                ],
              ),
            ),
            Obx(() => Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: product.isSelected.value ? activeColor : Colors.transparent,
                border: Border.all(color: product.isSelected.value ? activeColor : Colors.grey.shade300, width: 2),
              ),
              child: product.isSelected.value ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            )),
          ],
        ),
      ),
    );
  }
}