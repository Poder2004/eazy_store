import 'package:eazy_store/menu_bar/bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

// กำหนดสีหลักที่ใช้ในแอปพลิเคชัน
const Color _kPrimaryColor = Color(0xFF6B8E23); // สีเขียวมะกอก/ทหาร
const Color _kBackgroundColor = Color(0xFFF7F7F7); // สีพื้นหลังอ่อน
const Color _kButtonGreen = Color(0xFF8BC34A); // สีเขียวสว่างสำหรับปุ่ม "เงินสด" และ "ยืนยัน"
const Color _kButtonBlue = Color(0xFF6495ED); // สีฟ้าสำหรับปุ่ม "เงินโอน"
const Color _kInputFillColor = Color(0xFFF7F7F0); // สีพื้นหลังของ Input Field
const Color _kQRCodePlaceholderColor = Color(0xFFE0E0E0); // สีพื้นหลังของ QR Code Placeholder

// --- DATA MODEL (จำลอง) ---
// ข้อมูลจำลองของลูกค้าที่กำลังจะชำระเงิน
const String _kCustomerName = 'ป้าดา';
const double _kDebtAmount = 45.00;
// รหัส PIN จำลอง (สำหรับการทดสอบ)
const String _kStorePin = '123456'; 

// ----------------------------

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Eazy Store Payment',
      theme: ThemeData(
        // fontFamily: 'AbhayaLibre',
        useMaterial3: true,
      ),
      home: const PaymentScreen(),
    );
  }
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

