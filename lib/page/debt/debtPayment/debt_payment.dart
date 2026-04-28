import 'package:flutter/material.dart';
import 'package:get/get.dart';

// --- Imports ไฟล์ของคุณ ---
import 'package:eazy_store/page/menu_bar/bottom_navbar.dart';
import '../../../model/response/debtor_response.dart';
import 'debt_payment_controller.dart'; // ★ Import Controller เข้ามา

// กำหนดสีหลัก
const Color _kPrimaryColor = Color(0xFF6B8E23);
const Color _kBackgroundColor = Color(
  0xFFF4F7FA,
); // สีพื้นหลังให้อ่อนลงดูสบายตา
const Color _kButtonGreen = Color(0xFF10B981); // ปรับเขียวให้ดูทันสมัยขึ้น
const Color _kButtonBlue = Color(0xFF3B82F6); // ปรับฟ้าให้ดูพรีเมียม
const Color _kInputFillColor = Color(0xFFF8FAFC);
const Color _kQRCodePlaceholderColor = Color(0xFFF1F5F9);
const Color _kCardColor = Colors.white;

class DebtPaymentScreen extends StatelessWidget {
  final DebtorResponse? debtor;

  // เรียกใช้งาน Controller
  final DebtPaymentController controller = Get.put(DebtPaymentController());

  DebtPaymentScreen({super.key, this.debtor}) {
    // จ่ายข้อมูลเริ่มต้นให้ Controller ทันทีที่เปิดหน้า
    controller.initData(debtor);
  }

