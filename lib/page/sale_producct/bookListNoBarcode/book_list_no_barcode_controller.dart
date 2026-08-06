import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/model/request/category_model.dart';
import 'package:eazy_store/model/response/product_response.dart';
import 'package:eazy_store/page/sale_producct/sale/checkout_controller.dart';
import 'package:eazy_store/page/sale_producct/sale/checkout_page.dart';
import 'package:eazy_store/utils/thai_sort.dart';

// 🛒 Import ตัว Model กลางมาใช้ เพื่อให้เป็น Type เดียวกับในตะกร้า
import 'package:eazy_store/model/request/baskets_model.dart';

class ManualListController extends GetxController {
  var isLoading = true.obs;

  // ── แท็บ "ไม่มีบาร์โค้ด" ──
  // ใช้ ProductItem จาก baskets_model.dart
  var allProducts = <ProductItem>[].obs;
  var filteredProducts = <ProductItem>[].obs; // หลังค้นหา+เรียง (ก่อนตัดหน้า)
  var pagedProducts = <ProductItem>[].obs; // หน้าปัจจุบันที่แสดงจริง

  // ── แท็บ "มีบาร์โค้ด" ──
  var allBarcodeProducts = <ProductItem>[].obs;
  var filteredBarcodeProducts = <ProductItem>[].obs;
  var pagedBarcodeProducts = <ProductItem>[].obs;

  // เก็บสถานะการเลือกแยกไว้ (เพราะ ProductItem ใน basket ไม่มี isSelected)
  // ใช้ร่วมกันทั้ง 2 แท็บ — เลือกจากแท็บไหนก็รวมลงตะกร้าเดียวกัน
  var selectedIds = <String>{}.obs;

  // ตัวกรอง (หมวดหมู่ + จัดเรียง) — ใช้ร่วมกันทั้ง 2 แท็บ เหมือนหน้าเช็คสต็อกสินค้า
  var categories = <CategoryModel>[].obs;
  var selectedCategoryId = 0.obs;
  var selectedSortOption = "name_asc".obs;
  var searchQuery = "".obs;

  // pagination: แยกกันคนละแท็บ เพราะจำนวนรายการของแต่ละแท็บไม่เท่ากัน
  var currentPage = 1.obs;
  var itemsPerPage = 10.obs;
  var totalPages = 1.obs;

  var currentPageBarcode = 1.obs;
  var itemsPerPageBarcode = 10.obs;
  var totalPagesBarcode = 1.obs;

  @override
  void onInit() {
    super.onInit();
    fetchInitialData();
    debounce(searchQuery, (_) => filterProducts(), time: 300.milliseconds);
  }

