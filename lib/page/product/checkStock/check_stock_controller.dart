import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/model/request/category_model.dart';
import 'package:eazy_store/model/response/product_response.dart';
import 'package:eazy_store/page/sale_producct/scanBarcode/scan_barcode.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StockController extends GetxController {
  var isLoading = true.obs;
  var products = <ProductResponse>[].obs;
  var filteredProducts = <ProductResponse>[].obs;
  var selectedIndex = 0.obs;
  var isAscending = true.obs;

  var categories = <CategoryModel>[].obs;
  var selectedCategoryId = 0.obs; // 0 คือ "ทั้งหมด"
  var isLoadingCategories = false.obs;
  
  final TextEditingController searchCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchStockData();
    fetchCategories();
  }

  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }

  // 🚀 ดึงข้อมูลสินค้า
  Future<void> fetchStockData() async {
    isLoading.value = true;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;

      if (shopId != 0) {
        List<ProductResponse> list = await ApiProduct.getProductsByShop(shopId);

        // กรองเอาเฉพาะสินค้าที่สถานะเป็น true
        list = list.where((p) => p.status == true).toList();

        products.assignAll(list);
        _applySortAndFilter();
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

  // 🏷️ ดึงหมวดหมู่
  Future<void> fetchCategories() async {
    isLoadingCategories.value = true;
    try {
      var result = await ApiProduct.getCategories();
      categories.assignAll(result);
    } catch (e) {
      print("Error fetching categories: $e");
    } finally {
      isLoadingCategories.value = false;
    }
  }

  void filterByCategory(int? id) {
    selectedCategoryId.value = id ?? 0;
    _applySortAndFilter();
  }

  void toggleSort() {
    isAscending.value = !isAscending.value;
    _applySortAndFilter();
  }

  void _applySortAndFilter() {
    String query = searchCtrl.text.toLowerCase();
    int catId = selectedCategoryId.value;

    var result = products.where((p) {
      bool matchesSearch = p.name.toLowerCase().contains(query) ||
          (p.barcode != null && p.barcode!.contains(query));

      bool matchesCategory = (catId == 0) || (p.categoryId == catId);

      return matchesSearch && matchesCategory;
    }).toList();

    // เรียงลำดับสต็อก
    if (isAscending.value) {
      result.sort((a, b) => a.stock.compareTo(b.stock)); // น้อย -> มาก
    } else {
      result.sort((a, b) => b.stock.compareTo(a.stock)); // มาก -> น้อย
    }

    filteredProducts.assignAll(result);
  }

  void searchProduct(String query) {
    _applySortAndFilter();
  }

  // ✨ ฟังก์ชันเปิดกล้องสแกน
  Future<void> openScanner() async {
    var result = await Get.to(() => const ScanBarcodePage());
    if (result != null && result is String) {
      searchCtrl.text = result;
      searchProduct(result);
    }
  }

  void changeTab(int index) => selectedIndex.value = index;
}