import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/model/response/product_response.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddStockController extends GetxController {
  // ---------------- State Variables ----------------
  var selectedIndex = 1.obs; // เมนู Stock ลำดับที่ 1
  var isSearching = false.obs;
  Rx<ProductResponse?> foundProduct = Rx<ProductResponse?>(null);
  var calculatedTotal = 0.obs;

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
    // 🧮 ฟังชั่นคำนวณยอดรวมทันทีที่พิมพ์ตัวเลข
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

  // ---------------- Functions ----------------

  // 🔍 ค้นหาสินค้า
  Future<void> handleSearch() async {
    String keyword = searchController.text.trim();
    if (keyword.isEmpty) return;

    isSearching.value = true;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;

      List<ProductResponse> allProducts = await ApiProduct.getProductsByShop(shopId);

      var match = allProducts.firstWhereOrNull(
        (p) => (p.barcode == keyword) || (p.name.contains(keyword)),
      );

      if (match != null) {
        foundProduct.value = match;
        nameController.text = match.name;
        costController.text = match.costPrice.toStringAsFixed(2);
        salePriceController.text = match.sellPrice.toStringAsFixed(2);
        currentStockController.text = match.stock.toString();
        unitController.text = match.unit;
        categoryController.text = match.category?.name ?? 'ทั่วไป';

        addAmountController.clear();
        calculatedTotal.value = match.stock;

        Get.snackbar(
          "สำเร็จ",
          "พบสินค้า: ${match.name}",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      } else {
        handleClear();
        Get.snackbar(
          "ไม่พบข้อมูล",
          "ไม่มีสินค้ารหัส/ชื่อนี้ในระบบ",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      print(e);
    } finally {
      isSearching.value = false;
    }
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
