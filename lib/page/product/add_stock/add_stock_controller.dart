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
  var isSavingPrice = false.obs;
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

  // 💰 Controllers สำหรับแก้ไขราคา
  final editSellPriceCtrl = TextEditingController();
  final editCostPriceCtrl = TextEditingController();

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
    editSellPriceCtrl.dispose();
    editCostPriceCtrl.dispose();
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

        // ตั้งค่าเริ่มต้นให้ช่องแก้ไขราคา
        editSellPriceCtrl.text = (match.sellPrice ?? 0).toStringAsFixed(2);
        editCostPriceCtrl.text = (match.costPrice ?? 0).toStringAsFixed(2);

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
    editSellPriceCtrl.clear();
    editCostPriceCtrl.clear();
    calculatedTotal.value = 0;
  }

  // ✅ ตรวจสอบว่าราคาถูกเปลี่ยนหรือไม่
  bool get _isPriceChanged {
    final newSell = double.tryParse(editSellPriceCtrl.text);
    final newCost = double.tryParse(editCostPriceCtrl.text);
    final origSell = foundProduct.value?.sellPrice ?? 0;
    final origCost = foundProduct.value?.costPrice ?? 0;
    if (newSell == null || newCost == null) return false;
    return newSell != origSell || newCost != origCost;
  }

  // Public getter สำหรับ View
  bool get isPriceChangedPublic => _isPriceChanged;

  // ✅ ตรวจสอบว่ามีการเพิ่มสต็อกหรือไม่
  bool get _hasStockToAdd {
    final amount = int.tryParse(addAmountController.text) ?? 0;
    return amount > 0;
  }

  // Public getter สำหรับ View
  bool get hasStockToAddPublic => _hasStockToAdd;

  // 🔗 ฟังก์ชันหลัก — บันทึกทุกอย่างด้วยปุ่มเดียว
  Future<void> saveAll() async {
    if (foundProduct.value == null) return;

    final hasPrice = _isPriceChanged;
    final hasStock = _hasStockToAdd;

    // ไม่มีการเปลี่ยนแปลงอะไรเลย
    if (!hasPrice && !hasStock) {
      Get.snackbar(
        "แจ้งเตือน",
        "ยังไม่มีการเปลี่ยนแปลงข้อมูล",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    isSavingPrice.value = true;

    try {
      bool priceOk = true;
      bool stockOk = true;

      // --- อัปเดตราคา (ถ้ามีการเปลี่ยน) ---
      if (hasPrice) {
        final newSell = double.tryParse(editSellPriceCtrl.text);
        final newCost = double.tryParse(editCostPriceCtrl.text);
        if (newSell == null || newCost == null) {
          Get.snackbar(
            "แจ้งเตือน",
            "กรุณากรอกราคาให้ถูกต้อง",
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
          isSavingPrice.value = false;
          return;
        }

        final result = await ApiProduct.updateProduct(
          foundProduct.value!.productId!,
          {"sell_price": newSell, "cost_price": newCost},
        );

        if (result != null) {
          salePriceController.text = newSell.toStringAsFixed(2);
          costController.text = newCost.toStringAsFixed(2);
        } else {
          priceOk = false;
        }
      }

      // --- เพิ่มสต็อก (ถ้ามีจำนวน) ---
      if (hasStock) {
        final amount = int.tryParse(addAmountController.text);
        if (amount == null || amount <= 0) {
          Get.snackbar("แจ้งเตือน", "กรุณากรอกจำนวนสต็อกเป็นตัวเลขที่มากกว่า 0",
              backgroundColor: Colors.orange, colorText: Colors.white);
          isSavingPrice.value = false;
          return;
        }
        stockOk = await ApiProduct.updateStock(
          foundProduct.value!.productId!,
          amount,
        );
      }

      // --- แจ้งผลลัพธ์ ---
      if (priceOk && stockOk) {
        String msg = "";
        if (hasPrice && hasStock) msg = "อัปเดตราคาและสต็อกเรียบร้อยแล้ว";
        else if (hasPrice) msg = "อัปเดตราคาเรียบร้อยแล้ว";
        else msg = "เพิ่มสต็อกเรียบร้อยแล้ว";

        Get.snackbar(
          "สำเร็จ",
          msg,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        if (hasStock) {
          handleClear();
          searchController.clear();
        }
      } else {
        Get.snackbar(
          "ผิดพลาด",
          "บันทึกไม่สำเร็จบางส่วน กรุณาลองใหม่",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar("Error", "เกิดข้อผิดพลาด: $e", backgroundColor: Colors.red);
    } finally {
      isSavingPrice.value = false;
    }
  }

  // 💾 เก็บไว้ใช้ใน Dialog ยืนยัน
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
