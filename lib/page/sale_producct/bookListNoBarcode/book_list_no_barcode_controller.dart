import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/page/sale_producct/sale/checkout_controller.dart';
import 'package:eazy_store/page/sale_producct/sale/checkout_page.dart';

// 🛒 Import ตัว Model กลางมาใช้ เพื่อให้เป็น Type เดียวกับในตะกร้า
import 'package:eazy_store/model/request/baskets_model.dart';

class ManualListController extends GetxController {
  var isLoading = true.obs;

  // ใช้ ProductItem จาก baskets_model.dart
  var allProducts = <ProductItem>[].obs;
  var filteredProducts = <ProductItem>[].obs;

  // เก็บสถานะการเลือกแยกไว้ (เพราะ ProductItem ใน basket ไม่มี isSelected)
  var selectedIds = <String>{}.obs;

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
          final name = c.name.toString().trim();
          categories.add(name);
          categoryMap[name] = c.categoryId;
        }
      }
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  Future<void> fetchProducts(int shopId) async {
    try {
      final List<dynamic> data = await ApiProduct.getNullBarcodeProducts(
        shopId,
      );
      _mapDataToProducts(data);
    } catch (e) {
      print("Fetch Products Error: $e");
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
      _mapDataToProducts(data);
    } catch (e) {
      print("Refresh Products Error: $e");
    } finally {
      isLoading(false);
    }
  }

  void _mapDataToProducts(List<dynamic> data) {
    var products = data.where((item) => item['status'] == true).map((item) {
      return ProductItem(
        id: (item['product_id'] ?? item['id'] ?? "").toString(),
        name: item['name'] ?? "ไม่มีชื่อสินค้า",
        price: double.tryParse(item['sell_price']?.toString() ?? "0") ?? 0.0,
        category: (item['category_name'] ?? "อื่นๆ").toString().trim(),
        imagePath: item['img_product'] ?? item['image'] ?? "",
        maxStock: item['stock'] ?? 999, // ดึง stock จาก API มาใส่
      );
    }).toList();
    allProducts.assignAll(products);
    filterProducts();
  }

  void filterProducts() {
    var results = allProducts.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(
        searchQuery.value.toLowerCase(),
      );
      // เมื่อเลือกหมวดหมู่ → API ส่งข้อมูลที่ filter แล้วมาใน allProducts
      // ดังนั้นกรองเฉพาะ searchQuery เท่านั้น
      return matchesSearch;
    }).toList();
    filteredProducts.assignAll(results);
  }

  // ปรับการ Toggle โดยเช็คจาก ID
  void toggleSelection(String id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }
  }

  Future<void> goToCheckout() async {
    if (selectedIds.isEmpty) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณาเลือกสินค้าอย่างน้อย 1 ชิ้น",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final List<String> idsToSend = selectedIds.toList();

    if (Get.isRegistered<CheckoutController>()) {
      final checkoutCtrl = Get.find<CheckoutController>();

      // ✅ await เพื่อรอให้เพิ่มสินค้าลงตะกร้าจริงๆ ก่อนแสดง snackbar
      final int addedCount = await checkoutCtrl.addItemsByIds(idsToSend);

      // อัปเดต Nav Index เพื่อให้ Tab Bar แสดงสีแดงที่เมนูขาย (Index 2)
      checkoutCtrl.currentNavIndex.value = 2;

      // ล้างค่าที่เลือกไว้เพื่อให้กลับมาเลือกใหม่ได้สะอาดๆ
      selectedIds.clear();

      if (addedCount > 0) {
        Get.snackbar(
          "สำเร็จ",
          "เพิ่มสินค้า $addedCount รายการลงตะกร้าแล้ว",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 1),
        );
      } else {
        Get.snackbar(
          "ไม่สามารถเพิ่มได้",
          "สินค้าที่เลือกอาจหมดสต็อก หรือไม่พบในระบบ",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return; // ไม่เปลี่ยนหน้าถ้าไม่มีสินค้าถูกเพิ่มเลย
      }

      // จัดการหน้าจอ
      if (Get.previousRoute.contains('CheckoutPage')) {
        Get.back();
      } else {
        Get.to(() => const CheckoutPage());
      }
    } else {
      // กรณีเปิดแอปมาแล้วเข้าหน้านี้เลยโดยไม่มี CheckoutController (กันพลาด)
      selectedIds.clear();
      Get.offAll(
        () => const CheckoutPage(),
        arguments: {'selectedIds': idsToSend},
      );
    }
  }
}
