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
import '../debtRegister/debt_register.dart';
import 'debtor_book_sheet.dart';

class DebtSaleController extends GetxController {
  final debtorNameController = TextEditingController();
  final debtorPhoneController = TextEditingController();
  final payAmountController = TextEditingController();
  final debtRemarkController = TextEditingController();

  // ลูกหนี้ที่เลือกอยู่ (เป็น Rx เพื่อให้การ์ดเลือกลูกหนี้อัปเดตอัตโนมัติ)
  final selectedDebtorRx = Rxn<DebtorResponse>();
  DebtorResponse? get selectedDebtor => selectedDebtorRx.value;

  // --- สมุดลูกหนี้ (รายชื่อลูกหนี้ทั้งหมด เรียงตามตัวอักษร + ช่องค้นหาเดียวในระบบ) ---
  final bookSearchController = TextEditingController();
  var allDebtors = <DebtorResponse>[].obs;
  var bookResults = <DebtorResponse>[].obs;
  var isLoadingBook = false.obs;
  var isSearchingBook = false.obs;
  var bookKeyword = "".obs;
  var bookError = "".obs;
  Timer? debounce;

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
    bookSearchController.dispose();
    super.onClose();
  }

  // ================= ยอดเงิน =================

  /// ยอดที่ลูกค้าต้องเซ็นค้างจริง (ไม่ติดลบ จ่ายเกินถือว่าค้าง 0)
  double remainingDebt(double totalPrice) {
    final double debt = totalPrice - payAmount.value;
    return debt > 0 ? debt : 0.0;
  }

  /// เงินทอน (มีเมื่อจ่ายเกินยอดสินค้า)
  double changeAmount(double totalPrice) {
    final double change = payAmount.value - totalPrice;
    return change > 0 ? change : 0.0;
  }

  /// วงเงินที่ลูกหนี้คนนี้ยังค้างได้อีก
  double get creditRemain {
    final debtor = selectedDebtor;
    if (debtor == null) return 0.0;
    final double remain = debtor.creditLimit - debtor.currentDebt;
    return remain > 0 ? remain : 0.0;
  }

  /// รายการนี้ไม่มียอดค้าง (จ่ายครบ/เกิน) = ต้องบันทึกเป็นการขายเงินสดแทน
  bool isCashCase(double totalPrice) =>
      payAmount.value > 0 && remainingDebt(totalPrice) <= 0;

  /// กลับไปหน้าคิดเงิน แล้วเปิดหน้าจ่ายเงินสดให้ต่อเลย พร้อมเติมยอดเงินที่รับมา
  void switchToCashCheckout(CheckoutController checkoutController) {
    FocusManager.instance.primaryFocus?.unfocus();

    final double received = payAmount.value;

    // เคลียร์ข้อมูลฝั่งค้างชำระ ไม่ให้ค้างไว้สับสน (ตะกร้าสินค้ายังอยู่ครบ)
    payAmountController.clear();
    debtRemarkController.clear();

    Get.back(); // กลับหน้าคิดเงิน

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = Get.context;
      final open = checkoutController.openCashPaymentSheet;
      if (ctx == null || open == null) return;

      open(ctx); // เปิดแผ่นจ่ายเงินสด
      // ใส่ยอดเงินที่ลูกค้ายื่นมาให้เลย ระบบจะคำนวณเงินทอนให้เอง
      if (received > 0) {
        checkoutController.receivedAmountController.text = received
            .toInt()
            .toString();
      }
    });
  }

  void selectDebtor(DebtorResponse debtor) {
    selectedDebtorRx.value = debtor;
    debtorNameController.text = debtor.name;
    debtorPhoneController.text = debtor.phone;
    FocusManager.instance.primaryFocus?.unfocus();
  }

  // ================= สมุดลูกหนี้ =================

  /// เปิดสมุดลูกหนี้ (Popup รายชื่อลูกหนี้ทั้งหมด เรียงตามตัวอักษร)
  void openDebtorBook() {
    FocusManager.instance.primaryFocus?.unfocus();
    bookSearchController.clear();
    DebtorBookSheet.show(this);
    loadAllDebtors();
  }

  /// โหลดรายชื่อลูกหนี้ทั้งหมดของร้าน แล้วเรียงตามตัวอักษร
  Future<void> loadAllDebtors({bool forceRefresh = false}) async {
    if (allDebtors.isNotEmpty && !forceRefresh) {
      filterBook(bookSearchController.text);
      return;
    }

    isLoadingBook.value = true;
    bookError.value = "";
    try {
      final prefs = await SharedPreferences.getInstance();
      final int shopId = prefs.getInt('shopId') ?? 0;

      if (shopId == 0) {
        bookError.value = "ไม่พบข้อมูลร้านค้า กรุณาเข้าสู่ระบบใหม่อีกครั้ง";
        return;
      }

      // ดึงมาทีเดียวทั้งหมด (limit สูง) เพื่อให้เลือกจากสมุดได้ครบ
      final result = await ApiDebtor.getDebtorsByShop(
        shopId,
        page: 1,
        limit: 1000,
      );

      List<DebtorResponse> list = [];
      if (result is DebtorPagedResponse) {
        list = List<DebtorResponse>.from(result.items);
      } else if (result is List<DebtorResponse>) {
        list = List<DebtorResponse>.from(result);
      } else {
        bookError.value = "ไม่สามารถโหลดรายชื่อลูกหนี้ได้ กรุณาลองใหม่อีกครั้ง";
        return;
      }

      list.sort(
        (a, b) => a.name.trim().toLowerCase().compareTo(
          b.name.trim().toLowerCase(),
        ),
      );
      allDebtors.assignAll(list);
      filterBook(bookSearchController.text);
    } catch (e) {
      debugPrint("โหลดสมุดลูกหนี้ไม่สำเร็จ: $e");
      bookError.value = "เชื่อมต่อเซิร์ฟเวอร์ไม่สำเร็จ กรุณาลองใหม่อีกครั้ง";
    } finally {
      isLoadingBook.value = false;
    }
  }

  /// ค้นหาภายในสมุดลูกหนี้ (ค้นจากชื่อหรือเบอร์โทร)
  /// ถ้าในเครื่องไม่เจอ จะยิงค้นหาที่เซิร์ฟเวอร์ให้อีกชั้น (เผื่อร้านมีลูกหนี้เยอะเกินที่โหลดมา)
  void filterBook(String keyword) {
    final String key = keyword.trim().toLowerCase();
    bookKeyword.value = keyword;
    debounce?.cancel();

    if (key.isEmpty) {
      bookResults.assignAll(allDebtors);
      isSearchingBook.value = false;
      return;
    }

    bookResults.assignAll(
      allDebtors.where(
        (d) =>
            d.name.toLowerCase().contains(key) ||
            d.phone.replaceAll('-', '').contains(key),
      ),
    );

    if (bookResults.isNotEmpty || key.length < 2) return;

    // ไม่เจอในเครื่อง ค่อยถามเซิร์ฟเวอร์
    debounce = Timer(const Duration(milliseconds: 400), () async {
      isSearchingBook.value = true;
      try {
        final results = await ApiDebtor.searchDebtor(keyword.trim());
        // กันกรณีผู้ใช้พิมพ์ต่อจนคำค้นเปลี่ยนไปแล้ว
        if (bookSearchController.text.trim().toLowerCase() != key) return;
        bookResults.assignAll(results);
      } catch (e) {
        debugPrint("ค้นหาลูกหนี้จากเซิร์ฟเวอร์ไม่สำเร็จ: $e");
      } finally {
        isSearchingBook.value = false;
      }
    });
  }

  /// จัดกลุ่มรายชื่อตามตัวอักษรตัวแรก สำหรับแสดงหัวข้อในสมุด
  Map<String, List<DebtorResponse>> groupedBookResults() {
    final Map<String, List<DebtorResponse>> grouped = {};
    for (final debtor in bookResults) {
      final String name = debtor.name.trim();
      final String letter = name.isEmpty ? "#" : name[0].toUpperCase();
      grouped.putIfAbsent(letter, () => []).add(debtor);
    }
    return grouped;
  }

  /// เลือกลูกหนี้จากสมุด แล้วปิด Popup
  void selectDebtorFromBook(DebtorResponse debtor) {
    Get.back(); // ปิดสมุดลูกหนี้
    selectDebtor(debtor);
  }

  /// เปิดหน้าสมัครบัญชีลูกหนี้ ถ้าสมัครสำเร็จจะเลือกลูกหนี้คนนั้นให้อัตโนมัติ
  Future<void> goToRegisterDebtor() async {
    final result = await Get.to(() => DebtRegisterScreen());

    if (result is DebtorResponse) {
      // มีลูกหนี้ใหม่ ต้องโหลดสมุดใหม่รอบหน้า
      allDebtors.clear();
      // เลือกลูกหนี้คนที่เพิ่งสมัครทันที
      selectDebtor(result);

      Get.snackbar(
        "เลือกลูกหนี้แล้ว",
        "เลือก ${result.name} เป็นผู้ค้างชำระเรียบร้อยแล้ว",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
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

    final double total = checkoutController.totalPrice.toDouble();
    final double debtValue = remainingDebt(total);
    final double change = changeAmount(total);

    // จ่ายครบแล้ว ไม่มียอดค้าง = ไม่ใช่การขายแบบค้างชำระ ให้ไปใช้หน้าขายเงินสดแทน
    if (debtValue <= 0) {
      showErrorDialog(
        change > 0
            ? "ลูกค้าจ่ายเกินยอดสินค้า (เงินทอน ${change.toInt()} บาท)\n"
                  "รายการนี้ไม่มียอดค้างชำระ กรุณาบันทึกเป็นการขายเงินสดแทน"
            : "ลูกค้าจ่ายครบตามยอดสินค้าแล้ว ไม่มียอดค้างชำระ\n"
                  "กรุณาบันทึกเป็นการขายเงินสดแทน",
      );
      return;
    }

    // เช็ควงเงินคงเหลือของลูกหนี้ก่อน (เซิร์ฟเวอร์เช็คซ้ำอีกชั้น)
    if (debtValue > creditRemain) {
      showErrorDialog(
        "ยอดที่เซ็นค้าง ${debtValue.toInt()} บาท เกินวงเงินที่ลูกหนี้ค้างได้\n"
        "วงเงินคงเหลือของ ${selectedDebtor!.name} คือ ${creditRemain.toInt()} บาท",
      );
      return;
    }

    int debt = debtValue.toInt();

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
                      _rowPopupInfo("ยอดสินค้า:", "${total.toInt()} ฿"),
                      const SizedBox(height: 10),
                      _rowPopupInfo(
                        "จ่ายล่วงหน้า:",
                        "${payAmount.value.toInt()} ฿",
                      ),
                      const SizedBox(height: 10),
                      _rowPopupInfo(
                        "วงเงินคงเหลือหลังเซ็น:",
                        "${(creditRemain - debtValue).toInt()} ฿",
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

      if (currentShopId == 0) {
        showErrorDialog("ไม่พบข้อมูลร้านค้า กรุณาล็อกอินใหม่");
        return;
      }

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

      // จ่ายเกินยอดสินค้าไม่ได้ ไม่งั้นเซิร์ฟเวอร์จะเอาส่วนเกินไปหักหนี้ก้อนเก่า
      final double total = checkoutController.totalPrice.toDouble();
      final double effectivePay = payAmount.value > total
          ? total
          : payAmount.value;

      final saleRequest = SaleRequest(
        shopId: currentShopId,
        debtorId: selectedDebtor!.debtorId,
        netPrice: total,
        pay: effectivePay,
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
      debugPrint("บันทึกค้างชำระไม่สำเร็จ: $e");
      showErrorDialog("ไม่สามารถบันทึกรายการได้ กรุณาลองใหม่อีกครั้ง");
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
    selectedDebtorRx.value = null;
    checkoutController.clearAll();
  }
}
