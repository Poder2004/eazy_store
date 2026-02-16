import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Imports ไฟล์ของคุณ ---
import 'package:eazy_store/menu_bar/bottom_navbar.dart';
import 'package:eazy_store/api/api_payment.dart'; // ★ Import ไฟล์ API
import 'package:eazy_store/model/request/pay_debt_request.dart'; // ★ Import Model Request
import '../model/response/debtor_response.dart';

// กำหนดสีหลัก
const Color _kPrimaryColor = Color(0xFF6B8E23);
const Color _kBackgroundColor = Color(0xFFF7F7F7);
const Color _kButtonGreen = Color(0xFF8BC34A);
const Color _kButtonBlue = Color(0xFF6495ED);
const Color _kInputFillColor = Color(0xFFF7F7F0);
const Color _kQRCodePlaceholderColor = Color(0xFFE0E0E0);

class DebtPaymentScreen extends StatefulWidget {
  final DebtorResponse? debtor;

  const DebtPaymentScreen({super.key, this.debtor});

  @override
  State<DebtPaymentScreen> createState() => _DebtPaymentScreenState();
}

enum PaymentMethod { cash, transfer }

class _DebtPaymentScreenState extends State<DebtPaymentScreen> {
  int _selectedIndex = 3;
  PaymentMethod _selectedMethod = PaymentMethod.cash;

  final TextEditingController _amountPaidController = TextEditingController();
  final TextEditingController _payerNameController = TextEditingController(text: 'เจ้าของร้าน');

  late double _totalDebtAmount;
  double _amountPaid = 0.0;
  double _remainingDebt = 0.0;
  double _change = 0.0;

  @override
  void initState() {
    super.initState();
    // แปลงหนี้จาก String เป็น Double (จัดการกรณีเป็น null หรือ format ผิด)
    _totalDebtAmount = (widget.debtor?.currentDebt as num?)?.toDouble() ?? 0.0;
    
    // Default หนี้ที่ต้องจ่ายเท่ากับยอดหนี้ทั้งหมด
    _remainingDebt = _totalDebtAmount; 
    _amountPaidController.text = _totalDebtAmount.toStringAsFixed(0); // ใส่ค่ายอดหนี้ให้อัตโนมัติ (Option)
    _amountPaid = _totalDebtAmount;

    _amountPaidController.addListener(_calculateChange);
  }

  @override
  void dispose() {
    _amountPaidController.removeListener(_calculateChange);
    _amountPaidController.dispose();
    _payerNameController.dispose();
    super.dispose();
  }

