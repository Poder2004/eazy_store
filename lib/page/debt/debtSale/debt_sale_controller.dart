import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Imports ---
import '../../../api/api_debtor.dart';
import '../../../api/api_sale.dart';
import '../../../model/request/sales_model_request.dart';
import '../../../model/response/debtor_response.dart';
import '../../../sale_producct/sale/checkout_controller.dart';
import '../../../homepage/home_page.dart';

class DebtSaleController extends GetxController {
  // --- Controllers สำหรับ TextFields ---
  final debtorNameController = TextEditingController();
  final debtorPhoneController = TextEditingController();
  final payAmountController = TextEditingController();
  final debtRemarkController = TextEditingController();
  final searchController = TextEditingController();

  DebtorResponse? selectedDebtor;

  // --- ตัวแปรสำหรับระบบค้นหา (Observable) ---
  Timer? debounce;
  var isSearching = false.obs;
  var searchResults = <DebtorResponse>[].obs;
  var showResults = false.obs;
  var isSearchEmpty = true.obs;

  // ไว้เก็บค่ายอดจ่ายปัจจุบันเพื่อคำนวณแบบ Real-time
  var payAmount = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    // ดักจับการพิมพ์ยอดจ่ายเงิน เพื่อให้ UI อัปเดต "ยอดที่เซ็น" อัตโนมัติ
    payAmountController.addListener(() {
      payAmount.value = double.tryParse(payAmountController.text) ?? 0.0;
    });
  }

  @override
  void onClose() {
    debounce?.cancel();
    debtorNameController.dispose();
    debtorPhoneController.dispose();
    payAmountController.dispose();
    debtRemarkController.dispose();
    searchController.dispose();
    super.onClose();
  }

  void onSearchChanged(String keyword) {
    
    isSearchEmpty.value = keyword.isEmpty;

    if (keyword.isEmpty) {
      searchResults.clear();
      showResults.value = false;
      return;
    }
    
    if (debounce?.isActive ?? false) debounce!.cancel();
    debounce = Timer(const Duration(milliseconds: 300), () async {
      isSearching.value = true;
      try {
        final results = await ApiDebtor.searchDebtor(keyword);
        searchResults.assignAll(results);
        showResults.value = results.isNotEmpty;
      } catch (e) {
        debugPrint("Error searching: $e");
        searchResults.clear();
      } finally {
        isSearching.value = false;
      }
    });
  }

  void selectDebtor(DebtorResponse debtor) {
    selectedDebtor = debtor;
    debtorNameController.text = debtor.name;
    debtorPhoneController.text = debtor.phone;
    showResults.value = false;
    FocusManager.instance.primaryFocus?.unfocus(); // ซ่อนคีย์บอร์ด
  }

 
  void clearSearch() {
    searchController.clear();
    isSearchEmpty.value = true;
    searchResults.clear();
    showResults.value = false;
    FocusManager.instance.primaryFocus?.unfocus(); // ซ่อนคีย์บอร์ด
  }

  void confirmSubmit(CheckoutController checkoutController) {
    if (checkoutController.cartItems.isEmpty) {
      Get.snackbar("แจ้งเตือน", "ไม่มีสินค้าในตะกร้า",
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    if (selectedDebtor == null) {
      Get.snackbar("แจ้งเตือน", "กรุณาเลือกลูกหนี้ก่อน",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    Get.defaultDialog(
      title: "ยืนยันการทำรายการ",
      middleText: "คุณต้องการบันทึกการค้างชำระของ\n'${selectedDebtor?.name}' ใช่หรือไม่?",
      textConfirm: "ยืนยัน",
      textCancel: "ยกเลิก",
      confirmTextColor: Colors.white,
      buttonColor: Colors.black,
      onConfirm: () {
        Get.back(); // ปิด Dialog ยืนยัน
        submitDebt(checkoutController);
      },
    );
  }

  Future<void> submitDebt(CheckoutController checkoutController) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int currentShopId = prefs.getInt('shopId') ?? 0;
      String userName = prefs.getString('name') ??
          prefs.getString('username') ??
          "พนักงานขาย";

      final groupedMap = <String, List<dynamic>>{};
      for (var item in checkoutController.cartItems) {
        groupedMap.putIfAbsent(item.id, () => []).add(item);
      }

      List<SaleItemRequest> itemsRequest = groupedMap.entries.map((entry) {
        var firstItem = entry.value.first;
        return SaleItemRequest(
          productId: int.parse(firstItem.id),
          amount: entry.value.length,
          pricePerUnit: firstItem.price.toDouble(),
          totalPrice: (firstItem.price * entry.value.length).toDouble(),
        );
      }).toList();

      final saleRequest = SaleRequest(
        shopId: currentShopId,
        debtorId: selectedDebtor!.debtorId,
        netPrice: checkoutController.totalPrice.toDouble(),
        pay: payAmount.value,
        paymentMethod: "ค้างชำระ",
        note: debtRemarkController.text,
        createdBuy: userName,
        saleItems: itemsRequest,
      );

      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final result = await ApiSale.createCreditSale(saleRequest);
      Get.back(); // ปิด Loading

      if (result != null && result.containsKey('sale_id')) {
        Get.snackbar(
          "สำเร็จ",
          "บันทึกการค้างชำระเรียบร้อยแล้ว",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );

        checkoutController.clearAll();
        Get.offAll(() => const HomePage());
      } else {
        String errorMsg = result?['error'] ?? "บันทึกไม่สำเร็จ กรุณาลองใหม่";
        showErrorDialog(errorMsg);
      }
    } catch (e) {
      Get.back(); // ปิด Loading
      showErrorDialog("เกิดข้อผิดพลาด: $e");
    }
  }

  void showErrorDialog(String message) {
    Get.defaultDialog(
      title: "แจ้งเตือน",
      middleText: message,
      textConfirm: "ตกลง",
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () => Get.back(),
    );
  }

  void clearForm(CheckoutController checkoutController) {
    debtorNameController.clear();
    debtorPhoneController.clear();
    payAmountController.clear();
    debtRemarkController.clear();
    selectedDebtor = null;
    checkoutController.clearAll();
  }
}