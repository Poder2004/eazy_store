import 'package:dotted_border/dotted_border.dart';
import 'package:eazy_store/api/api_product.dart'; // ✨ เพิ่ม Import API
import '../model/request/product_model.dart';
import 'package:eazy_store/menu_bar/bottom_navbar.dart';
import 'package:eazy_store/sale_producct/scan_barcode.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color _kPrimaryColor = Color(0xFF6B8E23);
const Color _kBackgroundColor = Color(0xFFF7F7F7);

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  int _selectedIndex = 0;
  File? _imageFile;
  final _picker = ImagePicker();
  bool _isSaving = false; // ✨ สำหรับแสดง Loading

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _salePriceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _idController =
      TextEditingController(); // ใช้เก็บ Barcode

  String? _selectedCategory;
  final List<String> _categories = [
    'เครื่องดื่ม',
    'ขนมขบเคี้ยว',
    'อาหารสด',
    'อื่น ๆ',
  ];

  // Mapping หมวดหมู่เป็น ID ตาม Backend
  int _getCategoryId(String? categoryName) {
    switch (categoryName) {
      case 'เครื่องดื่ม':
        return 1;
      case 'ขนมขบเคี้ยว':
        return 2;
      case 'อาหารสด':
        return 3;
      default:
        return 4;
    }
  }

  final List<String> _unitOptions = [
    'ชิ้น',
    'กล่อง',
    'ลัง',
    'ขวด',
    'ซอง',
    'กิโลกรัม',
  ];
  Key _unitKey = UniqueKey();

  // 🔥 ฟังก์ชันหลักสำหรับการส่งข้อมูลไปยัง Backend
  Future<void> _handleSaveProduct() async {
    // 1. Validation เบื้องต้น
    if (_nameController.text.isEmpty ||
        _selectedCategory == null ||
        _costController.text.isEmpty ||
        _salePriceController.text.isEmpty) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณากรอกข้อมูลที่จำเป็นให้ครบถ้วน",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 2. ดึง Shop ID จาก SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 1; // Default เป็น 1 หากหาไม่เจอ

      // 3. เตรียมข้อมูลสินค้า (หมายเหตุ: ในแอปจริงควรอัปโหลดรูปภาพผ่าน ApiServiceImage ก่อนเพื่อเอา URL)
      String imgUrl =
          "https://placeholder.com/product.jpg"; // แทนที่ด้วย URL จริงจากการอัปโหลด

      Product newProduct = Product(
        shopId: shopId,
        categoryId: _getCategoryId(_selectedCategory),
        name: _nameController.text.trim(),
        barcode: _idController.text.trim().isEmpty
            ? null
            : _idController.text.trim(),
        imgProduct: imgUrl,
        sellPrice: double.parse(_salePriceController.text),
        costPrice: double.parse(_costController.text),
        stock: int.parse(
          _stockController.text.isEmpty ? "0" : _stockController.text,
        ),
        unit: _unitController.text.trim(),
        status: true,
      );

      // 4. เรียกใช้ API
      final result = await ApiProduct.createProduct(newProduct);

      if (result['success']) {
        Get.snackbar(
          "สำเร็จ",
          "บันทึกสินค้าเรียบร้อยแล้ว",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        _resetForm(); // ล้างข้อมูลหน้าจอ
      } else {
        Get.snackbar(
          "ผิดพลาด",
          result['error'],
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "ผิดพลาด",
        "เกิดข้อผิดพลาดในการบันทึก: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _resetForm() {
    setState(() {
      _nameController.clear();
      _costController.clear();
      _salePriceController.clear();
      _stockController.clear();
      _unitController.clear();
      _idController.clear();
      _selectedCategory = null;
      _imageFile = null;
      _unitKey = UniqueKey();
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<File?> _pickImageFromSource(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    return pickedFile != null ? File(pickedFile.path) : null;
  }

  void _showImageSourcePicker(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text(
          'เลือกรูปภาพ',
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('เลือกจากคลังภาพ', style: GoogleFonts.prompt()),
              onTap: () async {
                Get.back();
                final image = await _pickImageFromSource(ImageSource.gallery);
                if (image != null) setState(() => _imageFile = image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text('ถ่ายภาพ', style: GoogleFonts.prompt()),
              onTap: () async {
                Get.back();
                final image = await _pickImageFromSource(ImageSource.camera);
                if (image != null) setState(() => _imageFile = image);
              },
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImagePicker(),
            const SizedBox(height: 20),
            _buildInputField(
              label: 'ชื่อสินค้า',
              hintText: 'ชื่อสินค้า',
              controller: _nameController,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    label: 'ราคาต้นทุน',
                    hintText: '0.00',
                    controller: _costController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildInputField(
                    label: 'ราคาขาย',
                    hintText: '0.00',
                    controller: _salePriceController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    label: 'จำนวนสินค้า',
                    hintText: '0',
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: KeyedSubtree(
                    key: _unitKey,
                    child: _buildUnitAutocompleteField(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDropdownField(
              label: 'หมวดหมู่สินค้า',
              hintText: 'เลือกหมวดหมู่',
            ),
            const SizedBox(height: 20),
            _buildBarcodeField(context),
            const SizedBox(height: 40),
            _buildAddProductButton(),
            const SizedBox(height: 20),
            _buildResetText(),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

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
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor: const Color(0xFFF0F0E0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Color(0xFF939393)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Color(0xFF939393)),
              ),
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0E0),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: const Color(0xFF939393), width: 1.0),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedCategory,
              hint: Text(hintText),
              items: _categories
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitAutocompleteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'หน่วยนับสินค้า',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Autocomplete<String>(
          optionsBuilder: (val) => val.text.isEmpty
              ? _unitOptions
              : _unitOptions.where((e) => e.contains(val.text)),
          onSelected: (s) => _unitController.text = s,
          fieldViewBuilder: (ctx, ctrl, node, onSub) {
            ctrl.text = _unitController.text;
            return _buildInputField(
              label: '',
              hintText: 'หน่วยนับ',
              controller: ctrl,
            );
          },
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: () => _showImageSourcePicker(context),
        child: DottedBorder(
          borderType: BorderType.RRect,
          radius: const Radius.circular(15.0),
          dashPattern: const [6, 3],
          color: const Color(0xFF939393),
          strokeWidth: 2,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(15.0),
              image: _imageFile != null
                  ? DecorationImage(
                      image: FileImage(_imageFile!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _imageFile == null
                ? const Icon(
                    Icons.add_a_photo_outlined,
                    size: 40,
                    color: Colors.grey,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildBarcodeField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'บาร์โค้ดสินค้า (ถ้ามี)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildInputField(
                label: '',
                hintText: 'สแกนหรือพิมพ์เลขบาร์โค้ด',
                controller: _idController,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: () => Get.to(() => const ScanBarcodePage()),
              icon: const Icon(Icons.qr_code_scanner),
              style: IconButton.styleFrom(
                backgroundColor: _kPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddProductButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _handleSaveProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.add, color: Colors.white),
        label: Text(
          _isSaving ? 'กำลังบันทึก...' : 'เพิ่มสินค้า',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildResetText() {
    return Center(
      child: TextButton.icon(
        onPressed: _resetForm,
        icon: const Icon(Icons.refresh, size: 18, color: Colors.grey),
        label: const Text('รีเซ็ตข้อมูล', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