  // --- Widgets UI ---
  Widget _buildPaymentMethodButtons() {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () =>
                  controller.selectedMethod.value = PaymentMethod.cash,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    controller.selectedMethod.value == PaymentMethod.cash
                    ? _kButtonGreen.withOpacity(0.1)
                    : _kCardColor,
                foregroundColor:
                    controller.selectedMethod.value == PaymentMethod.cash
                    ? _kButtonGreen
                    : Colors.blueGrey.shade400,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  side: BorderSide(
                    color: controller.selectedMethod.value == PaymentMethod.cash
                        ? _kButtonGreen
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.payments_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'เงินสด',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: ElevatedButton(
              onPressed: () =>
                  controller.selectedMethod.value = PaymentMethod.transfer,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    controller.selectedMethod.value == PaymentMethod.transfer
                    ? _kButtonBlue.withOpacity(0.1)
                    : _kCardColor,
                foregroundColor:
                    controller.selectedMethod.value == PaymentMethod.transfer
                    ? _kButtonBlue
                    : Colors.blueGrey.shade400,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  side: BorderSide(
                    color:
                        controller.selectedMethod.value ==
                            PaymentMethod.transfer
                        ? _kButtonBlue
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'เงินโอน',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✨ ปรับช่องกรอกข้อมูลให้ยืดหยุ่น ปลดล็อกความสูงออก
  Widget _buildPaymentDetailRow({
    required String label,
    required String value,
    bool isInput = false,
    bool isAction = false,
    TextEditingController? textController,
    bool isRemainingDebt = false,
    bool isChange = false,
  }) {
    final Color valueColor = isAction
        ? Colors.black87
        : isRemainingDebt
        ? Colors.red.shade600
        : isChange
        ? _kButtonGreen
        : Colors.black87;

    String displayValue = value;
    if (!isInput && double.tryParse(value) != null) {
      displayValue = double.parse(value).toStringAsFixed(2);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.blueGrey.shade700,
                fontWeight: (isRemainingDebt || isChange)
                    ? FontWeight.bold
                    : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: isInput
                ? TextField(
                    controller: textController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: valueColor,
                    ),
                    decoration: InputDecoration(
                      isDense: true, // ไม่ให้ช่องกรอกสูงเกินไป
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 12.0,
                      ),
                      filled: true,
                      fillColor: isAction ? Colors.white : _kInputFillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(
                          color: _kButtonBlue,
                          width: 2,
                        ),
                      ),
                    ),
                  )
                : Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: isAction ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10.0),
                      border: isAction
                          ? Border.all(color: Colors.grey.shade300)
                          : null,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        displayValue,
                        style: TextStyle(
                          fontSize: (isRemainingDebt || isChange) ? 22 : 18,
                          fontWeight: FontWeight.bold,
                          color: valueColor,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection() {
    return Obx(() {
      if (controller.selectedMethod.value != PaymentMethod.transfer) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: Column(
          children: [
            const Divider(color: Color(0xFFE2E8F0), thickness: 1, height: 30),
            const Text(
              'คิวอาร์โค้ดชำระเงิน',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              width: 160,
              height: 160,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: _kQRCodePlaceholderColor,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Center(
                  child: Icon(Icons.qr_code_2, size: 80, color: Colors.black45),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // --- Dialogs ---
  void _showPinInputDialog() {
    final pinController = TextEditingController();
    final FocusNode pinFocusNode = FocusNode();

    Get.dialog(
      // ✨ คุมฟอนต์ในป๊อปอัป ไม่ให้ใหญ่จนล้นกรอบ
      MediaQuery(
        data: MediaQuery.of(Get.context!).copyWith(
          textScaler: MediaQuery.textScalerOf(
            Get.context!,
          ).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.2),
        ),
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          contentPadding: const EdgeInsets.all(24.0),
          title: const Text(
            'ยืนยันการชำระเงิน',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.lock_outline_rounded,
                color: Colors.blueGrey,
                size: 50,
              ),
              const SizedBox(height: 20),
              TextField(
                autofocus: true,
                controller: pinController,
                focusNode: pinFocusNode,
                obscureText: true,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(
                  fontSize: 28, // ปรับลดจาก 32 เพื่อให้พิมพ์ 6 ตัวไม่ล้น
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                ),
                decoration: InputDecoration(
                  counterText: "",
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  hintText: '●●●●●●',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    letterSpacing: 4,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onSubmitted: (_) {
                  controller.validateAndSubmit(
                    pinCode: pinController.text,
                    onSuccess: () => _showSuccessDialog(),
                    onPinIncorrect: () {
                      pinController.clear();
                      Get.snackbar(
                        'ข้อผิดพลาด',
                        'รหัส PIN ไม่ถูกต้อง',
                        backgroundColor: Colors.redAccent,
                        colorText: Colors.white,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kButtonGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    controller.validateAndSubmit(
                      pinCode: pinController.text,
                      onSuccess: () => _showSuccessDialog(),
                      onPinIncorrect: () {
                        pinController.clear();
                        Get.snackbar(
                          'ข้อผิดพลาด',
                          'รหัส PIN ไม่ถูกต้อง',
                          backgroundColor: Colors.redAccent,
                          colorText: Colors.white,
                        );
                      },
                    );
                  },
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'ยืนยันรหัส',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Get.back(),
                child: const Text(
                  'ยกเลิก',
                  style: TextStyle(color: Colors.blueGrey, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _showSuccessDialog() {
    Get.dialog(
      MediaQuery(
        data: MediaQuery.of(Get.context!).copyWith(
          textScaler: MediaQuery.textScalerOf(
            Get.context!,
          ).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.2),
        ),
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          contentPadding: const EdgeInsets.all(24.0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  color: _kButtonGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(20.0),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: _kButtonGreen,
                  size: 60,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ชำระเงินสำเร็จ',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kButtonGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    Get.back(); // ปิดหน้าต่าง Success
                    await Future.delayed(const Duration(milliseconds: 200));
                    Get.back(
                      result: true,
                    ); // ปิดหน้า DebtPaymentScreen กลับไป Ledger
                  },
                  child: const Text(
                    'ตกลง',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'รับชำระหนี้',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      // ✨ คุมฟอนต์ทั้งหน้าจอ จำกัดไม่ให้ใหญ่เกิน 1.2 เท่า
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: MediaQuery.textScalerOf(
            context,
          ).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.2),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // --- การ์ดแสดงยอดค้างชำระ ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _kCardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              debtor?.name ?? 'ไม่ระบุชื่อ',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.blueGrey,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'ยอดค้างชำระทั้งหมด',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Obx(
                              () => FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '฿ ${controller.totalDebtAmount.value.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 36,
                                    color: Colors.red.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),

                      // --- วิธีชำระเงิน ---
                      _buildPaymentMethodButtons(),
                      const SizedBox(height: 25),

                      // --- กล่องสรุปการจ่ายเงิน ---
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _kCardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Obx(
                              () => _buildPaymentDetailRow(
                                label: 'ระบุยอดที่จ่าย',
                                value: controller.amountPaid.value.toString(),
                                isInput: true,
                                textController: controller.amountPaidController,
                              ),
                            ),
                            const Divider(
                              color: Color(0xFFF1F5F9),
                              thickness: 1.5,
                              height: 20,
                            ),
                            Obx(
                              () => _buildPaymentDetailRow(
                                label: 'หนี้คงเหลือ',
                                value: controller.remainingDebt.value
                                    .toString(),
                                isRemainingDebt:
                                    controller.remainingDebt.value > 0,
                              ),
                            ),
                            Obx(
                              () => _buildPaymentDetailRow(
                                label: 'เงินทอน',
                                value: controller.change.value.toString(),
                                isChange: true,
                              ),
                            ),
                            const Divider(
                              color: Color(0xFFF1F5F9),
                              thickness: 1.5,
                              height: 20,
                            ),
                            _buildPaymentDetailRow(
                              label: 'ผู้รับเงิน',
                              value: controller.payerNameController.text,
                              isAction: true,
                              isInput: true,
                              textController: controller.payerNameController,
                            ),
                            _buildQRCodeSection(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // --- ปุ่มยืนยันด้านล่างสุด ---
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, -4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (controller.amountPaid.value <= 0) {
                          Get.snackbar(
                            'แจ้งเตือน',
                            'กรุณาระบุยอดเงินที่ชำระ',
                            backgroundColor: Colors.orange,
                            colorText: Colors.white,
                          );
                          return;
                        }
                        _showPinInputDialog();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 2,
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'ยืนยันการชำระเงิน',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // bottomNavigationBar: Obx(() => BottomNavBar(
      //   currentIndex: controller.selectedIndex.value,
      //   onTap: controller.setBottomNavIndex,
      // )),
    );
  }
}
