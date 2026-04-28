import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Imports ---
import '../../../api/api_debtor.dart';
import '../../../api/api_sale.dart';
import '../../../model/request/sales_model_request.dart';
import '../../../model/response/debtor_response.dart';
import '../../sale_producct/sale/checkout_controller.dart';
import '../../homepage/home_page.dart';

class DebtSaleController extends GetxController {
  final debtorNameController = TextEditingController();
  final debtorPhoneController = TextEditingController();
  final payAmountController = TextEditingController();
  final debtRemarkController = TextEditingController();
  final searchController = TextEditingController();

  DebtorResponse? selectedDebtor;

  Timer? debounce;
  var isSearching = false.obs;
  var searchResults = <DebtorResponse>[].obs;
  var showResults = false.obs;
  var isSearchEmpty = true.obs;

  var payAmount = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
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
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void clearSearch() {
    searchController.clear();
    isSearchEmpty.value = true;
    searchResults.clear();
    showResults.value = false;
    FocusManager.instance.primaryFocus?.unfocus();
  }

  // ✨ Popup ยืนยันที่แก้ไขใหม่ โชว์ปุ่มครบ ไม่ต้องเลื่อนหา
  void confirmSubmit(CheckoutController checkoutController) {
    // 1. สั่งปิดคีย์บอร์ดก่อนเสมอ เพื่อไม่ให้จอโดนดันจน Popup เล็กลง
    FocusManager.instance.primaryFocus?.unfocus();

    if (checkoutController.cartItems.isEmpty) {
      showErrorDialog("ไม่มีสินค้าในตะกร้า");
      return;
    }
    if (selectedDebtor == null) {
      showErrorDialog("กรุณาเลือกลูกหนี้ก่อนบันทึก");
      return;
    }

    int debt = (checkoutController.totalPrice - payAmount.value).toInt();

    Get.dialog(
      MediaQuery(
        data: MediaQuery.of(Get.context!).copyWith(
          textScaler: MediaQuery.textScalerOf(
            Get.context!,
          ).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.2),
        ),
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.transparent, // ใช้ Container ด้านในคุมสีแทน
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400), // จำกัดความกว้าง
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            // ✨ 2. เอา SingleChildScrollView ที่คลุมทั้งหน้าออก แล้วใช้ MainAxisSize.min
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.assignment_ind_rounded,
                    size: 40,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "ยืนยันบันทึกค้างชำระ",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // กรอบข้อมูลสรุปยอด
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _rowPopupInfo("ลูกหนี้:", selectedDebtor?.name ?? ""),
                      const SizedBox(height: 10),
                      _rowPopupInfo(
                        "จ่ายล่วงหน้า:",
                        "${payAmount.value.toInt()} ฿",
                      ),
                      const Divider(height: 24, thickness: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "ยอดที่เซ็น:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "$debt ฿",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // ปุ่มกดยืนยัน / ยกเลิก (มองเห็นได้ทันที)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "ยกเลิก",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                          submitDebt(checkoutController);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "ยืนยัน",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // Widget ช่วยจัด Row ใน Popup ให้ยืดหยุ่นขึ้น
  Widget _rowPopupInfo(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 15)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> submitDebt(CheckoutController checkoutController) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int currentShopId = prefs.getInt('shopId') ?? 0;
      String userName =
          prefs.getString('name') ??
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
      Get.back();
      showErrorDialog("เกิดข้อผิดพลาด: $e");
    }
  }

  // ✨ ปรับปรุง Error Dialog ให้สมบูรณ์แบบ
  void showErrorDialog(String message) {
    FocusManager.instance.primaryFocus?.unfocus();
    Get.dialog(
      MediaQuery(
        data: MediaQuery.of(Get.context!).copyWith(
          textScaler: MediaQuery.textScalerOf(
            Get.context!,
          ).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.2),
        ),
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // ให้หดตัวตามเนื้อหา
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 60,
                ),
                const SizedBox(height: 16),
                const Text(
                  "แจ้งเตือน",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(fontSize: 15, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Get.back(),
                    child: const Text(
                      "ตกลง",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
