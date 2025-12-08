import 'package:eazy_store/menu_bar/bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

// กำหนดสีหลักที่ใช้ในแอปพลิเคชัน
const Color _kPrimaryColor = Color(0xFF6B8E23); // สีเขียวมะกอก/ทหาร
const Color _kBackgroundColor = Color(0xFFF7F7F7); // สีพื้นหลังอ่อน
const Color _kInputFillColor = Color(0xFFF0F0E0); // สีพื้นหลังของ Input/Card และ Barcode Input

class AddStockScreen extends StatefulWidget {
  const AddStockScreen({super.key});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  // State สำหรับจัดการ Bottom Navigation Bar
  int _selectedIndex = 0; 

  // Controllers สำหรับ TextField
  final TextEditingController _idController = TextEditingController(text: 'B120356');
  final TextEditingController _nameController = TextEditingController(text: 'สบู่นกแก้วสีชมพู');
  final TextEditingController _costController = TextEditingController(text: '13');
  final TextEditingController _salePriceController = TextEditingController(text: '15');
  final TextEditingController _stockController = TextEditingController(text: '50');
  final TextEditingController _unitController = TextEditingController(text: 'ก้อน');
  final TextEditingController _categoryController = TextEditingController(text: 'ผลิตภัณฑ์ทำความสะอาด');

  // Function สำหรับเปลี่ยน Tab ใน Bottom Navigation Bar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    print('Tab tapped: $index');
  }

  // 🖼️ Widget สำหรับ input field ทั่วไป (มี Label ด้านบน)
  // ใช้สำหรับ ชื่อ, ราคา, จำนวน, หน่วยนับ, หมวดหมู่
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    // ใช้ OutlineInputBorder สำหรับ Field ทั่วไป
    final borderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: const BorderSide(
        color: Color(0xFFE0E0C0),
        width: 1.5,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          style: TextStyle(
            color: readOnly ? Colors.grey[700] : Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10.0,
              horizontal: 12.0,
            ),
            filled: true,
            fillColor: _kInputFillColor, // สีพื้นหลังของ input
            border: borderStyle,
            enabledBorder: borderStyle,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: _kPrimaryColor, width: 2.0),
            ),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  // 🔍 Widget สำหรับช่องกรอกรหัสสินค้า (มี Label ด้านบน และสไตล์เหมือน Search Input)
  // ใช้สำหรับ รหัสสินค้า ตามที่ลูกค้าร้องขอ
  Widget _buildBarcodeInputField({
    required String label,
    required TextEditingController controller,
    String hintText = 'กรอกหรือสแกนรหัสสินค้า', // เพิ่ม hint text
    required void Function()? onBarcodeScan, // ฟังก์ชันสำหรับกดไอคอนสแกน
    TextInputType keyboardType = TextInputType.text,
  }) {
    const Color _kInputBorderColor = Color(0xFFE0E0C0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _kInputFillColor, // ใช้สีพื้นหลัง Input
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: _kInputBorderColor, width: 1.5),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 12.0,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.qr_code_scanner_outlined,
                  color: Colors.grey[700],
                ),
                onPressed: onBarcodeScan, // เชื่อมต่อฟังก์ชันสแกน
              ),
              filled: true,
              fillColor: Colors.transparent, // ใช้สีจาก Container แทน
              border: InputBorder.none, // ลบ border ของ TextField ออก
              enabledBorder: InputBorder.none,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(color: _kPrimaryColor, width: 2.0),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 🖼️ Widget สำหรับแสดงรหัสสินค้าพร้อมรูปสินค้า
  Widget _buildProductHeader() {
    return Column(
      children: [
        // 1. รหัสสินค้า (ใช้ _buildBarcodeInputField ที่ปรับสไตล์แล้ว)
        _buildBarcodeInputField(
          label: 'รหัสสินค้า',
          controller: _idController,
          hintText: 'สแกนหรือกรอกรหัสสินค้า',
          onBarcodeScan: () {
            print('Scanning barcode...');
            // Logic สำหรับการสแกนบาร์โค้ด
          },
        ),

        const SizedBox(height: 15),

        // 2. รูปสินค้าที่ดึงมา
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F0), // สีพื้นหลังอ่อน
              borderRadius: BorderRadius.circular(15.0),
              border: Border.all(
                color: const Color(0xFFE0E0C0),
                style: BorderStyle.solid,
                width: 2.0,
              ),
              // แสดงรูปสินค้า (ใช้ Asset จำลองจากรูป)
              // ⚠️ ต้องเพิ่ม Path นี้ใน pubspec.yaml และมีไฟล์รูปภาพจริง
              image: const DecorationImage(
                image: AssetImage('assets/image/soap_image.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  // 🖼️ Widget สำหรับปุ่ม "บันทึกสินค้า"
  Widget _buildSaveButton() {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        onPressed: () {
          // Logic สำหรับการบันทึกสต็อกสินค้า
          print('Saving stock for product: ${_idController.text}');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7B68EE), // สีม่วงเข้มตามรูป
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: 5,
          padding: const EdgeInsets.symmetric(horizontal: 0),
        ),
        child: const Text(
          'บันทึกสินค้า',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // 🖼️ Widget สำหรับปุ่ม "ยกเลิก"
  Widget _buildCancelButton() {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        onPressed: () {
          // Logic สำหรับการยกเลิก/กลับไปหน้าเดิม
          print('Cancel pressed.');
          // Navigator.pop(context); // ใช้สำหรับกลับหน้าเดิม
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE0E0E0), // สีเทาอ่อน
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: 5,
          padding: const EdgeInsets.symmetric(horizontal: 0),
        ),
        child: const Text(
          'ยกเลิก',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF808080), // สีเทาเข้ม
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      // AppBar สำหรับหัวข้อ "เพิ่มสต็อกสินค้า"
      appBar: AppBar(
        title: const Text(
          'เพิ่มสต็อกสินค้า',
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
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ส่วนรหัสสินค้าและรูปภาพ
            _buildProductHeader(),

            // 2. ชื่อสินค้า (อ่านอย่างเดียว)
            _buildInputField(
              label: 'ชื่อสินค้า',
              controller: _nameController,
              readOnly: true,
            ),
            const SizedBox(height: 20),

            // 3. ราคาต้นทุน และ ราคาขาย (อ่านอย่างเดียว)
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    label: 'ราคาต้นทุน',
                    controller: _costController,
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildInputField(
                    label: 'ราคาขาย',
                    controller: _salePriceController,
                    readOnly: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 4. จำนวนสินค้า (แก้ไขได้) และ หน่วยนับสินค้า (อ่านอย่างเดียว)
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    label: 'จำนวนสินค้า',
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildInputField(
                    label: 'หน่วยนับสินค้า',
                    controller: _unitController,
                    readOnly: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 5. หมวดหมู่สินค้า (อ่านอย่างเดียว)
            _buildInputField(
              label: 'หมวดหมู่สินค้า',
              controller: _categoryController,
              readOnly: true,
            ),
            const SizedBox(height: 40),

            // 6. ปุ่ม บันทึกสินค้า และ ยกเลิก
            Row(
              children: [
                Expanded(child: _buildSaveButton()),
                const SizedBox(width: 15),
                Expanded(child: _buildCancelButton()),
              ],
            ),
            const SizedBox(height: 10),
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