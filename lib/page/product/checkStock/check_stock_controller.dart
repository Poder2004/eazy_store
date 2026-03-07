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

  // ตัวแปรสำหรับ Pagination
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

  //  ดึงข้อมูลสินค้า
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
          search: searchCtrl.text,
          categoryId: selectedCategoryId.value != 0
              ? selectedCategoryId.value
              : null, // ✨ ส่งหมวดหมู่
          sort: isAscending.value ? "asc" : "desc",
        );

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
      isLoading.value = false;
    }
  }

  //  ดึงหมวดหมู่
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

  //  ฟังก์ชันสำหรับเปลี่ยนหน้า
  void changePage(int page) {
    if (page >= 1 && page <= totalPages.value) {
      currentPage.value = page;
      fetchStockData();
    }
  }

  //  ฟังก์ชันเปลี่ยนจำนวนรายการต่อหน้า
  void updateLimit(int limit) {
    itemsPerPage.value = limit;
    currentPage.value = 1; // รีเซ็ตไปหน้าแรกเสมอเมื่อเปลี่ยนจำนวนรายการ
    fetchStockData();
  }

  void filterByCategory(int? id) {
    selectedCategoryId.value = id ?? 0;
    currentPage.value = 1;
    fetchStockData(); // เปลี่ยนจาก _applySortAndFilter() เป็นดึงข้อมูลใหม่
  }

 void toggleSort() {
    isAscending.value = !isAscending.value;
    currentPage.value = 1; // ✨ รีเซ็ตไปหน้า 1
    fetchStockData();      // ✨ ดึงข้อมูลใหม่จาก Server พร้อม Sort ตัวใหม่
  }

  void _applySortAndFilter() {
    // 1. ดึงค่าปัจจุบันจาก Controller
    String query = searchCtrl.text.toLowerCase();
    int catId = selectedCategoryId.value;

    // 2. นำข้อมูลที่ได้จาก API (หน้าปัจจุบัน) มาเริ่มกรอง
    var result = products.where((p) {
      // กรองสถานะต้องเป็น true
      bool matchesStatus = p.status == true;

      // กรองคำค้นหา (ชื่อ หรือ บาร์โค้ด)
      bool matchesSearch =
          p.name.toLowerCase().contains(query) ||
          (p.barcode != null && p.barcode!.contains(query));

      // ✨ กรองหมวดหมู่ (ต้องกลับมาใส่ตรงนี้!)
      bool matchesCategory = (catId == 0) || (p.categoryId == catId);

      return matchesStatus && matchesSearch && matchesCategory;
    }).toList();

    // 3. เรียงลำดับสต็อกตามที่ User เลือก
    if (isAscending.value) {
      // น้อย -> มาก (0 จะอยู่หน้าแรกๆ)
      result.sort((a, b) => a.stock.compareTo(b.stock));
    } else {
      // มาก -> น้อย (0 จะอยู่หน้าท้ายๆ หรือลำดับสุดท้ายของหน้า)
      result.sort((a, b) => b.stock.compareTo(a.stock));
    }

    // 4. อัปเดต UI
    filteredProducts.assignAll(result);
  }

  void searchProduct(String query) {
    currentPage.value = 1;
    fetchStockData(); // เปลี่ยนจาก _applySortAndFilter() เป็นดึงข้อมูลใหม่
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
