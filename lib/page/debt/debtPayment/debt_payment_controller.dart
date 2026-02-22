import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eazy_store/api/api_payment.dart';
import 'package:eazy_store/model/request/pay_debt_request.dart';
import '../../../model/response/debtor_response.dart';

enum PaymentMethod { cash, transfer }

class DebtPaymentController extends GetxController {
  // --- ตัวแปร State (ใส่ .obs เพื่อให้ UI อัปเดตอัตโนมัติ) ---
  var selectedIndex = 3.obs;
  var selectedMethod = PaymentMethod.cash.obs;

  var totalDebtAmount = 0.0.obs;
  var amountPaid = 0.0.obs;
  var remainingDebt = 0.0.obs;
  var change = 0.0.obs;

  // --- Controllers ---
  final TextEditingController amountPaidController = TextEditingController();
  final TextEditingController payerNameController = TextEditingController(text: 'เจ้าของร้าน');

  DebtorResponse? debtor;

  @override
  void onInit() {
    super.onInit();
    amountPaidController.addListener(calculateChange);
  }

  @override
  void onClose() {
    amountPaidController.removeListener(calculateChange);
    amountPaidController.dispose();
    payerNameController.dispose();
    super.onClose();
  }

  // เซ็ตค่าเริ่มต้นเมื่อเปิดหน้า
  void initData(DebtorResponse? currentDebtor) {
    debtor = currentDebtor;
    totalDebtAmount.value = (debtor?.currentDebt as num?)?.toDouble() ?? 0.0;
    
    remainingDebt.value = totalDebtAmount.value;
    amountPaid.value = totalDebtAmount.value;

    // ยกเลิก listener ชั่วคราวตอนเซ็ตค่าเริ่มต้น เพื่อไม่ให้คำนวณซ้ำซ้อน
    amountPaidController.removeListener(calculateChange);
    amountPaidController.text = totalDebtAmount.value.toStringAsFixed(0);
    amountPaidController.addListener(calculateChange);
  }

  // คำนวณเงินทอน / หนี้คงเหลือ
  void calculateChange() {
    final input = amountPaidController.text;
    final paid = double.tryParse(input) ?? 0.0;

    amountPaid.value = paid;
    if (paid >= totalDebtAmount.value) {
      change.value = paid - totalDebtAmount.value;
      remainingDebt.value = 0.0;
    } else {
      change.value = 0.0;
      remainingDebt.value = totalDebtAmount.value - paid;
    }
  }

  void setBottomNavIndex(int index) {
    selectedIndex.value = index;
  }

  // ฟังก์ชันเรียก API และตรวจสอบ PIN
  Future<void> validateAndSubmit({
    required String pinCode,
    required VoidCallback onSuccess,
    required VoidCallback onPinIncorrect,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String savedPin = prefs.getString('pinCode') ?? '';
    final int shopId = prefs.getInt('shopId') ?? 0;

    if (savedPin.isEmpty) {
      Get.snackbar('แจ้งเตือน', 'ไม่พบรหัส PIN ในระบบ กรุณา Login ใหม่',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    if (pinCode == savedPin) {
      // 1. แสดง Loading Dialog
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      try {
        final request = PayDebtRequest(
          shopId: shopId,
          debtorId: debtor?.debtorId ?? 0,
          amountPaid: amountPaid.value,
          paymentMethod: selectedMethod.value == PaymentMethod.cash ? 'จ่ายเงินสด' : 'โอนจ่าย',
          payWith: payerNameController.text,
          pinCode: pinCode,
        );

        final result = await ApiPayment.payDebt(request);

        // ปิด Loading Dialog
        Get.back();

        if (result != null && !result.containsKey('error')) {
          // ✅ สำเร็จ - ปิดหน้า PIN แล้วแสดง Dialog สำเร็จ (ผ่าน Callback)
          Get.back(); 
          onSuccess();
        } else {
          // ❌ มี Error จาก Server
          String errorMsg = result != null ? result['error'].toString() : 'เกิดข้อผิดพลาดที่ไม่รู้จัก';
          Get.snackbar('ข้อผิดพลาด', errorMsg,
              backgroundColor: Colors.redAccent, colorText: Colors.white);
        }
      } catch (e) {
        Get.back(); // ปิด Loading
        print("Error submit: $e");
        Get.snackbar('ข้อผิดพลาด', 'เชื่อมต่อล้มเหลว: $e',
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } else {
      // ❌ PIN ผิด
      onPinIncorrect();
    }
  }
}