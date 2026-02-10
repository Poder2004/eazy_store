import 'package:eazy_store/menu_bar/bottom_navbar.dart';
import 'package:flutter/material.dart';
import '../api/api_product.dart'; // ตรวจสอบ path ให้ถูกต้อง
import '../model/request/product_model.dart'; // ตรวจสอบ path ให้ถูกต้อง

// กำหนดสีหลักที่ใช้ในแอปพลิเคชัน
const Color _kPrimaryColor = Color(0xFF6B8E23); // สีเขียวมะกอก/ทหาร
const Color _kBackgroundColor = Color(0xFFF7F7F7); // สีพื้นหลังอ่อน
const Color _kInputFillColor = Color(0xFFF0F0E0); // สีพื้นหลังของ Input

class AddStockScreen extends StatefulWidget {
  const AddStockScreen({super.key});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  // State สำหรับจัดการ Bottom Navigation Bar
  int _selectedIndex = 0;

  // เก็บ Object สินค้าที่ค้นเจอไว้ตรงนี้
  Product? _foundProduct;

  // Controllers สำหรับ TextField
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _salePriceController = TextEditingController();
  final TextEditingController _currentStockController = TextEditingController();
  final TextEditingController _addAmountController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  // ตัวแปรสำหรับแสดงผลยอดรวม Real-time (Optional)
  int _calculatedTotal = 0;

  @override
  void initState() {
    super.initState();
    // เพิ่ม Listener เพื่อคำนวณยอดรวมทันทีที่พิมพ์ (Optional UX improvement)
    _addAmountController.addListener(() {
      if (_foundProduct != null) {
        int current = int.tryParse(_currentStockController.text) ?? 0;
        int add = int.tryParse(_addAmountController.text) ?? 0;
        setState(() {
          _calculatedTotal = current + add;
        });
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // ----------------------------------------------------------------
  // ฟังก์ชัน: ค้นหาสินค้า
  // ----------------------------------------------------------------
  Future<void> _handleSearch() async {
    String keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    Product? product = await ApiProduct.searchProduct(keyword);

    if (mounted) Navigator.pop(context);

    if (product != null) {
      setState(() {
        _foundProduct = product;
        _nameController.text = product.name;
        _costController.text = (product.costPrice).toString();
        _salePriceController.text = (product.sellPrice).toString();
        _currentStockController.text = (product.stock).toString();
        _unitController.text = product.unit;
        _categoryController.text = product.categoryName ?? 'ไม่ระบุ';

        _addAmountController.clear();
        _calculatedTotal = product.stock; // เริ่มต้นยอดรวมเท่ากับของเดิม
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่พบสินค้ารหัสนี้'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ----------------------------------------------------------------
  // ✨ ฟังก์ชันใหม่ 1: ตรวจสอบและแสดง Pop-up ยืนยัน
  // ----------------------------------------------------------------
  void _handleSaveCheck() {
    // 1. Validation เบื้องต้น
    if (_foundProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาค้นหาสินค้าก่อน'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_addAmountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาระบุจำนวนที่เพิ่ม'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    int amountToAdd = int.tryParse(_addAmountController.text) ?? 0;
    if (amountToAdd <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('จำนวนต้องมากกว่า 0'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 2. คำนวณตัวเลขเพื่อโชว์ใน Dialog
    int currentStock = int.tryParse(_currentStockController.text) ?? 0;
    int newTotal = currentStock + amountToAdd;

    // 3. แสดง Dialog ยืนยัน
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยืนยันการเพิ่มสต็อก'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('สินค้า: ${_nameController.text}'),
              const Divider(),
              Text('คงเหลือเดิม: $currentStock'),
              Text(
                'จำนวนที่เพิ่ม: +$amountToAdd',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              Text(
                'ยอดคงเหลือสุทธิ: $newTotal ${_unitController.text}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'ข้อมูลถูกต้องใช่หรือไม่?',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            // ปุ่มยกเลิก -> ปิด Dialog กลับไปแก้ไข
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(); // ปิด Dialog
              },
              icon: const Icon(Icons.edit, size: 18, color: Colors.white),
              label: const Text(
                'แก้ไข',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700], // สีพื้นหลังส้ม
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                elevation: 2, // เงาปุ่มเล็กน้อย
              ),
            ),
            // ปุ่มยืนยัน -> ปิด Dialog แล้วเรียก API
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _executeSaveToApi(amountToAdd);
              },
              icon: const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
              label: const Text(
                'ยืนยัน',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                elevation: 2,
              ),
            ),
          ],
        );
      },
    );
  }

  // ----------------------------------------------------------------
  // ✨ ฟังก์ชันใหม่ 2: ยิง API บันทึกจริง (ทำงานหลังกดยืนยัน)
  // ----------------------------------------------------------------
  Future<void> _executeSaveToApi(int amountToAdd) async {
    // Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    // เรียก API
    bool success = await ApiProduct.updateStock(
      _foundProduct!.productId!,
      amountToAdd,
    );

    // Hide Loading
    if (mounted) Navigator.pop(context);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เพิ่มสต็อกสำเร็จ!'),
            backgroundColor: Colors.green,
          ),
        );

        // อัปเดตหน้าจอทันที
        setState(() {
          int currentStock = int.tryParse(_currentStockController.text) ?? 0;
          int newTotal = currentStock + amountToAdd;

          _currentStockController.text = newTotal.toString();
          _addAmountController.clear();
          _foundProduct!.stock = newTotal;
          _calculatedTotal = newTotal; // Reset ยอดคำนวณ
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกไม่สำเร็จ กรุณาลองใหม่'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ฟังก์ชันสำหรับปุ่มยกเลิก/เคลียร์หน้าจอ
  void _handleCancel() {
    setState(() {
      _foundProduct = null;
      _searchController.clear();
      _nameController.clear();
      _costController.clear();
      _salePriceController.clear();
      _currentStockController.clear();
      _addAmountController.clear();
      _unitController.clear();
      _categoryController.clear();
      _calculatedTotal = 0;
    });
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final borderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: const BorderSide(color: Color(0xFFE0E0C0), width: 1.5),
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
            fillColor: _kInputFillColor,
            border: borderStyle,
            enabledBorder: borderStyle,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: _kPrimaryColor, width: 2.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarcodeInputField() {
    const Color kInputBorderColor = Color(0xFFE0E0C0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "รหัสสินค้า",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _kInputFillColor,
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: kInputBorderColor, width: 1.5),
          ),
          child: TextField(
            controller: _searchController,
            keyboardType: TextInputType.text,
            onSubmitted: (value) => _handleSearch(),
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'กรอกหรือสแกนรหัสสินค้า',
              hintStyle: const TextStyle(color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 12.0,
              ),
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.qr_code_scanner_outlined,
                  color: Colors.grey[700],
                ),
                onPressed: () {
                  print("Open Camera Scanner");
                },
              ),
              prefixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _handleSearch,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductImage() {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F0),
          borderRadius: BorderRadius.circular(15.0),
          border: Border.all(color: const Color(0xFFE0E0C0), width: 2.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13.0),
          child:
              _foundProduct?.imgProduct != null &&
                  _foundProduct!.imgProduct!.isNotEmpty
              ? Image.network(
                  _foundProduct!.imgProduct!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: Colors.grey,
                  ),
                )
              : const Icon(Icons.image, size: 50, color: Colors.grey),
        ),
      ),
    );
  }

