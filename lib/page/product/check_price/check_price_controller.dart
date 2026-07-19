import 'dart:async';
import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/model/response/product_response.dart';
import 'package:eazy_store/page/sale_producct/scanBarcode/scan_barcode.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PriceController extends GetxController {
  var isLoading = false.obs;
  var filteredProducts = <ProductResponse>[].obs; 
  var selectedIndex = 2.obs;

  Timer? _debounce;
  final TextEditingController searchCtrl = TextEditingController();

  // ขอมาทีเดียวให้ครบ (หน้านี้ไม่มี pagination) แทนที่จะให้ backend
  // แบ่งหน้า ซึ่ง default เป็น limit=10 ถ้าไม่ส่งค่ามา
  static const int _fetchAllLimit = 100000;

  @override
  void onInit() {
    super.onInit();
    // ไม่โหลดสินค้าทั้งหมดตั้งแต่แรก รอให้ผู้ใช้พิมพ์ค้นหาหรือสแกนก่อนค่อยแสดงรายการ
    searchCtrl.addListener(() {
      onSearchChanged(searchCtrl.text);
    });
  }

  @override
  void onClose() {
    _debounce?.cancel();
    searchCtrl.dispose();
    super.onClose();
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        handleApiSearch(query);
      } else {
        filteredProducts.clear(); // ลบช่องค้นหาแล้วให้ซ่อนรายการไว้เหมือนเดิม
      }
    });
  }

  // 🔄 เรียกซ้ำตามคำค้นหาปัจจุบัน (ใช้กับ pull-to-refresh และหลังแก้ไขสินค้า)
  Future<void> refreshCurrentSearch() async {
    final query = searchCtrl.text.trim();
    if (query.isNotEmpty) {
      await handleApiSearch(query);
    } else {
      filteredProducts.clear();
    }
  }

  // 🔍 ฟังก์ชันค้นหาผ่าน API (แบบ LIKE เพื่อให้เจอได้หลายรายการจากคำเดียว)
  Future<void> handleApiSearch(String keyword) async {
    isLoading.value = true;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;

      var result = await ApiProduct.getProductsByShop(
        shopId,
        search: keyword,
        limit: _fetchAllLimit,
      );

      List<ProductResponse> list = [];
      if (result is ProductPagedResponse) {
        list = result.items;
      } else if (result is List<ProductResponse>) {
        list = result;
      }

      var activeList = list.where((p) => p.status == true).toList();
      activeList.sort((a, b) => a.name.compareTo(b.name));

      filteredProducts.assignAll(activeList);
    } catch (e) {
      print("Search Error: $e");
      filteredProducts.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> openScanner() async {
    var result = await Get.to(() => const ScanBarcodePage());
    if (result != null && result is String) {
      searchCtrl.text = result;
      // listener จะทำงานต่อเอง
    }
  }

  void changeTab(int index) => selectedIndex.value = index;
}