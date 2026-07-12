import 'package:eazy_store/page/sale_producct/scanBarcode/scan_barcode.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/model/response/product_response.dart';
import 'package:eazy_store/model/request/category_model.dart';
import 'package:eazy_store/utils/thai_sort.dart';
import 'package:flutter/material.dart';

class BuyProductsController extends GetxController {
  var isLoading = true.obs;

  // สินค้าทั้งหมดที่ตรงกับตัวกรอง/คำค้นหาปัจจุบัน (ดึงมาครั้งเดียว ไม่ให้
  // backend แบ่งหน้า) เพราะหน้านี้เลือกสินค้าหลายชิ้นข้ามหน้าได้ ถ้าให้
  // backend แบ่งหน้าแทน การเลือกที่ทำไว้ในหน้าก่อนจะหายทันทีที่เปลี่ยนหน้า
  // (fetch หน้าใหม่มาทับของเดิม)
  var allProducts = <ProductResponse>[].obs;

  // สินค้าที่แสดงในหน้าปัจจุบัน (ตัดมาจาก allProducts)
  var products = <ProductResponse>[].obs;

  var categories = <CategoryModel>[].obs;

  // สร้าง Controller สำหรับช่องค้นหา

  final TextEditingController searchCtrl = TextEditingController();

  var selectedCategoryId = 0.obs;
  var searchQuery = ''.obs;
  var sortType = 'stock_asc'.obs;

  // Pagination: ทำฝั่งแอปเองจาก allProducts (ดู comment ด้านบน)
  var currentPage = 1.obs;
  var itemsPerPage = 10.obs;
  var totalPages = 1.obs;

  // ขอมาทีเดียวให้ครบ (ร้านหนึ่งไม่น่ามีสินค้าเกินนี้) แทนที่จะให้ backend
  // แบ่งหน้า ซึ่ง default เป็น limit=10 ถ้าไม่ส่งค่ามา
  static const int _fetchAllLimit = 100000;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
    fetchProducts();

    // เมื่อ searchQuery เปลี่ยน ให้รอ 500ms แล้วโหลด API
    debounce(searchQuery, (_) {
      currentPage.value = 1;
      fetchProducts();
    }, time: 500.milliseconds);
  }

  void applyFilter({required int categoryId, required String sortValue}) {
    selectedCategoryId.value = categoryId;
    sortType.value = sortValue;
    currentPage.value = 1;
    fetchProducts();
  }

  void clearFilter() {
    selectedCategoryId.value = 0;
    sortType.value = 'stock_asc';
    currentPage.value = 1;
    fetchProducts();
  }

  Future<void> loadCategories() async {
    var res = await ApiProduct.getCategories();
    res.sort((a, b) => thaiSortKey(a.name).compareTo(thaiSortKey(b.name)));
    categories.assignAll(res);
  }

  Future<void> fetchProducts() async {
    try {
      isLoading(true);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;

      // ใช้ API หลักตัวเดียวที่รองรับทั้ง search, category และ sort
      var response = await ApiProduct.getProductsByShop(
        shopId,
        categoryId: selectedCategoryId.value,
        search: searchQuery.value,
        sort: sortType.value,
        limit: _fetchAllLimit,
      );

      if (response is ProductPagedResponse) {
        allProducts.assignAll(response.items);
      } else if (response is List<ProductResponse>) {
        allProducts.assignAll(response);
      } else {
        allProducts.clear();
      }

      totalPages.value = allProducts.isEmpty
          ? 1
          : (allProducts.length / itemsPerPage.value).ceil();
      if (currentPage.value > totalPages.value) {
        currentPage.value = totalPages.value;
      }
      _applyPage();
    } catch (e) {
      print("Fetch Error: $e");
    } finally {
      isLoading(false);
    }
  }

  void _applyPage() {
    final start = (currentPage.value - 1) * itemsPerPage.value;
    if (start >= allProducts.length) {
      products.clear();
      return;
    }
    final end = (start + itemsPerPage.value).clamp(0, allProducts.length);
    products.assignAll(allProducts.sublist(start, end));
  }

  void updateLimit(int limit) {
    itemsPerPage.value = limit;
    currentPage.value = 1;
    totalPages.value = allProducts.isEmpty
        ? 1
        : (allProducts.length / limit).ceil();
    _applyPage();
  }

  void changePage(int page) {
    if (page >= 1 && page <= totalPages.value) {
      currentPage.value = page;
      _applyPage();
    }
  }

  // ✅ ฟังก์ชันเปิดสแกนเนอร์
  Future<void> openScanner() async {
    var result = await Get.to(() => const ScanBarcodePage());
    if (result != null && result is String) {
      searchCtrl.text = result;      // ใส่รหัสที่สแกนได้ลงในช่องพิมพ์
      searchQuery.value = result;   // อัปเดตค่าเพื่อไปดึง API (fetchProducts จะถูกเรียกอัตโนมัติจาก debounce/ever)
    }
  }

  void toggleProduct(int index) {
    products[index].isSelected = !products[index].isSelected;
    products.refresh();
    allProducts.refresh();
  }

  int get selectedCount => allProducts.where((p) => p.isSelected).length;
  List<ProductResponse> get selectedProducts =>
      allProducts.where((p) => p.isSelected).toList();

  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }
}