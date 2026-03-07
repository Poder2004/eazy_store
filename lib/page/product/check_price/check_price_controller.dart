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

  @override
  void onInit() {
    super.onInit();
    // โหลดสินค้าทั้งหมดมาโชว์ตอนแรก (หรือจะเว้นว่างไว้รอ Search ก็ได้ครับ)
    fetchInitialData();

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
        fetchInitialData(); // ถ้าลบช่องค้นหา ให้กลับไปแสดงรายการปกติ
      }
    });
  }

  // 🚀 ฟังก์ชันดึงข้อมูลเริ่มต้น (ใช้ getProductsByShop ตามเดิมสำหรับหน้าแรก)
  Future<void> fetchInitialData() async {
    isLoading.value = true;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;
      
      List<ProductResponse> list = await ApiProduct.getProductsByShop(shopId);
      // กรองเฉพาะที่เปิดใช้งานและเรียงชื่อ
      var activeList = list.where((p) => p.status == true).toList();
      activeList.sort((a, b) => a.name.compareTo(b.name));
      
      filteredProducts.assignAll(activeList);
    } catch (e) {
      print("Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // 🔍 ฟังก์ชันค้นหาผ่าน API (searchProduct)
  Future<void> handleApiSearch(String keyword) async {
    isLoading.value = true;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;

      // ✅ เปลี่ยนมาใช้ ApiProduct.searchProduct ตามที่คุณต้องการ
      ProductResponse? result = await ApiProduct.searchProduct(keyword, shopId);

      if (result != null) {
        filteredProducts.assignAll([result]); // แสดงเฉพาะตัวที่เจอ
      } else {
        filteredProducts.clear(); // ถ้าไม่เจอเลยให้ล้างรายการ
      }
    } catch (e) {
      print("Search Error: $e");
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