  void _calculateChange() {
    final input = _amountPaidController.text;
    final paid = double.tryParse(input) ?? 0.0;

    setState(() {
      _amountPaid = paid;
      if (paid >= _totalDebtAmount) {
        _change = paid - _totalDebtAmount;
        _remainingDebt = 0.0;
      } else {
        _change = 0.0;
        _remainingDebt = _totalDebtAmount - paid;
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // --- Widgets UI ---
  Widget _buildPaymentMethodButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() => _selectedMethod = PaymentMethod.cash);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedMethod == PaymentMethod.cash ? _kButtonGreen : Colors.white,
              foregroundColor: _selectedMethod == PaymentMethod.cash ? Colors.white : Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
                side: BorderSide(color: _selectedMethod == PaymentMethod.cash ? _kButtonGreen : Colors.grey.shade400),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('เงินสด', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() => _selectedMethod = PaymentMethod.transfer);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedMethod == PaymentMethod.transfer ? _kButtonBlue : Colors.white,
              foregroundColor: _selectedMethod == PaymentMethod.transfer ? Colors.white : Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
                side: BorderSide(color: _selectedMethod == PaymentMethod.transfer ? _kButtonBlue : Colors.grey.shade400),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('เงินโอน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDetailRow({required String label, required String value, bool isInput = false, bool isAction = false, TextEditingController? controller}) {
    final Color valueColor = isAction ? Colors.black87 : (label == 'เงินค้างชำระคงเหลือ' && _remainingDebt > 0 ? Colors.red : Colors.black87);
    final FontWeight valueWeight = (label == 'เงินค้างชำระคงเหลือ' || label == 'เงินทอน') ? FontWeight.bold : FontWeight.w500;
    
    String displayValue = value;
    if (!isInput && double.tryParse(value) != null) {
      displayValue = double.parse(value).toStringAsFixed(2);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: const TextStyle(fontSize: 18, color: Colors.black87))),
          Expanded(
            flex: 2,
            child: isInput
                ? Container(
                    height: 40,
                    decoration: BoxDecoration(color: _kInputFillColor, borderRadius: BorderRadius.circular(8.0), border: Border.all(color: Colors.grey.shade400)),
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 18, fontWeight: valueWeight, color: valueColor),
                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8.0), border: InputBorder.none),
                      onChanged: (text) => _calculateChange(),
                    ),
                  )
                : Container(
                    height: 40,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(color: isAction ? _kInputFillColor : _kBackgroundColor, borderRadius: BorderRadius.circular(8.0), border: isAction ? Border.all(color: Colors.grey.shade400) : null),
                    child: Text(displayValue, style: TextStyle(fontSize: 18, fontWeight: valueWeight, color: valueColor)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection() {
    if (_selectedMethod != PaymentMethod.transfer) return const SizedBox.shrink();
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text('คิวอาร์โค้ดชำระเงิน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFB2B2B2))),
        const SizedBox(height: 10),
        Container(
          width: 150, height: 150,
          decoration: BoxDecoration(color: _kQRCodePlaceholderColor, borderRadius: BorderRadius.circular(10.0), border: Border.all(color: Colors.grey.shade400, width: 2)),
          child: const Center(child: Icon(Icons.qr_code_2, size: 100, color: Colors.black54)),
        ),
      ],
    );
  }

  // --- Dialog & Logic ---

  Future<void> _showPinInputDialog(BuildContext context) async {
    final pinController = TextEditingController();
    final FocusNode pinFocusNode = FocusNode();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Auto focus
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if (pinController.text.isEmpty) FocusScope.of(context).requestFocus(pinFocusNode);
        });

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          contentPadding: const EdgeInsets.all(24.0),
          title: const Text('ยืนยันการชำระเงิน', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.lock_outline, color: Colors.grey, size: 40),
              const SizedBox(height: 20),
              TextField(
                controller: pinController,
                focusNode: pinFocusNode,
                obscureText: true,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 8),
                decoration: InputDecoration(
                  counterText: "", filled: true, fillColor: const Color(0xFFF0F0F0),
                  hintText: '●●●●●●', hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide.none),
                ),
                onSubmitted: (_) => _validateAndSubmit(context, pinController),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _kButtonGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () => _validateAndSubmit(context, pinController),
                  child: const Text('ยืนยัน', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ★ ฟังก์ชันหลัก: เช็ค PIN -> สร้าง Model -> เรียก API
  Future<void> _validateAndSubmit(BuildContext context, TextEditingController pinController) async {
    // 1. ตรวจสอบ PIN กับ SharedPreferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String savedPin = prefs.getString('pinCode') ?? ''; 
    final int shopId = prefs.getInt('shopId') ?? 0;

    if (savedPin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่พบรหัส PIN กรุณา Login ใหม่')));
      return;
    }

    if (pinController.text == savedPin) {
      // ✅ PIN ถูกต้อง
      Navigator.of(context).pop(); // ปิด Dialog PIN

      // แสดง Loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // 2. สร้าง Model Request
        final request = PayDebtRequest(
          shopId: shopId,
          debtorId: widget.debtor?.debtorId ?? 0, // ดึง ID ลูกหนี้
          amountPaid: _amountPaid,
          paymentMethod: _selectedMethod == PaymentMethod.cash ? 'จ่ายเงินสด' : 'โอนจ่าย',
          payWith: _payerNameController.text, // เอามาจากช่อง "จ่ายกับ"
          pinCode: pinController.text,        // เอามาจากรหัสที่เพิ่งกรอก
        );

        // 3. เรียก API ที่คุณเตรียมไว้
        final result = await ApiPayment.payDebt(request);

        // ปิด Loading
        Navigator.of(context).pop();

        // 4. ตรวจสอบผลลัพธ์
        if (result.containsKey('error')) {
          // ❌ มี Error จาก Server
          _showErrorSnackBar(context, result['error']);
        } else {
          // ✅ สำเร็จ
          _showSuccessDialog(context);
        }

      } catch (e) {
        // ❌ Error การเชื่อมต่อ
        Navigator.of(context).pop(); // ปิด Loading
        _showErrorSnackBar(context, 'เกิดข้อผิดพลาด: $e');
      }

    } else {
      // ❌ PIN ผิด
      pinController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('รหัสไม่ถูกต้อง'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
      );
      FocusScope.of(context).requestFocus();
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _showSuccessDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          contentPadding: const EdgeInsets.all(24.0),
          title: const Text('ชำระเงินสำเร็จ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                style: ElevatedButton.styleFrom(backgroundColor: _kButtonGreen, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () {
                  Navigator.of(context).pop(); // ปิด Dialog
                  Get.back(result: true); // กลับไปหน้า DebtLedger และรีเฟรช
                },
                child: const Text('ตกลง', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text('ชำระเงิน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black87)),
        centerTitle: true, backgroundColor: _kBackgroundColor, elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
        child: Column(
          children: [
            Row(
              children: [
                Text(widget.debtor?.name ?? 'ไม่ระบุชื่อ', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('ค้าง ${_totalDebtAmount.toStringAsFixed(0)} บาท', style: const TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            _buildPaymentMethodButtons(),
            const SizedBox(height: 30),
            _buildPaymentDetailRow(label: 'จ่าย', value: _amountPaid.toString(), isInput: true, controller: _amountPaidController),
            _buildPaymentDetailRow(label: 'เงินค้างชำระคงเหลือ', value: _remainingDebt.toString()),
            _buildPaymentDetailRow(label: 'เงินทอน', value: _change.toString()),
            Divider(color: Colors.grey.shade400, thickness: 1),
            _buildPaymentDetailRow(label: 'จ่ายกับ', value: _payerNameController.text, isAction: true, isInput: true, controller: _payerNameController),
            _buildQRCodeSection(),
            
            // ปุ่มยืนยัน
            Padding(
              padding: const EdgeInsets.only(top: 40.0, bottom: 20.0),
              child: SizedBox(
                height: 55, width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                     if (_amountPaid <= 0) {
                       _showErrorSnackBar(context, 'กรุณาระบุยอดเงินที่ชำระ');
                       return;
                     }
                     _showPinInputDialog(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _kButtonGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)), elevation: 5),
                  child: const Text('ยืนยันการชำระเงิน', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: _selectedIndex, onTap: _onItemTapped),
    );
  }
}