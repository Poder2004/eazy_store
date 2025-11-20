import 'package:eazy_store/menu_bar/bottom_navbar.dart';
import 'package:flutter/material.dart';


// กำหนดสีหลักที่ใช้ในแอปพลิเคชัน (อ้างอิงจากรูปภาพ)
const Color _kPrimaryColor = Color(0xFF6B8E23); // สีเขียวมะกอก/ทหาร
const Color _kBackgroundColor = Color(0xFFF7F7F7); // สีพื้นหลังอ่อน

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  // State สำหรับจัดการ Bottom Navigation Bar
  int _selectedIndex = 0; // เริ่มต้นที่ 'หน้าหลัก' (Index 0)

  // Controllers สำหรับ TextField
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _salePriceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _idController = TextEditingController();

  // ตัวแปรสำหรับ Dropdown
  String? _selectedCategory;
  final List<String> _categories = ['เครื่องดื่ม', 'ขนมขบเคี้ยว', 'อาหารสด', 'อื่น ๆ'];

  // Function สำหรับเปลี่ยน Tab ใน Bottom Navigation Bar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // ในแอปจริง คุณจะเพิ่ม Logic สำหรับเปลี่ยนหน้าจอที่นี่
    print('Tab tapped: $index');
  }

  // Widget สำหรับ input field ที่มีสไตล์คล้ายในรูปภาพ
  Widget _buildInputField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
            filled: true,
            fillColor: const Color(0xFFF0F0E0), // สีพื้นหลังของ input
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Color(0xFFE0E0C0), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Color(0xFFE0E0C0), width: 1.5),
            ),
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

  // Widget สำหรับ Dropdown field
  Widget _buildDropdownField({
    required String label,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0E0),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: const Color(0xFFE0E0C0), width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedCategory,
              hint: Text(
                hintText,
                style: const TextStyle(color: Colors.grey),
              ),
              icon: const Icon(Icons.arrow_drop_down),
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              items: _categories.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  // Widget สำหรับกล่องเพิ่มรูปภาพ
  Widget _buildImagePicker() {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F0), // สีพื้นหลังอ่อน
          borderRadius: BorderRadius.circular(15.0),
          border: Border.all(
            color: const Color(0xFFE0E0C0), // สีขอบอ่อน
            style: BorderStyle.solid,
            width: 2.0,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 40,
              color: Colors.grey,
            ),
            SizedBox(height: 5),
            Text(
              'แตะเพื่อเพิ่ม\nรูปสินค้า',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Widget สำหรับปุ่ม "เพิ่มสินค้า"
  Widget _buildAddProductButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: () {
          // Logic สำหรับการเพิ่มสินค้า
          print('Adding product...');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: 5,
        ),
        icon: const Icon(
          Icons.add,
          color: Colors.white,
          size: 24,
        ),
        label: const Text(
          'เพิ่มสินค้า',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Widget สำหรับข้อความ "รีเซ็ตข้อมูล"
  Widget _buildResetText() {
    return Center(
      child: GestureDetector(
        onTap: () {
          // Logic สำหรับการรีเซ็ตข้อมูล
          setState(() {
            _nameController.clear();
            _costController.clear();
            _salePriceController.clear();
            _stockController.clear();
            _unitController.clear();
            _idController.clear();
            _selectedCategory = null;
          });
          print('Resetting data...');
        },
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh, size: 16, color: Colors.grey),
            SizedBox(width: 5),
            Text(
              'รีเซ็ตข้อมูล',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      // AppBar สำหรับหัวข้อ "เพิ่มสินค้า"
      appBar: AppBar(
        title: const Text(
          'เพิ่มสินค้า',
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
            // 1. ส่วนสำหรับเพิ่มรูปภาพ
            _buildImagePicker(),
            const SizedBox(height: 20),

            // 2. ชื่อสินค้า
            _buildInputField(
              label: 'ชื่อสินค้า',
              hintText: 'ชื่อสินค้า',
              controller: _nameController,
            ),
            const SizedBox(height: 20),

            // 3. ราคาต้นทุน และ ราคาขาย
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    label: 'ราคาต้นทุน',
                    hintText: 'ราคาต้นทุน',
                    controller: _costController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildInputField(
                    label: 'ราคาขาย',
                    hintText: 'ราคาขาย',
                    controller: _salePriceController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 4. จำนวนสินค้า และ หน่วยนับสินค้า
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    label: 'จำนวนสินค้า',
                    hintText: 'จำนวนในสต็อก',
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildInputField(
                    label: 'หน่วยนับสินค้า',
                    hintText: 'เช่น ชิ้น, กล่อง',
                    controller: _unitController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 5. หมวดหมู่สินค้า
            _buildDropdownField(
              label: 'หมวดหมู่สินค้า',
              hintText: 'หมวดหมู่สินค้า',
            ),
            const SizedBox(height: 20),

            // 6. รหัสสินค้า (พร้อมไอคอนสแกน)
            _buildInputField(
              label: 'รหัสสินค้า',
              hintText: '1402235544',
              controller: _idController,
              keyboardType: TextInputType.number,
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: SizedBox(
                  width: 24,
                  child: Center(
                    // ใช้ Icon แทน Image.asset เพื่อความง่ายหากคุณไม่ได้ตั้งค่า asset
                    child: Icon(Icons.qr_code_scanner_outlined, color: Colors.grey[700], size: 24,),
                    // หากใช้ Image.asset: Image.asset('assets/qr_code_icon.png', height: 24, width: 24,), 
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // 7. ปุ่ม "เพิ่มสินค้า"
            _buildAddProductButton(),
            const SizedBox(height: 20),

            // 8. "รีเซ็ตข้อมูล"
            _buildResetText(),
            const SizedBox(height: 10),
          ],
        ),
      ),
      // 9. Navigation Bar (ใช้ Widget ที่ถูกแยกไฟล์แล้ว)
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}