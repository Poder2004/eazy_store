import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/sale_producct/sale/checkout_controller.dart';
import 'package:eazy_store/sale_producct/sale/checkout_page.dart';

// ----------------------------------------------------------------------
// 1. Model
// ----------------------------------------------------------------------
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
          .where(
            (item) => item['status'] == true,
          ) // 🔥 กรองเอาเฉพาะสินค้าที่ไม่ได้ถูกซ่อน (status == true)
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

      var products = data
          .where(
            (item) => item['status'] == true,
          ) // 🔥 กรองเอาเฉพาะสินค้าที่ไม่ได้ถูกซ่อน (status == true)
          .map((item) {
            return ProductItem(
              id: (item['product_id'] ?? item['id'] ?? "").toString(),
              name: item['name'] ?? "ไม่มีชื่อสินค้า",
              sellPrice:
                  double.tryParse(item['sell_price']?.toString() ?? "0") ?? 0.0,
              category: item['category_name'] ?? "อื่นๆ",
              categoryId: item['category_id'] ?? 0,
              imgProduct: item['img_product'] ?? item['image'] ?? "",
            );
          })
          .toList();

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

    if (Get.isRegistered<CheckoutController>()) {
      final checkoutCtrl = Get.find<CheckoutController>();

      checkoutCtrl.addItemsByIds(selectedIds);
      checkoutCtrl.currentNavIndex.value = 2;

      if (Get.previousRoute.contains('CheckoutPage')) {
        Get.close(2);
      } else {
        Get.until((route) => route.isFirst);
      }
    } else {
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