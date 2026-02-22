import 'package:flutter/material.dart';
import 'package:get/get.dart';

// --- Imports ไฟล์ของคุณ ---
import 'package:eazy_store/menu_bar/bottom_navbar.dart';
import '../../../model/response/debtor_response.dart';
import 'debt_payment_controller.dart'; // ★ Import Controller เข้ามา

// กำหนดสีหลัก
const Color _kPrimaryColor = Color(0xFF6B8E23);
const Color _kBackgroundColor = Color(0xFFF7F7F7);
const Color _kButtonGreen = Color(0xFF8BC34A);
const Color _kButtonBlue = Color(0xFF6495ED);
const Color _kInputFillColor = Color(0xFFF7F7F0);
const Color _kQRCodePlaceholderColor = Color(0xFFE0E0E0);

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
    return Obx(() => Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => controller.selectedMethod.value = PaymentMethod.cash,
            style: ElevatedButton.styleFrom(
              backgroundColor: controller.selectedMethod.value == PaymentMethod.cash
                  ? _kButtonGreen
                  : Colors.white,
              foregroundColor: controller.selectedMethod.value == PaymentMethod.cash
                  ? Colors.white
                  : Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
                side: BorderSide(
                  color: controller.selectedMethod.value == PaymentMethod.cash
                      ? _kButtonGreen
                      : Colors.grey.shade400,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'เงินสด',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: ElevatedButton(
            onPressed: () => controller.selectedMethod.value = PaymentMethod.transfer,
            style: ElevatedButton.styleFrom(
              backgroundColor: controller.selectedMethod.value == PaymentMethod.transfer
                  ? _kButtonBlue
                  : Colors.white,
              foregroundColor: controller.selectedMethod.value == PaymentMethod.transfer
                  ? Colors.white
                  : Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
                side: BorderSide(
                  color: controller.selectedMethod.value == PaymentMethod.transfer
                      ? _kButtonBlue
                      : Colors.grey.shade400,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'เงินโอน',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    ));
  }

  Widget _buildPaymentDetailRow({
    required String label,
    required String value,
    bool isInput = false,
    bool isAction = false,
    TextEditingController? textController,
    bool isRemainingDebt = false,
  }) {
    final Color valueColor = isAction
        ? Colors.black87
        : (isRemainingDebt
            ? Colors.red
            : Colors.black87);
    final FontWeight valueWeight =
        (label == 'เงินค้างชำระคงเหลือ' || label == 'เงินทอน')
        ? FontWeight.bold
        : FontWeight.w500;

    String displayValue = value;
    if (!isInput && double.tryParse(value) != null) {
      displayValue = double.parse(value).toStringAsFixed(2);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontSize: 18, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 2,
            child: isInput
                ? Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: _kInputFillColor,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: TextField(
                      controller: textController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: valueWeight,
                        color: valueColor,
                      ),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
                        border: InputBorder.none,
                      ),
                    ),
                  )
                : Container(
                    height: 40,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: isAction ? _kInputFillColor : _kBackgroundColor,
                      borderRadius: BorderRadius.circular(8.0),
                      border: isAction ? Border.all(color: Colors.grey.shade400) : null,
                    ),
                    child: Text(
                      displayValue,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: valueWeight,
                        color: valueColor,
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
      return Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'คิวอาร์โค้ดชำระเงิน',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFB2B2B2),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: _kQRCodePlaceholderColor,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: Colors.grey.shade400, width: 2),
            ),
            child: const Center(
              child: Icon(Icons.qr_code_2, size: 100, color: Colors.black54),
            ),
          ),
        ],
      );
    });
  }

  // --- Dialogs (เก็บเฉพาะ UI ของ Dialog ไว้ในไฟล์นี้) ---
  void _showPinInputDialog() {
    final pinController = TextEditingController();
    final FocusNode pinFocusNode = FocusNode();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        contentPadding: const EdgeInsets.all(24.0),
        title: const Text(
          'ยืนยันการชำระเงิน',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.lock_outline, color: Colors.grey, size: 40),
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
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                counterText: "",
                filled: true,
                fillColor: const Color(0xFFF0F0F0),
                hintText: '●●●●●●',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  letterSpacing: 5,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) {
                controller.validateAndSubmit(
                  pinCode: pinController.text,
                  onSuccess: () => _showSuccessDialog(),
                  onPinIncorrect: () {
                    pinController.clear();
                    Get.snackbar('ข้อผิดพลาด', 'รหัส PIN ไม่ถูกต้อง',
                        backgroundColor: Colors.redAccent, colorText: Colors.white);
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kButtonGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  controller.validateAndSubmit(
                    pinCode: pinController.text,
                    onSuccess: () => _showSuccessDialog(),
                    onPinIncorrect: () {
                      pinController.clear();
                      Get.snackbar('ข้อผิดพลาด', 'รหัส PIN ไม่ถูกต้อง',
                          backgroundColor: Colors.redAccent, colorText: Colors.white);
                    },
                  );
                },
                child: const Text(
                  'ยืนยัน',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey, fontSize: 16)),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _showSuccessDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        contentPadding: const EdgeInsets.all(24.0),
        title: const Text(
          'ชำระเงินสำเร็จ',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              decoration: const BoxDecoration(color: _kButtonGreen, shape: BoxShape.circle),
              padding: const EdgeInsets.all(15.0),
              child: const Icon(Icons.check, color: Colors.white, size: 50),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kButtonGreen,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Get.back(); // ปิดหน้าต่าง Success
                await Future.delayed(const Duration(milliseconds: 200));
                Get.back(result: true); // ปิดหน้า DebtPaymentScreen กลับไป Ledger พร้อมส่งค่า true
              },
              child: const Text(
                'ตกลง',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
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
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'ชำระเงิน',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black87),
        ),
        centerTitle: true,
        backgroundColor: _kBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  debtor?.name ?? 'ไม่ระบุชื่อ',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Obx(() => Text(
                  'ค้าง ${controller.totalDebtAmount.value.toStringAsFixed(0)} บาท',
                  style: const TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold),
                )),
              ],
            ),
            const SizedBox(height: 20),
            _buildPaymentMethodButtons(),
            const SizedBox(height: 30),
            Obx(() => _buildPaymentDetailRow(
              label: 'จ่าย',
              value: controller.amountPaid.value.toString(),
              isInput: true,
              textController: controller.amountPaidController,
            )),
            Obx(() => _buildPaymentDetailRow(
              label: 'เงินค้างชำระคงเหลือ',
              value: controller.remainingDebt.value.toString(),
              isRemainingDebt: controller.remainingDebt.value > 0,
            )),
            Obx(() => _buildPaymentDetailRow(
              label: 'เงินทอน',
              value: controller.change.value.toString(),
            )),
            Divider(color: Colors.grey.shade400, thickness: 1),
            _buildPaymentDetailRow(
              label: 'จ่ายกับ',
              value: controller.payerNameController.text,
              isAction: true,
              isInput: true,
              textController: controller.payerNameController,
            ),
            _buildQRCodeSection(),

            // ปุ่มยืนยัน
            Padding(
              padding: const EdgeInsets.only(top: 40.0, bottom: 20.0),
              child: SizedBox(
                height: 55,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (controller.amountPaid.value <= 0) {
                      Get.snackbar('แจ้งเตือน', 'กรุณาระบุยอดเงินที่ชำระ',
                          backgroundColor: Colors.redAccent, colorText: Colors.white);
                      return;
                    }
                    _showPinInputDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kButtonGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                    elevation: 5,
                  ),
                  child: const Text(
                    'ยืนยันการชำระเงิน',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Obx(() => BottomNavBar(
        currentIndex: controller.selectedIndex.value,
        onTap: controller.setBottomNavIndex,
      )),
    );
  }
}