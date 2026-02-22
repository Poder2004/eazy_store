import 'package:eazy_store/sale_producct/sale/checkout_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eazy_store/api/api_product.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ Import หน้า Checkout เพื่อเข้าถึง CheckoutController
import 'package:eazy_store/sale_producct/sale/checkout_page.dart';

class ProductItem {
  final String id;
  final String name;
  final double sellPrice;
  final String category;
  final int categoryId;
  final String imgProduct;
  RxBool isSelected;

  ProductItem({
    required this.id,
    required this.name,
    required this.sellPrice,
    required this.category,
    required this.categoryId,
    required this.imgProduct,
    bool selected = false,
  }) : isSelected = selected.obs;
}

// ----------------------------------------------------------------------
// 2. Controller
// ----------------------------------------------------------------------
class ManualListController extends GetxController {
  var isLoading = true.obs;
  var allProducts = <ProductItem>[].obs;
  var filteredProducts = <ProductItem>[].obs;
  var categories = <String>["หมวดหมู่"].obs;
  var searchQuery = "".obs;
  var selectedCategory = "หมวดหมู่".obs;
  var categoryMap = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchInitialData();
    ever(selectedCategory, (String categoryName) {
      int? categoryId = categoryMap[categoryName];
      refreshProducts(categoryId);
    });
    debounce(searchQuery, (_) => filterProducts(), time: 300.milliseconds);
    ever(selectedCategory, (_) => filterProducts());
  }

  Future<void> fetchInitialData() async {
    try {
      isLoading(true);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? storedShopId = prefs.getInt('shopId');
      await Future.wait([fetchCategories(), fetchProducts(storedShopId ?? 1)]);
    } catch (e) {
      print("Initial Data Error: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchCategories() async {
    try {
      final categoryData = await ApiProduct.getCategories();
      if (categoryData.isNotEmpty) {
        categoryMap.clear();
        categories.value = ["หมวดหมู่"];
        for (var c in categoryData) {
          categories.add(c.name.toString());
          categoryMap[c.name.toString()] = c.categoryId;
        }
      }
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  Future<void> refreshProducts(int? categoryId) async {
    try {
      isLoading(true);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 1;

      final List<dynamic> data = await ApiProduct.getNullBarcodeProducts(
        shopId,
        categoryId: categoryId,
      );

      var products = data
          .map(
            (item) => ProductItem(
              id: (item['product_id'] ?? "").toString(),
              name: item['name'] ?? "",
              sellPrice:
                  double.tryParse(item['sell_price']?.toString() ?? "0") ?? 0.0,
              category: item['category_name'] ?? "",
              categoryId: item['category_id'] ?? 0,
              imgProduct: item['img_product'] ?? "",
            ),
          )
          .toList();

      allProducts.assignAll(products);
      filterProducts();
    } catch (e) {
      print("Refresh Products Error: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchProducts(int shopId) async {
    try {
      final List<dynamic> data = await ApiProduct.getNullBarcodeProducts(
        shopId,
      );
      var products = data.map((item) {
        return ProductItem(
          id: (item['product_id'] ?? item['id'] ?? "").toString(),
          name: item['name'] ?? "ไม่มีชื่อสินค้า",
          sellPrice:
              double.tryParse(item['sell_price']?.toString() ?? "0") ?? 0.0,
          category: item['category_name'] ?? "อื่นๆ",
          categoryId: item['category_id'] ?? 0,
          imgProduct: item['img_product'] ?? item['image'] ?? "",
        );
      }).toList();

      allProducts.assignAll(products);
      filterProducts();
    } catch (e) {
      print("Fetch Products Error: $e");
    }
  }

  void filterProducts() {
    int? selectedId = categoryMap[selectedCategory.value];
    var results = allProducts.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(
        searchQuery.value.toLowerCase(),
      );
      final matchesCategory =
          selectedCategory.value == "หมวดหมู่" ||
          product.categoryId == selectedId;
      return matchesSearch && matchesCategory;
    }).toList();
    filteredProducts.assignAll(results);
  }

  void toggleSelection(ProductItem product) {
    product.isSelected.value = !product.isSelected.value;
  }

  // ✅ แก้ไข goToCheckout: ปรับ Navigation ใหม่เพื่อกันบัคจอดำและของหาย
  void goToCheckout() {
    final List<String> selectedIds = allProducts
        .where((p) => p.isSelected.value)
        .map((p) => p.id)
        .toList();

    if (selectedIds.isEmpty) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณาเลือกสินค้าอย่างน้อย 1 ชิ้น",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // 🛡️ ขั้นตอนการจัดการ Controller และ Navigation
    if (Get.isRegistered<CheckoutController>()) {
      final checkoutCtrl = Get.find<CheckoutController>();

      // 1. เพิ่มสินค้าลงตะกร้า (ใช้ฟังก์ชันที่แก้ให้เป็น async ในหน้า Checkout)
      checkoutCtrl.addItemsByIds(selectedIds);

      // 2. ตั้งค่า Tab ให้เป็นหน้า Checkout (Index 2)
      checkoutCtrl.currentNavIndex.value = 2;

      // 3. จัดการทิศทางกลับให้ปลอดภัย เพื่อไม่ให้เกิดจอดำ
      if (Get.previousRoute.contains('CheckoutPage')) {
        // กรณีเปิดจากหน้า Checkout -> กลับไปที่หน้าเดิม
        Get.close(2);
      } else {
        // กรณีเปิดจากหน้าหลัก (Home) -> ย้อนกลับไปหารูทแรกของแอป (Home)
        // วิธีนี้ปลอดภัยกว่า Get.offAll เพราะไม่ล้าง Memory ของ Controller ที่เป็น permanent
        Get.until((route) => route.isFirst);
      }
    } else {
      // กรณีฉุกเฉิน: Controller หาย ให้เปิดหน้า Checkout ใหม่พร้อมส่งค่า
      Get.offAll(
        () => const CheckoutPage(),
        arguments: {'selectedIds': selectedIds},
      );
    }

    Get.snackbar(
      "สำเร็จ",
      "เพิ่มสินค้าลงตะกร้าแล้ว",
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 1),
    );
  }
}

// ----------------------------------------------------------------------
// 3. View (UI คงเดิม)
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
        title: const Text(
          "สมุดสินค้าไม่มีบาร์โค้ด",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(controller),
          const SizedBox(height: 10),
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
                  return _buildProductCard(
                    controller.filteredProducts[index],
                    activeBlue,
                    controller,
                  );
                },
              );
            }),
          ),
          _buildCheckoutButton(controller),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    ProductItem product,
    Color activeColor,
    ManualListController controller,
  ) {
    return GestureDetector(
      onTap: () => controller.toggleSelection(product),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${product.sellPrice.toStringAsFixed(0)} บาท",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            Obx(
              () => Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: product.isSelected.value
                      ? activeColor
                      : Colors.transparent,
                  border: Border.all(
                    color: product.isSelected.value
                        ? activeColor
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: product.isSelected.value
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter(ManualListController controller) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              onChanged: (val) => controller.searchQuery.value = val,
              decoration: const InputDecoration(
                hintText: "ค้นหาชื่อสินค้า",
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Obx(
              () => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.selectedCategory.value,
                    items: controller.categories
                        .map(
                          (val) =>
                              DropdownMenuItem(value: val, child: Text(val)),
                        )
                        .toList(),
                    onChanged: (val) =>
                        controller.selectedCategory.value = val!,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutButton(ManualListController controller) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: controller.goToCheckout,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C853),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
          label: const Text(
            "เพิ่มลงรายการขาย",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
