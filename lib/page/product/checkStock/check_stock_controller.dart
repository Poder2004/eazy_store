import 'dart:async';
import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/model/request/category_model.dart';
import 'package:eazy_store/model/response/product_response.dart';
import 'package:eazy_store/page/sale_producct/scanBarcode/scan_barcode.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckStockController extends GetxController {
  // ---------------- State Variables ----------------
  var isLoading = true.obs;
  var products = <ProductResponse>[].obs;
  var filteredProducts = <ProductResponse>[].obs;
  var selectedIndex = 0.obs;
  var isAscending = true.obs;

  var categories = <CategoryModel>[].obs;
  var selectedCategoryId = 0.obs; // 0 คือ "ทั้งหมด"
  var isLoadingCategories = false.obs;

  // Pagination Variables
  var currentPage = 1.obs;
  var itemsPerPage = 10.obs;
  var totalPages = 1.obs;
  var totalItems = 0.obs;

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

  // ---------------- API Functions ----------------

  /// 🚀 1. ดึงข้อมูลแบบรายการปกติ (Pagination)
  Future<void> fetchStockData() async {
    isLoading.value = true;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;

      if (shopId != 0) {
        var result = await ApiProduct.getProductsByShop(
          shopId,
          page: currentPage.value,
          limit: itemsPerPage.value,
          search: "", // แยก Search ไปใช้ searchProduct API แทน
          categoryId: selectedCategoryId.value != 0 ? selectedCategoryId.value : null,
          sort: isAscending.value ? "asc" : "desc",
        );

        if (result is ProductPagedResponse) {
          products.assignAll(result.items);
          totalPages.value = result.totalPages;
          totalItems.value = result.totalItems;
        } else if (result is List<ProductResponse>) {
          products.assignAll(result);
        }
        
        // กรองและเรียงลำดับข้อมูลที่ได้มา
        _applySortAndFilter();
      }
    } catch (e) {
      print("Fetch Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// 🔍 2. ค้นหาสินค้าเจาะจงด้วย API searchProduct (สำหรับ Search Bar & Scan)
  Future<void> searchProduct(String query) async {
    if (query.isEmpty) {
      currentPage.value = 1;
      fetchStockData(); // ถ้าลบคำค้นหา ให้กลับไปดึงแบบ Pagination ปกติ
      return;
    }

    isLoading.value = true;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;

      // ✨ เรียกใช้ API ค้นหาโดยตรง
      ProductResponse? result = await ApiProduct.searchProduct(query, shopId);

      if (result != null) {
        // กรองเฉพาะสถานะที่เป็น true (ถ้าต้องการ)
        if (result.status == true) {
          filteredProducts.assignAll([result]);
        } else {
          filteredProducts.clear();
        }
        
        // ปรับ Metadata ของ Pagination ให้สอดคล้องกับผลการค้นหา
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

  /// 🏷️ 3. ดึงข้อมูลหมวดหมู่สินค้า
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

  // ---------------- UI Support Functions ----------------

  /// 🔢 เปลี่ยนจำนวนรายการต่อหน้า (Items Per Page)
  void updateLimit(int limit) {
    itemsPerPage.value = limit;
    currentPage.value = 1; // รีเซ็ตไปหน้า 1 เสมอ
    fetchStockData();
  }

  /// 📄 เปลี่ยนหน้า (Next/Previous Page)
  void changePage(int page) {
    if (page >= 1 && page <= totalPages.value) {
      currentPage.value = page;
      fetchStockData();
    }
  }

  /// 📷 เปิดกล้องสแกนบาร์โค้ด
  Future<void> openScanner() async {
    var result = await Get.to(() => const ScanBarcodePage());
    if (result != null && result is String) {
      searchCtrl.text = result;
      searchProduct(result); // เรียก API ค้นหาทันที
    }
  }

  /// 🧹 กรองและเรียงลำดับ Local List
  void _applySortAndFilter() {
    var result = products.where((p) => p.status == true).toList();

    if (isAscending.value) {
      result.sort((a, b) => a.stock.compareTo(b.stock));
    } else {
      result.sort((a, b) => b.stock.compareTo(a.stock));
    }
    filteredProducts.assignAll(result);
  }

  /// 🗂️ กรองตามหมวดหมู่
  void filterByCategory(int? id) {
    selectedCategoryId.value = id ?? 0;
    currentPage.value = 1;
    fetchStockData();
  }

  /// 🔃 สลับการเรียงลำดับ (น้อยไปมาก / มากไปน้อย)
  void toggleSort() {
    isAscending.value = !isAscending.value;
    currentPage.value = 1;
    fetchStockData();
  }

  void changeTab(int index) => selectedIndex.value = index;
}