import 'dart:async';
import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/model/request/category_model.dart';
import 'package:eazy_store/model/response/product_response.dart';
import 'package:eazy_store/page/sale_producct/scanBarcode/scan_barcode.dart';
import 'package:eazy_store/utils/thai_sort.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckStockController extends GetxController {
  // ---------------- State Variables ----------------
  var isLoading = true.obs;
  var products = <ProductResponse>[].obs;
  var filteredProducts = <ProductResponse>[].obs;
  var selectedIndex = 0.obs;

  // ค่าตรงกับที่ backend รองรับ: name_asc, name_desc, stock_asc, stock_desc
  var selectedSortOption = "name_asc".obs;

  var categories = <CategoryModel>[].obs;
  var selectedCategoryId = 0.obs;
  var isLoadingCategories = false.obs;

  // Pagination Variables
  var currentPage = 1.obs;
  var itemsPerPage = 10.obs;
  var totalPages = 1.obs;
  var totalItems = 0.obs;

  final TextEditingController searchCtrl = TextEditingController();

  // ป้องกัน race condition: ถ้าผู้ใช้กดเปลี่ยนหน้าเร็วๆ ก่อนที่ request เดิม
  // จะตอบกลับ (เช่น backend ตื่นช้าตอน cold start บน Render) request เก่า
  // อาจตอบกลับมาทีหลัง request ใหม่ แล้วทับข้อมูลของหน้าที่ถูกต้องทิ้งไป
  int _fetchGeneration = 0;

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

  // ---------------- API Functions ----------------

  Future<void> fetchStockData() async {
    isLoading.value = true;
    final int requestGeneration = ++_fetchGeneration;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;

      if (shopId != 0) {
        var result = await ApiProduct.getProductsByShop(
          shopId,
          page: currentPage.value,
          limit: itemsPerPage.value,
          search: "",
          categoryId: selectedCategoryId.value != 0 ? selectedCategoryId.value : null,
          sort: selectedSortOption.value,
        );

        // มี request ใหม่กว่าเริ่มไปแล้วระหว่างที่รอ await อยู่ ทิ้งผลลัพธ์
        // ของ request นี้เพื่อไม่ให้ทับข้อมูลของหน้าปัจจุบัน
        if (requestGeneration != _fetchGeneration) return;

        if (result is ProductPagedResponse) {
          products.assignAll(result.items);
          totalPages.value = result.totalPages;
          totalItems.value = result.totalItems;
        } else if (result is List<ProductResponse>) {
          products.assignAll(result);
        }

        _applySortAndFilter();
      }
    } catch (e) {
      print("Fetch Error: $e");
    } finally {
      if (requestGeneration == _fetchGeneration) {
        isLoading.value = false;
      }
    }
  }

  Future<void> searchProduct(String query) async {
    if (query.isEmpty) {
      currentPage.value = 1;
      fetchStockData();
      return;
    }

    isLoading.value = true;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;

      ProductResponse? result = await ApiProduct.searchProduct(query, shopId);

      if (result != null) {
        if (result.status == true) {
          filteredProducts.assignAll([result]);
        } else {
          filteredProducts.clear();
        }
        totalPages.value = 1;
        totalItems.value = filteredProducts.length;
      } else {
        filteredProducts.clear();
        totalItems.value = 0;
      }
    } catch (e) {
      print("Search Error: $e");
      filteredProducts.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCategories() async {
    isLoadingCategories.value = true;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;
      var result = await ApiProduct.getCategories(shopId);
      // Remove duplicates by categoryId
      final seen = <int>{};
      final uniqueList = result.where((cat) => seen.add(cat.categoryId)).toList();
      uniqueList.sort(
        (a, b) => thaiSortKey(a.name).compareTo(thaiSortKey(b.name)),
      );
      categories.assignAll(uniqueList);
    } catch (e) {
      print("Error fetching categories: $e");
    } finally {
      isLoadingCategories.value = false;
    }
  }

  // ---------------- UI Support Functions ----------------

  void updateLimit(int limit) {
    itemsPerPage.value = limit;
    currentPage.value = 1;
    fetchStockData();
  }

  void changePage(int page) {
    if (page >= 1 && page <= totalPages.value) {
      currentPage.value = page;
      fetchStockData();
    }
  }

  Future<void> openScanner() async {
    var result = await Get.to(() => const ScanBarcodePage());
    if (result != null && result is String) {
      searchCtrl.text = result;
      searchProduct(result);
    }
  }

  void _applySortAndFilter() {
    var result = products.where((p) => p.status == true).toList();

    switch (selectedSortOption.value) {
      case "name_desc":
        result.sort(
          (a, b) => thaiSortKey(b.name).compareTo(thaiSortKey(a.name)),
        );
        break;
      case "stock_asc":
        result.sort((a, b) => a.stock.compareTo(b.stock));
        break;
      case "stock_desc":
        result.sort((a, b) => b.stock.compareTo(a.stock));
        break;
      case "name_asc":
      default:
        result.sort(
          (a, b) => thaiSortKey(a.name).compareTo(thaiSortKey(b.name)),
        );
        break;
    }
    filteredProducts.assignAll(result);
  }

  void applyFilter({required int categoryId, required String sortOption}) {
    selectedCategoryId.value = categoryId;
    selectedSortOption.value = sortOption;
    currentPage.value = 1;
    fetchStockData();
  }

  void clearFilter() {
    selectedCategoryId.value = 0;
    selectedSortOption.value = "name_asc";
    currentPage.value = 1;
    fetchStockData();
  }

  void changeTab(int index) => selectedIndex.value = index;
}