  // 🖼️ Widget ปุ่มบันทึก (แก้ไขให้ไปเรียก _handleSaveCheck)
  Widget _buildSaveButton() {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        onPressed:
            _handleSaveCheck, // ✨ เปลี่ยนจาก _handleSave เป็น _handleSaveCheck
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7B68EE),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: 5,
        ),
        child: const Text(
          'บันทึก',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        onPressed: _handleCancel,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE0E0E0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: 5,
        ),
        child: const Text(
          'ยกเลิก',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF808080),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
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
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBarcodeInputField(),
            const SizedBox(height: 15),
            if (_foundProduct != null) ...[
              _buildProductImage(),
              const SizedBox(height: 25),
              _buildInputField(
                label: 'ชื่อสินค้า',
                controller: _nameController,
                readOnly: true,
              ),
              const SizedBox(height: 20),
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
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      label: 'คงเหลือเดิม',
                      controller: _currentStockController,
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputField(
                          label: 'เพิ่มจำนวน',
                          controller: _addAmountController,
                          keyboardType: TextInputType.number,
                        ),
                        // ✨ แสดงยอดรวมแบบ Real-time ใต้ช่องกรอก
                        if (_addAmountController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              "รวมเป็น: $_calculatedTotal ${_unitController.text}",
                              style: TextStyle(
                                fontSize: 13,
                                color: _kPrimaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      label: 'หน่วยนับ',
                      controller: _unitController,
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildInputField(
                      label: 'หมวดหมู่',
                      controller: _categoryController,
                      readOnly: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(child: _buildSaveButton()),
                  const SizedBox(width: 15),
                  Expanded(child: _buildCancelButton()),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
