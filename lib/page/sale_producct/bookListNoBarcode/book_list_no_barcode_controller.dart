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
          categories.add(c.name.toString());
          categoryMap[c.name.toString()] = c.categoryId;
        }
      }
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  Future<void> fetchProducts(int shopId) async {
    try {
      final List<dynamic> data = await ApiProduct.getNullBarcodeProducts(shopId);
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
      final List<dynamic> data = await ApiProduct.getNullBarcodeProducts(shopId, categoryId: categoryId);
      _mapDataToProducts(data);
    } catch (e) {
      print("Refresh Products Error: $e");
    } finally {
      isLoading(false);
    }
  }

  void _mapDataToProducts(List<dynamic> data) {
    var products = data
        .where((item) => item['status'] == true)
        .map((item) {
          return ProductItem(
            id: (item['product_id'] ?? item['id'] ?? "").toString(),
            name: item['name'] ?? "ไม่มีชื่อสินค้า",
            price: double.tryParse(item['sell_price']?.toString() ?? "0") ?? 0.0,
            category: item['category_name'] ?? "อื่นๆ",
            imagePath: item['img_product'] ?? item['image'] ?? "",
            maxStock: item['stock'] ?? 999, // ดึง stock จาก API มาใส่
          );
        })
        .toList();
    allProducts.assignAll(products);
    filterProducts();
  }

  void filterProducts() {
    int? selectedId = categoryMap[selectedCategory.value];
    var results = allProducts.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(searchQuery.value.toLowerCase());
      // หมายเหตุ: ใน baskets_model ไม่มี categoryId ดังนั้นอาจต้องเช็คจากชื่อหมวดหมู่แทนถ้าต้องการกรองละเอียด
      final matchesCategory = selectedCategory.value == "หมวดหมู่" || product.category == selectedCategory.value;
      return matchesSearch && matchesCategory;
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

  void goToCheckout() {
    if (selectedIds.isEmpty) {
      Get.snackbar("แจ้งเตือน", "กรุณาเลือกสินค้าอย่างน้อย 1 ชิ้น", backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    final List<String> idsToSend = selectedIds.toList();

    if (Get.isRegistered<CheckoutController>()) {
      final checkoutCtrl = Get.find<CheckoutController>();
      
      // ✅ ส่ง ID ไปให้ CheckoutController ตัวจริงจัดการ
      checkoutCtrl.addItemsByIds(idsToSend);
      
      // อัปเดต Nav Index เพื่อให้ Tab Bar แสดงสีแดงที่เมนูขาย (Index 2)
      checkoutCtrl.currentNavIndex.value = 2;

      // จัดการหน้าจอ
      if (Get.previousRoute.contains('CheckoutPage')) {
        Get.back();
      } else {
        Get.to(() => const CheckoutPage());
      }
    } else {
      // กรณีเปิดแอปมาแล้วเข้าหน้านี้เลยโดยไม่มี CheckoutController (กันพลาด)
      Get.offAll(() => const CheckoutPage(), arguments: {'selectedIds': idsToSend});
    }

    // ล้างค่าที่เลือกไว้เพื่อให้กลับมาเลือกใหม่ได้สะอาดๆ
    selectedIds.clear();

    Get.snackbar("สำเร็จ", "เพิ่มสินค้าลงตะกร้าแล้ว", backgroundColor: Colors.green, colorText: Colors.white, duration: const Duration(seconds: 1));
  }
}