import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/model/response/product_response.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class AddStockController extends GetxController {
  // ---------------- State Variables ----------------
  var selectedIndex = 1.obs; // เมนู Stock ลำดับที่ 1
  var isSearching = false.obs;
  Rx<ProductResponse?> foundProduct = Rx<ProductResponse?>(null);
  var calculatedTotal = 0.obs;
  Timer? _debounce;

  // ---------------- Controllers ----------------
  final searchController = TextEditingController();
  final nameController = TextEditingController();
  final costController = TextEditingController();
  final salePriceController = TextEditingController();
  final currentStockController = TextEditingController();
  final addAmountController = TextEditingController();
  final unitController = TextEditingController();
  final categoryController = TextEditingController();

  @override
  void onInit() {
    super.onInit();

    searchController.addListener(() {
      onSearchChanged(searchController.text);
    });

    addAmountController.addListener(() {
      if (foundProduct.value != null) {
        int current = int.tryParse(currentStockController.text) ?? 0;
        int add = int.tryParse(addAmountController.text) ?? 0;
        calculatedTotal.value = current + add;
      }
    });
  }

  @override
  void onClose() {
    _debounce?.cancel();
    searchController.dispose();
    nameController.dispose();
    costController.dispose();
    salePriceController.dispose();
    currentStockController.dispose();
    addAmountController.dispose();
    unitController.dispose();
    categoryController.dispose();
    super.onClose();
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        handleSearch(query);
      } else {
        handleClear();
      }
    });
  }
  // ---------------- Functions ----------------

  // 🔍 ค้นหาสินค้า
  // 🔍 ค้นหาสินค้า (เปลี่ยนมาใช้ API Search โดยตรง)
  Future<void> handleSearch([String? query]) async {
    String keyword = query ?? searchController.text.trim();
    if (keyword.isEmpty) {
      handleClear();
      return;
    }

    isSearching.value = true;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;

      // ✅ เปลี่ยนจากดึงทั้งหมด มาเป็นการยิง Search API รายตัว
      ProductResponse? match = await ApiProduct.searchProduct(keyword, shopId);

      if (match != null) {
        foundProduct.value = match;

        // อัปเดตข้อมูลลง Controller
        nameController.text = match.name;
        // ป้องกัน Error ถ้าค่าเป็น Null (ใช้ ?. และ ?? เหมือนเดิม)
        costController.text = (match.costPrice ?? 0).toStringAsFixed(2);
        salePriceController.text = (match.sellPrice ?? 0).toStringAsFixed(2);
        currentStockController.text = (match.stock ?? 0).toString();
        unitController.text = match.unit ?? '';
        categoryController.text = match.category?.name ?? 'ทั่วไป';

        calculatedTotal.value = match.stock ?? 0;
      } else {
        // ถ้าไม่เจอสินค้า ให้ล้างค่า แต่ไม่ต้องแจ้งเตือน Snack เดี๋ยวมันเด้งรัวๆ ตอนพิมพ์
        foundProduct.value = null;
      }
    } catch (e) {
      print("Search Error: $e");
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> refreshCurrentProduct() async {
    if (searchController.text.isNotEmpty) {
      await handleSearch(searchController.text);
    }
    return Future.value();
  }

  // 🧹 ล้างหน้าจอ
  void handleClear() {
    foundProduct.value = null;
    nameController.clear();
    costController.clear();
    salePriceController.clear();
    currentStockController.clear();
    addAmountController.clear();
    unitController.clear();
    categoryController.clear();
    calculatedTotal.value = 0;
  }

  // 💾 บันทึกจริง (API)
  Future<void> executeSave(int amount) async {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    bool success = await ApiProduct.updateStock(
      foundProduct.value!.productId!,
      amount,
    );

    Get.back(); // Hide Loading

    if (success) {
      Get.snackbar(
        "สำเร็จ",
        "เพิ่มสต็อกเรียบร้อยแล้ว",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      handleClear();
      searchController.clear();
    } else {
      Get.snackbar(
        "ผิดพลาด",
        "บันทึกไม่สำเร็จ กรุณาลองใหม่",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
