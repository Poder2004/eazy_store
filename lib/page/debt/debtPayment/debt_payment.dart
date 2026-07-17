import 'package:flutter/material.dart';
import 'package:get/get.dart';

// --- Imports ไฟล์ของคุณ ---
import '../../../model/response/debtor_response.dart';
import 'debt_payment_controller.dart'; // ★ Import Controller เข้ามา

// ─── Design Tokens ────────────────────────────────────────────────────────────
const Color _kBg = Color(0xFFF3F5F9);
const Color _kSurface = Colors.white;
const Color _kFill = Color(0xFFF8FAFC);
const Color _kBorder = Color(0xFFE7EAF2);

const Color _kInk = Color(0xFF14213D);
const Color _kInk2 = Color(0xFF6B7A99);
const Color _kInk3 = Color(0xFF9AA4BF);

const Color _kGreen = Color(0xFF10B981);
const Color _kGreenBg = Color(0xFFE7FBF4);
const Color _kGreenBorder = Color(0xFFA7F0D6);

const Color _kBlue = Color(0xFF3B82F6);
const Color _kBlueBg = Color(0xFFEAF2FF);
const Color _kBlueBorder = Color(0xFFBFDBFE);

const Color _kRed = Color(0xFFEF4444);
const Color _kRedBg = Color(0xFFFEECEC);

const double _kR12 = 12.0;
const double _kR16 = 16.0;
const double _kR20 = 20.0;

class DebtPaymentScreen extends StatelessWidget {
  final DebtorResponse? debtor;

  // เรียกใช้งาน Controller
  final DebtPaymentController controller = Get.put(DebtPaymentController());

  DebtPaymentScreen({super.key, this.debtor}) {
    // จ่ายข้อมูลเริ่มต้นให้ Controller ทันทีที่เปิดหน้า
    controller.initData(debtor);
  }

  // ─── การ์ดข้อมูลลูกหนี้ ─────────────────────────────────────────────────────
  Widget _buildDebtorCard() {
    final name = debtor?.name ?? 'ไม่ระบุชื่อ';
    final img = debtor?.imgDebtor ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(_kR20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: _kBlueBg,
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: img.isNotEmpty
                    ? Image.network(
                        img,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _avatarInitial(name),
                      )
                    : _avatarInitial(name),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kInk,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _kFill,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ลูกหนี้',
                        style: TextStyle(fontSize: 11, color: _kInk2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: _kBorder),
          const SizedBox(height: 14),
          const Text(
            'ยอดค้างชำระทั้งหมด',
            style: TextStyle(fontSize: 13, color: _kInk2),
          ),
          const SizedBox(height: 4),
          Obx(
            () => FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '฿ ${controller.totalDebtAmount.value.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 32,
                  color: _kRed,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarInitial(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name.characters.first : '?',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: _kBlue,
        ),
      ),
    );
  }

