import 'package:eazy_store/page/sale_producct/scanBarcode/scan_barcode.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/model/response/product_response.dart';
import 'package:eazy_store/model/request/category_model.dart';
import 'package:flutter/material.dart';

class BuyProductsController extends GetxController {
  var isLoading = true.obs;
  var products = <ProductResponse>[].obs;
  var categories = <CategoryModel>[].obs;
  
  // สร้าง Controller สำหรับช่องค้นหา
 
  final TextEditingController searchCtrl = TextEditingController();

  var selectedCategoryId = 0.obs;
  var searchQuery = ''.obs;
  var sortType = 'stock_asc'.obs;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
    fetchProducts();
    
    // เมื่อ searchQuery เปลี่ยน ให้รอ 500ms แล้วโหลด API
    debounce(searchQuery, (_) => fetchProducts(), time: 500.milliseconds);
    ever(selectedCategoryId, (_) => fetchProducts());
    ever(sortType, (_) => fetchProducts());
  }

  Future<void> loadCategories() async {
    var res = await ApiProduct.getCategories();
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
      );

      if (response is ProductPagedResponse) {
        products.assignAll(response.items);
      } else if (response is List<ProductResponse>) {
        products.assignAll(response);
      }
    } catch (e) {
      print("Fetch Error: $e");
    } finally {
      isLoading(false);
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
  }

  int get selectedCount => products.where((p) => p.isSelected).length;
  List<ProductResponse> get selectedProducts => products.where((p) => p.isSelected).toList();
  
  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }
}