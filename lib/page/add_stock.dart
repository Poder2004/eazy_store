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
  final TextEditingController _searchController = TextEditingController(); // สำหรับช่องค้นหา/Barcode
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _salePriceController = TextEditingController();
  
  // *** แยก Controller สต็อกเดิม กับ สต็อกที่จะเพิ่ม ***
  final TextEditingController _currentStockController = TextEditingController(); 
  final TextEditingController _addAmountController = TextEditingController(); 
  
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  // Function สำหรับเปลี่ยน Tab ใน Bottom Navigation Bar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // เพิ่ม Logic การเปลี่ยนหน้าตาม index ที่นี่ถ้าต้องการ
  }

  // ----------------------------------------------------------------
  // ฟังก์ชัน: ค้นหาสินค้า
  // ----------------------------------------------------------------
  Future<void> _handleSearch() async {
    String keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    // Show Loading
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator())
    ); 
    
    // เรียก API ค้นหา
    Product? product = await ApiProduct.searchProduct(keyword);
    
    // Hide Loading
    if (mounted) Navigator.pop(context); 

    if (product != null) {
      setState(() {
        _foundProduct = product;
        
        // Map ข้อมูลลง Controller เพื่อแสดงผล
        _nameController.text = product.name ?? '';
        
        // ราคาต้นทุน และ ราคาขาย
        _costController.text = (product.costPrice ?? 0).toString();
        _salePriceController.text = (product.sellPrice ?? 0).toString();
        
        // สต็อกคงเหลือ
        _currentStockController.text = (product.stock ?? 0).toString();
        
        // หน่วยนับ และ หมวดหมู่
        _unitController.text = product.unit ?? '-';
        _categoryController.text = product.categoryName ?? 'ไม่ระบุ';
        
        // เคลียร์ช่องจำนวนที่จะเพิ่ม รอให้ user กรอก
        _addAmountController.clear(); 
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบสินค้ารหัสนี้'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ----------------------------------------------------------------
  // ฟังก์ชัน: บันทึกสต็อก
  // ----------------------------------------------------------------
  Future<void> _handleSave() async {
    // Validation
    if (_foundProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาค้นหาสินค้าก่อน'), backgroundColor: Colors.orange)
      );
      return;
    }
    
    if (_addAmountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาระบุจำนวนที่เพิ่ม'), backgroundColor: Colors.orange)
      );
      return;
    }

    int amountToAdd = int.tryParse(_addAmountController.text) ?? 0;
    if (amountToAdd <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('จำนวนต้องมากกว่า 0'), backgroundColor: Colors.orange)
      );
      return;
    }

    // Show Loading
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator())
    );

    // เรียก API อัปเดตสต็อก
    bool success = await ApiProduct.updateStock(_foundProduct!.productId!, amountToAdd);

    // Hide Loading
    if (mounted) Navigator.pop(context);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เพิ่มสต็อกสำเร็จ!'), backgroundColor: Colors.green),
        );
        
        // อัปเดตหน้าจอทันทีเพื่อให้เห็นยอดใหม่
        setState(() {
           int currentStock = int.tryParse(_currentStockController.text) ?? 0;
           int newTotal = currentStock + amountToAdd;
           
           // อัปเดตยอดคงเหลือที่แสดงบนหน้าจอ
           _currentStockController.text = newTotal.toString();
           
           // เคลียร์ช่องจำนวนที่เพิ่ม
           _addAmountController.clear();
           
           // อัปเดตข้อมูลใน object ด้วย (เผื่อมีการใช้ต่อ)
           _foundProduct!.stock = newTotal;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกไม่สำเร็จ กรุณาลองใหม่'), backgroundColor: Colors.red),
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
    });
  }

  // 🖼️ Widget สำหรับ input field ทั่วไป
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
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
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
            contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
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

  // 🔍 Widget สำหรับช่องกรอกรหัสสินค้า
  Widget _buildBarcodeInputField() {
    const Color kInputBorderColor = Color(0xFFE0E0C0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "รหัสสินค้า",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
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
            onSubmitted: (value) => _handleSearch(), // กด Enter เพื่อค้นหา
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'กรอกหรือสแกนรหัสสินค้า',
              hintStyle: const TextStyle(color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
              border: InputBorder.none,
              // ปุ่ม Scan Barcode (ด้านหลัง)
              suffixIcon: IconButton(
                icon: Icon(Icons.qr_code_scanner_outlined, color: Colors.grey[700]),
                onPressed: () {
                  // TODO: เพิ่ม Barcode Scanner ตรงนี้
                  print("Open Camera Scanner");
                  // เมื่อได้ค่า Barcode มา:
                  // _searchController.text = barcode;
                  // _handleSearch();
                },
              ),
              // ปุ่มค้นหา (ด้านหน้า)
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

  // 🖼️ Widget แสดงรูปภาพสินค้า
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
          child: _foundProduct?.imgProduct != null && _foundProduct!.imgProduct!.isNotEmpty
              ? Image.network(
                  _foundProduct!.imgProduct!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                )
              : const Icon(Icons.image, size: 50, color: Colors.grey),
        ),
      ),
    );
  }

  // 🖼️ Widget ปุ่มบันทึก
  Widget _buildSaveButton() {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        onPressed: _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7B68EE), // สีม่วงเข้ม
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          elevation: 5,
        ),
        child: const Text(
          'บันทึก',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  // 🖼️ Widget ปุ่มยกเลิก
  Widget _buildCancelButton() {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        onPressed: _handleCancel,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE0E0E0), // สีเทาอ่อน
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          elevation: 5,
        ),
        child: const Text(
          'ยกเลิก',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF808080)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      
      // AppBar
      appBar: AppBar(
        title: const Text(
          'เพิ่มสต็อกสินค้า',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black87),
        ),
        centerTitle: true,
        backgroundColor: _kBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      
      // Body
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ช่องค้นหา
            _buildBarcodeInputField(),
            const SizedBox(height: 15),

            // 2. รูปภาพสินค้า
            _buildProductImage(),
            const SizedBox(height: 25),

            // 3. ชื่อสินค้า (Read Only)
            _buildInputField(label: 'ชื่อสินค้า', controller: _nameController, readOnly: true),
            const SizedBox(height: 20),

            // 4. ราคาต้นทุน & ราคาขาย (Read Only)
            Row(
              children: [
                Expanded(child: _buildInputField(label: 'ราคาต้นทุน', controller: _costController, readOnly: true)),
                const SizedBox(width: 15),
                Expanded(child: _buildInputField(label: 'ราคาขาย', controller: _salePriceController, readOnly: true)),
              ],
            ),
            const SizedBox(height: 20),

            // 5. จัดการสต็อก (คงเหลือเดิม Read Only / เพิ่มจำนวน Editable)
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    label: 'คงเหลือเดิม', 
                    controller: _currentStockController, 
                    readOnly: true
                  )
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildInputField(
                    label: 'เพิ่มจำนวน', 
                    controller: _addAmountController, 
                    keyboardType: TextInputType.number
                  )
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 6. หน่วยนับ & หมวดหมู่ (Read Only)
            Row(
              children: [
                 Expanded(child: _buildInputField(label: 'หน่วยนับ', controller: _unitController, readOnly: true)),
                 const SizedBox(width: 15),
                 Expanded(child: _buildInputField(label: 'หมวดหมู่', controller: _categoryController, readOnly: true)),
              ],
            ),
            const SizedBox(height: 40),

            // 7. ปุ่ม Action (บันทึก / ยกเลิก)
            Row(
              children: [
                Expanded(child: _buildSaveButton()),
                const SizedBox(width: 15),
                Expanded(child: _buildCancelButton()),
              ],
            ),
            const SizedBox(height: 20),
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