  // ─── ปุ่มเลือกวิธีชำระ ──────────────────────────────────────────────────────
  Widget _buildPaymentMethodButtons() {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: _methodButton(
              selected: controller.selectedMethod.value == PaymentMethod.cash,
              icon: Icons.payments_rounded,
              label: 'เงินสด',
              accent: _kGreen,
              accentBg: _kGreenBg,
              accentBorder: _kGreenBorder,
              onTap: () => controller.selectedMethod.value = PaymentMethod.cash,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _methodButton(
              selected:
                  controller.selectedMethod.value == PaymentMethod.transfer,
              icon: Icons.qr_code_scanner_rounded,
              label: 'เงินโอน',
              accent: _kBlue,
              accentBg: _kBlueBg,
              accentBorder: _kBlueBorder,
              onTap: () =>
                  controller.selectedMethod.value = PaymentMethod.transfer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodButton({
    required bool selected,
    required IconData icon,
    required String label,
    required Color accent,
    required Color accentBg,
    required Color accentBorder,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? accentBg : _kSurface,
          borderRadius: BorderRadius.circular(_kR12),
          border: Border.all(
            color: selected ? accentBorder : _kBorder,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: selected ? accent : _kInk3),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: selected ? accent : _kInk2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: selected
                  ? Padding(
                      key: const ValueKey('checked'),
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 17,
                        color: accent,
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('unchecked')),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ช่องกรอกยอดที่จ่าย (hero input) ───────────────────────────────────────
  Widget _buildAmountInput() {
    return Obx(() {
      final isCash = controller.selectedMethod.value == PaymentMethod.cash;
      final accent = isCash ? _kGreen : _kBlue;
      final accentBg = isCash ? _kGreenBg : _kBlueBg;
      final accentBorder = isCash ? _kGreenBorder : _kBlueBorder;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ระบุยอดที่ต้องการรับชำระ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kInk2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: accentBg,
              borderRadius: BorderRadius.circular(_kR16),
              border: Border.all(color: accentBorder, width: 1.5),
            ),
            child: Row(
              children: [
                Text(
                  '฿',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller.amountPaidController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: _kInk,
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      hintText: '0',
                      hintStyle: const TextStyle(
                        color: _kInk3,
                        fontWeight: FontWeight.w800,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  // ─── การ์ดสรุป: หนี้คงเหลือ / เงินทอน ───────────────────────────────────────
  Widget _buildSummaryChips() {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: _statChip(
              icon: Icons.account_balance_wallet_rounded,
              label: 'หนี้คงเหลือ',
              value: controller.remainingDebt.value,
              color: _kRed,
              bg: _kRedBg,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statChip(
              icon: Icons.savings_rounded,
              label: 'เงินทอน',
              value: controller.change.value,
              color: _kGreen,
              bg: _kGreenBg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip({
    required IconData icon,
    required String label,
    required double value,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(_kR12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '฿ ${value.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ช่องชื่อผู้รับเงิน ─────────────────────────────────────────────────────
  Widget _buildPayerNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ผู้รับเงิน',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kInk2,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller.payerNameController,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _kInk,
          ),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.person_outline_rounded,
              size: 20,
              color: _kInk3,
            ),
            filled: true,
            fillColor: _kFill,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kR12),
              borderSide: BorderSide(color: _kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kR12),
              borderSide: BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kR12),
              borderSide: const BorderSide(color: _kBlue, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQRCodeSection() {
    return Obx(() {
      if (controller.selectedMethod.value != PaymentMethod.transfer) {
        return const SizedBox.shrink();
      }
      final qrUrl = controller.shopQrCodeUrl.value;
      return Padding(
        padding: const EdgeInsets.only(top: 18.0),
        child: Column(
          children: [
            Container(height: 1, color: _kBorder),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.qr_code_2_rounded, size: 16, color: _kBlue),
                SizedBox(width: 6),
                Text(
                  'สแกนเพื่อชำระผ่าน QR',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kInk,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: 180,
              height: 180,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_kR16),
                border: Border.all(color: _kBlueBorder),
                boxShadow: [
                  BoxShadow(
                    color: _kBlue.withValues(alpha: .08),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: _kFill,
                  borderRadius: BorderRadius.circular(_kR12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_kR12),
                  child: qrUrl.isNotEmpty
                      ? Image.network(
                          qrUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image_rounded,
                                size: 50,
                                color: _kInk3,
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Icon(
                            Icons.qr_code_2,
                            size: 80,
                            color: _kInk3,
                          ),
                        ),
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
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      disabledBackgroundColor: _kGreen.withValues(alpha: .6),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: controller.isSubmitting.value
                        ? null
                        : () {
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
                    child: controller.isSubmitting.value
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const FittedBox(
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
              ),
              const SizedBox(height: 8),
              Obx(
                () => TextButton(
                  onPressed: controller.isSubmitting.value
                      ? null
                      : () => Get.back(),
                  child: const Text(
                    'ยกเลิก',
                    style: TextStyle(color: Colors.blueGrey, fontSize: 16),
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
                  color: _kGreen.withValues(alpha: .1),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(20.0),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: _kGreen,
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
                    backgroundColor: _kGreen,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refreshShopData(); // ✅ ดึงรูป QR Code ใหม่ทุกครั้งที่เปิดหน้า
    });
    return Scaffold(
      backgroundColor: _kBg,
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
            color: _kInk,
          ),
        ),
        centerTitle: true,
        backgroundColor: _kSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kInk),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
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
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  child: Column(
                    children: [
                      _buildDebtorCard(),
                      const SizedBox(height: 16),
                      _buildPaymentMethodButtons(),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _kSurface,
                          borderRadius: BorderRadius.circular(_kR20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .04),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildAmountInput(),
                            const SizedBox(height: 14),
                            _buildSummaryChips(),
                            const SizedBox(height: 18),
                            _buildPayerNameField(),
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
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                decoration: BoxDecoration(
                  color: _kSurface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .05),
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
                        backgroundColor: _kGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_kR12),
                        ),
                        elevation: 3,
                        shadowColor: _kGreen.withValues(alpha: .4),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'ยืนยันการชำระเงิน',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
    );
  }
}