  Future<void> fetchInitialData() async {
    try {
      isLoading(true);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 1;
      await Future.wait([
        fetchCategories(),
        fetchProducts(shopId),
        fetchBarcodeProducts(shopId),
      ]);
    } catch (e) {
      print("Initial Data Error: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchCategories() async {
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
    }
  }

  Future<void> fetchProducts(int shopId) async {
    try {
      final List<dynamic> data = await ApiProduct.getNullBarcodeProducts(
        shopId,
        categoryId: selectedCategoryId.value != 0 ? selectedCategoryId.value : null,
      );
      _mapDataToProducts(data);
    } catch (e) {
      print("Fetch Products Error: $e");
    }
  }

  // โหลดสินค้าที่ "มีบาร์โค้ด" — ดึงสินค้าทั้งหมดจากร้าน แล้วกรองเอาเฉพาะตัวที่มี
  // บาร์โค้ด (getProductsByShop คืน ProductResponse มาให้อยู่แล้ว)
  Future<void> fetchBarcodeProducts(int shopId, {int? categoryId}) async {
    try {
      final result = await ApiProduct.getProductsByShop(
        shopId,
        categoryId: categoryId,
        limit: 1000,
      );

      List<ProductResponse> list = [];
      if (result is ProductPagedResponse) {
        list = result.items;
      } else if (result is List<ProductResponse>) {
        list = result;
      }

      final products = list
          .where(
            (p) => p.status == true && (p.barcode ?? '').trim().isNotEmpty,
          )
          .map(
            (p) => ProductItem(
              id: (p.productId ?? 0).toString(),
              name: p.name,
              price: p.sellPrice,
              category: (p.categoryName ?? p.category?.name ?? "อื่นๆ").trim(),
              imagePath: p.imgProduct,
              maxStock: p.stock,
              unit: p.unit.trim().isNotEmpty ? p.unit.trim() : 'ชิ้น',
            ),
          )
          .toList();

      allBarcodeProducts.assignAll(products);
      _filterBarcode();
    } catch (e) {
      print("Fetch Barcode Products Error: $e");
    }
  }

  Future<void> refreshProducts(int? categoryId) async {
    try {
      isLoading(true);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 1;
      await Future.wait([
        () async {
          final data = await ApiProduct.getNullBarcodeProducts(
            shopId,
            categoryId: categoryId,
          );
          _mapDataToProducts(data);
        }(),
        fetchBarcodeProducts(shopId, categoryId: categoryId),
      ]);
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
        unit: (item['unit'] ?? '').toString().trim().isNotEmpty
            ? item['unit'].toString().trim()
            : 'ชิ้น',
      );
    }).toList();
    allProducts.assignAll(products);
    _filterNoBarcode();
  }

  // กรองด้วย searchQuery + จัดเรียง — แยกฟังก์ชันของแต่ละแท็บ
  // (หมวดหมู่ถูก filter จาก API แล้วตอน fetch/refresh)
  void filterProducts() {
    _filterNoBarcode();
    _filterBarcode();
  }

  void _filterNoBarcode() {
    final q = searchQuery.value.toLowerCase();
    var result = allProducts.where((p) => p.name.toLowerCase().contains(q)).toList();
    _sortItems(result);
    filteredProducts.assignAll(result);
    currentPage.value = 1;
    _paginateNoBarcode();
  }

  void _filterBarcode() {
    final q = searchQuery.value.toLowerCase();
    var result = allBarcodeProducts.where((p) => p.name.toLowerCase().contains(q)).toList();
    _sortItems(result);
    filteredBarcodeProducts.assignAll(result);
    currentPageBarcode.value = 1;
    _paginateBarcode();
  }

  void _sortItems(List<ProductItem> items) {
    switch (selectedSortOption.value) {
      case "name_desc":
        items.sort((a, b) => thaiSortKey(b.name).compareTo(thaiSortKey(a.name)));
        break;
      case "stock_asc":
        items.sort((a, b) => a.maxStock.compareTo(b.maxStock));
        break;
      case "stock_desc":
        items.sort((a, b) => b.maxStock.compareTo(a.maxStock));
        break;
      case "name_asc":
      default:
        items.sort((a, b) => thaiSortKey(a.name).compareTo(thaiSortKey(b.name)));
        break;
    }
  }

  // ---------------- Pagination (ตัดหน้าฝั่ง client เพราะข้อมูลถูกโหลดมาครบแล้ว) ----------------

  void _paginateNoBarcode() {
    final total = filteredProducts.length;
    totalPages.value = total == 0 ? 1 : (total / itemsPerPage.value).ceil();
    if (currentPage.value > totalPages.value) currentPage.value = totalPages.value;
    final start = (currentPage.value - 1) * itemsPerPage.value;
    if (start >= total) {
      pagedProducts.clear();
      return;
    }
    final end = (start + itemsPerPage.value).clamp(0, total);
    pagedProducts.assignAll(filteredProducts.sublist(start, end));
  }

  void _paginateBarcode() {
    final total = filteredBarcodeProducts.length;
    totalPagesBarcode.value = total == 0 ? 1 : (total / itemsPerPageBarcode.value).ceil();
    if (currentPageBarcode.value > totalPagesBarcode.value) {
      currentPageBarcode.value = totalPagesBarcode.value;
    }
    final start = (currentPageBarcode.value - 1) * itemsPerPageBarcode.value;
    if (start >= total) {
      pagedBarcodeProducts.clear();
      return;
    }
    final end = (start + itemsPerPageBarcode.value).clamp(0, total);
    pagedBarcodeProducts.assignAll(filteredBarcodeProducts.sublist(start, end));
  }

  void updateLimit(int limit) {
    itemsPerPage.value = limit;
    currentPage.value = 1;
    _paginateNoBarcode();
  }

  void changePage(int page) {
    if (page >= 1 && page <= totalPages.value) {
      currentPage.value = page;
      _paginateNoBarcode();
    }
  }

  void updateLimitBarcode(int limit) {
    itemsPerPageBarcode.value = limit;
    currentPageBarcode.value = 1;
    _paginateBarcode();
  }

  void changePageBarcode(int page) {
    if (page >= 1 && page <= totalPagesBarcode.value) {
      currentPageBarcode.value = page;
      _paginateBarcode();
    }
  }

  // ---------------- ตัวกรอง (หมวดหมู่ + จัดเรียง) ----------------

  void applyFilter({required int categoryId, required String sortOption}) {
    selectedCategoryId.value = categoryId;
    selectedSortOption.value = sortOption;
    refreshProducts(categoryId != 0 ? categoryId : null);
  }

  void clearFilter() {
    selectedCategoryId.value = 0;
    selectedSortOption.value = "name_asc";
    refreshProducts(null);
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