enum PaymentMethod { cash, transfer }

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedIndex = 3; // Index 3: คนค้างชำระ
  PaymentMethod _selectedMethod = PaymentMethod.cash;

  // Controllers และ State สำหรับการคำนวณ
  final TextEditingController _amountPaidController = TextEditingController();
  final TextEditingController _payerNameController = TextEditingController(text: 'ปอ'); // ชื่อผู้รับเงิน/พนักงาน
  double _amountPaid = 0.0;
  double _remainingDebt = _kDebtAmount;
  double _change = 0.0;

  @override
  void initState() {
    super.initState();
    // ตั้งค่าเริ่มต้นของช่อง "จ่าย" เป็นยอดค้างชำระ
    _amountPaidController.text = _kDebtAmount.toStringAsFixed(0);
    _amountPaid = _kDebtAmount;
    
    // Listener สำหรับการเปลี่ยนแปลงในช่อง 'จ่าย'
    _amountPaidController.addListener(_calculateChange);
    // ทำการคำนวณครั้งแรก
    _calculateChange();
  }

  @override
  void dispose() {
    _amountPaidController.removeListener(_calculateChange);
    _amountPaidController.dispose();
    _payerNameController.dispose();
    super.dispose();
  }

  // ⚙️ Logic: คำนวณเงินทอนและยอดค้างชำระคงเหลือ
  void _calculateChange() {
    final input = _amountPaidController.text;
    final paid = double.tryParse(input) ?? 0.0;
    
    setState(() {
      _amountPaid = paid;
      
      if (paid >= _kDebtAmount) {
        // จ่ายพอดีหรือเกิน
        _change = paid - _kDebtAmount;
        _remainingDebt = 0.0;
      } else {
        // จ่ายไม่พอ
        _change = 0.0;
        _remainingDebt = _kDebtAmount - paid;
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    print('Tab tapped: $index');
  }
  
  // 💰 Widget สำหรับปุ่มสลับ "เงินสด" / "เงินโอน"
  Widget _buildPaymentMethodButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedMethod = PaymentMethod.cash;
              });
              // เรียกคำนวณใหม่เมื่อเปลี่ยนวิธีการชำระ
              _calculateChange(); 
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedMethod == PaymentMethod.cash ? _kButtonGreen : Colors.white,
              foregroundColor: _selectedMethod == PaymentMethod.cash ? Colors.white : Colors.black87,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
                side: BorderSide(
                  color: _selectedMethod == PaymentMethod.cash ? _kButtonGreen : Colors.grey.shade400,
                  width: 1.5,
                ),
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
              setState(() {
                _selectedMethod = PaymentMethod.transfer;
              });
              // เรียกคำนวณใหม่เมื่อเปลี่ยนวิธีการชำระ
              _calculateChange(); 
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedMethod == PaymentMethod.transfer ? _kButtonBlue : Colors.white,
              foregroundColor: _selectedMethod == PaymentMethod.transfer ? Colors.white : Colors.black87,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
                side: BorderSide(
                  color: _selectedMethod == PaymentMethod.transfer ? _kButtonBlue : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('เงินโอน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // 📝 Widget สำหรับแถวแสดงข้อมูล/รับข้อมูล
  Widget _buildPaymentDetailRow({
    required String label,
    required String value,
    bool isInput = false,
    bool isAction = false,
    TextEditingController? controller,
    VoidCallback? onActionTap,
  }) {
    // กำหนดสีและสไตล์ตามประเภทของข้อมูล
    final Color valueColor = isAction ? Colors.black87 : (label == 'เงินค้างชำระคงเหลือ' && _remainingDebt > 0 ? Colors.red : Colors.black87);
    final FontWeight valueWeight = (label == 'เงินค้างชำระคงเหลือ' || label == 'เงินทอน') ? FontWeight.bold : FontWeight.w500;
    
    // ฟอร์แมตจำนวนเงิน (ถ้าเป็นตัวเลข)
    String displayValue = value;
    if (double.tryParse(value) != null) {
      displayValue = double.parse(value).toStringAsFixed(2);
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          // Label (ซ้าย)
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
          ),
          
          // Value/Input (ขวา)
          Expanded(
            flex: 2,
            child: isInput
                ? Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: _kInputFillColor,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.grey.shade400, width: 1),
                    ),
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 18, fontWeight: valueWeight, color: valueColor),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
                        border: InputBorder.none,
                      ),
                      onChanged: (text) => _calculateChange(),
                    ),
                  )
                : Container(
                    height: 40,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: isAction ? _kInputFillColor : _kBackgroundColor, // ใช้สีพื้นหลัง
                      borderRadius: BorderRadius.circular(8.0),
                      border: isAction ? Border.all(color: Colors.grey.shade400, width: 1) : null,
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

  // 📲 Widget สำหรับแสดง QR Code (แสดงเมื่อเลือก "เงินโอน")
  Widget _buildQRCodeSection() {
    // จะแสดงเฉพาะเมื่อเลือก PaymentMethod.transfer เท่านั้น
    if (_selectedMethod != PaymentMethod.transfer) {
      return const SizedBox.shrink(); // ซ่อน Widget ถ้าไม่ใช่เงินโอน
    }

    // กำหนด crossAxisAlignment: CrossAxisAlignment.start เพื่อให้ Text ชิดซ้าย
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // ให้ Text ชิดซ้าย
      children: [
        const SizedBox(height: 20),
        
        // Text ชิดซ้ายโดยธรรมชาติ
        const Text(
          'คิวอาร์โค้ดชำระเงิน',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFFB2B2B2), // สีตามที่ร้องขอ
          ),
        ),
        
        const SizedBox(height: 10),
        
        // QR Code Placeholder ต้องถูกห่อด้วย Center เพื่อให้มันอยู่ตรงกลาง
        Center( 
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: _kQRCodePlaceholderColor,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: Colors.grey.shade400, width: 2),
            ),
            child: const Center(
              child: Icon(
                Icons.qr_code_2, // ใช้ Icon เป็น Placeholder
                size: 100,
                color: Colors.black54,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 🔐 ฟังก์ชันแสดง Dialog ป้อนรหัส PIN
  Future<void> _showPinInputDialog(BuildContext context) async {
    // ใช้ Get.dialog แทน showDialog เพื่อให้จัดการ Navigation ได้ง่ายขึ้น (ถ้าใช้ GetX)
    // หรือใช้ showDialog ปกติก็ได้
    final pinController = TextEditingController();
    
    await showDialog(
      context: context,
      barrierDismissible: false, // ห้ามปิดโดยการแตะนอก Dialog
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          contentPadding: const EdgeInsets.all(24.0),
          title: const Text(
            'กรุณากรอกรหัสร้านเพื่อยืนยัน',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.lock_open, color: Colors.grey, size: 40),
              const SizedBox(height: 15),
              // ใช้ TextField สำหรับ Pin Input (จำลองเป็นรหัสผ่าน)
              TextField(
                controller: pinController,
                obscureText: true,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: const TextStyle(letterSpacing: 10, fontSize: 24),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                ),
                maxLength: _kStorePin.length,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kButtonGreen,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  // Logic ตรวจสอบ PIN
                  if (pinController.text == _kStorePin) {
                    Navigator.of(context).pop(); // ปิด Pin Dialog
                    _showSuccessDialog(context); // แสดง Dialog สำเร็จ
                  } else {
                    // หาก Pin ไม่ถูกต้อง อาจจะแสดงข้อความเตือนสั้นๆ
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('รหัสไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง')),
                    );
                  }
                },
                child: const Text(
                  'ยืนยัน',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // ยกเลิกและปิด Dialog
                },
                child: const Text('ยกเลิก', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ ฟังก์ชันแสดง Dialog การชำระเงินสำเร็จ
  Future<void> _showSuccessDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false, // ห้ามปิดโดยการแตะนอก Dialog
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          contentPadding: const EdgeInsets.all(24.0),
          title: const Text(
            'ชำระเงินสำเร็จ',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Icon เครื่องหมายถูกขนาดใหญ่
              Container(
                decoration: BoxDecoration(
                  color: _kButtonGreen,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(15.0),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kButtonGreen,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // ปิด Dialog
                  // ** เพิ่ม Logic หลังจากชำระเงินสำเร็จที่นี่ **
                  // เช่น: อัปเดตยอดค้างชำระใน Firestore และนำทางผู้ใช้กลับไปหน้า DebtLedgerScreen
                  print('Transaction recorded and confirmed.');
                  // Navigator.pop(context); // นำทางกลับ
                },
                child: const Text(
                  'ตกลง',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 💾 Widget สำหรับปุ่ม ยืนยันการชำระเงิน
  Widget _buildConfirmButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 40.0, bottom: 20.0),
      child: SizedBox(
        height: 55,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            // เรียก Dialog ป้อน PIN ก่อนยืนยันการชำระเงิน
            _showPinInputDialog(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _kButtonGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 5,
          ),
          child: const Text(
            'ยืนยันการชำระเงิน',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      // AppBar สำหรับหัวข้อ "ชำระเงิน"
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ชำระเงิน',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: _kBackgroundColor,
        elevation: 0,
      ),
      
      // Body ส่วนเนื้อหา
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: ชื่อลูกค้าและยอดค้าง
            Row(
              children: [
                Text(
                  _kCustomerName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(
                  'ค้าง ${_kDebtAmount.toStringAsFixed(0)} บาท',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ปุ่ม เงินสด / เงินโอน
            _buildPaymentMethodButtons(),
            const SizedBox(height: 30),

            // รายละเอียดการชำระเงิน
            _buildPaymentDetailRow(
              label: 'จ่าย',
              value: _amountPaid.toString(),
              isInput: true,
              controller: _amountPaidController,
            ),
            
            _buildPaymentDetailRow(
              label: 'เงินค้างชำระคงเหลือ',
              value: _remainingDebt.toString(),
              isInput: false,
            ),
            
            _buildPaymentDetailRow(
              label: 'เงินทอน',
              value: _change.toString(),
              isInput: false,
            ),
            
            Divider(color: Colors.grey.shade400, thickness: 1),
            
            _buildPaymentDetailRow(
              label: 'จ่ายกับ',
              value: _payerNameController.text,
              isAction: true,
              isInput: true, // ใช้ input field สำหรับจ่ายกับ
              controller: _payerNameController,
            ),
            
            // ส่วน QR Code ที่ถูกจัดให้อยู่ตรงกลางแล้ว แต่หัวข้อชิดซ้าย
            _buildQRCodeSection(),

            // ปุ่มยืนยัน (เรียก Dialog)
            _buildConfirmButton(),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}