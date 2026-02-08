import 'package:dotted_border/dotted_border.dart';
import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/api/api_service_image.dart';
import 'package:eazy_store/homepage/home_page.dart';
import 'package:eazy_store/menu_bar/bottom_navbar.dart';
import 'package:eazy_store/model/request/category_model.dart';
import 'package:eazy_store/model/request/product_model.dart';
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
  bool _isSaving = false;

  List<CategoryModel> _categoryList = [];
  CategoryModel? _selectedCategoryObject;
  final List<String> _unitOptions = [
    'ชิ้น',
    'กล่อง',
    'ลัง',
    'ขวด',
    'ซอง',
    'กิโลกรัม',
  ];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _salePriceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _idController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    _unitController.dispose();
    _idController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    final list = await ApiProduct.getCategories();
    if (mounted) {
      setState(() {
        _categoryList = list;
      });
    }
  }

  void _showImagePickerOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Wrap(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const Text(
              "เลือกรูปภาพสินค้า",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 50),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.photo_library, color: _kPrimaryColor),
              ),
              title: const Text('เลือกจากคลังภาพ'),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.camera_alt, color: _kPrimaryColor),
              ),
              title: const Text('ถ่ายภาพใหม่'),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  // 🔥 ฟังก์ชันบันทึกสินค้าที่ได้รับการแก้ไขเรื่องการอัปโหลดรูปภาพ
  Future<void> _handleSaveProduct() async {
    // 1. ตรวจสอบข้อมูลเบื้องต้น
    if (_imageFile == null) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณาเลือกรูปภาพสินค้า",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    if (_nameController.text.isEmpty ||
        _selectedCategoryObject == null ||
        _costController.text.isEmpty ||
        _salePriceController.text.isEmpty ||
        _unitController.text.isEmpty) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณากรอกข้อมูลให้ครบถ้วน",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 🚀 ขั้นตอนที่ 1: อัปโหลดรูปภาพขึ้น Cloudinary
      final uploadService = ImageUploadService();
      String? uploadedImageUrl = await uploadService.uploadImage(_imageFile!);

      if (uploadedImageUrl == null) {
        setState(() => _isSaving = false);
        Get.snackbar(
          "ผิดพลาด",
          "ไม่สามารถอัปโหลดรูปภาพได้",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return;
      }

      // 🚀 ขั้นตอนที่ 2: ดึง shopId
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;

      if (shopId == 0) {
        setState(() => _isSaving = false);
        Get.snackbar(
          "ผิดพลาด",
          "ไม่พบข้อมูลร้านค้า",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return;
      }

      // 🚀 ขั้นตอนที่ 3: สร้าง Product Object พร้อม URL จริงจาก Cloudinary
      Product newProduct = Product(
        shopId: shopId,
        categoryId: _selectedCategoryObject!.categoryId,
        name: _nameController.text.trim(),
        barcode: _idController.text.trim().isEmpty
            ? null
            : _idController.text.trim(),
        imgProduct: uploadedImageUrl, // ✨ ใช้ URL จริงที่ได้จากการอัปโหลด
        sellPrice: double.parse(_salePriceController.text),
        costPrice: double.parse(_costController.text),
        stock: int.parse(
          _stockController.text.isEmpty ? "0" : _stockController.text,
        ),
        unit: _unitController.text.trim(),
        status: true,
      );

      // 🚀 ขั้นตอนที่ 4: บันทึกลง Backend
      final result = await ApiProduct.createProduct(newProduct);

      if (result['success']) {
        _showSuccessPopup();
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
        "เกิดข้อผิดพลาด: $e",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSuccessPopup() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _kPrimaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 60,
                    color: _kPrimaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                "บันทึกสินค้าสำเร็จ!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                "สินค้าถูกเพิ่มเข้าสู่ระบบเรียบร้อยแล้ว\nคุณต้องการทำรายการใดต่อ?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Get.back();
                    _resetForm();
                  },
                  child: const Text(
                    "เพิ่มสินค้าต่อ",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: () {
                    Get.back();
                    Get.offAll(() => const HomePage());
                  },
                  child: Text(
                    "กลับสู่หน้าหลัก",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
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

  void _resetForm() {
    setState(() {
      _nameController.clear();
      _costController.clear();
      _salePriceController.clear();
      _stockController.clear();
      _unitController.clear();
      _idController.clear();
      _selectedCategoryObject = null;
      _imageFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        title: Text(
          'เพิ่มสินค้า',
          style: GoogleFonts.prompt(
            fontWeight: FontWeight.bold,
            fontSize: 22,
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
            const SizedBox(height: 25),
            _buildInputField(
              label: 'ชื่อสินค้า',
              hintText: 'ระบุชื่อสินค้า',
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
                Expanded(child: _buildUnitHybridField()),
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
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }

  Widget _buildUnitHybridField() {
    return _buildInputField(
      label: 'หน่วยนับ',
      hintText: 'เช่น ชิ้น, ขวด',
      controller: _unitController,
      suffixIcon: PopupMenuButton<String>(
        icon: const Icon(
          Icons.arrow_drop_down_circle_outlined,
          color: _kPrimaryColor,
        ),
        onSelected: (val) => setState(() => _unitController.text = val),
        itemBuilder: (ctx) => _unitOptions
            .map((e) => PopupMenuItem(value: e, child: Text(e)))
            .toList(),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        if (label.isNotEmpty) const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor: const Color(0xFFF0F0E0).withOpacity(0.5),
              suffixIcon: suffixIcon,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kPrimaryColor, width: 1.5),
              ),
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
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0E0).withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<CategoryModel>(
              isExpanded: true,
              value: _selectedCategoryObject,
              hint: Text(hintText),
              items: _categoryList
                  .map(
                    (cat) =>
                        DropdownMenuItem(value: cat, child: Text(cat.name)),
                  )
                  .toList(),
              onChanged: (newValue) =>
                  setState(() => _selectedCategoryObject = newValue),
            ),
          ),
        ),
      ],
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
                hintText: 'สแกนหรือพิมพ์บาร์โค้ด',
                controller: _idController,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => Get.to(() => const ScanBarcodePage()),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kPrimaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.qr_code_scanner, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: _showImagePickerOptions,
        child: DottedBorder(
          borderType: BorderType.RRect,
          radius: const Radius.circular(20),
          dashPattern: const [6, 4],
          color: Colors.grey[400]!,
          strokeWidth: 2,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              image: _imageFile != null
                  ? DecorationImage(
                      image: FileImage(_imageFile!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _imageFile == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.add_a_photo_outlined,
                        size: 44,
                        color: _kPrimaryColor,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "เพิ่มรูปสินค้า",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : null,
          ),
        ),
      ),
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
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
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
          _isSaving ? 'กำลังประมวลผล...' : 'เพิ่มสินค้าลงระบบ',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildResetText() => Center(
    child: TextButton.icon(
      onPressed: _resetForm,
      icon: const Icon(Icons.refresh, size: 18, color: Colors.grey),
      label: const Text(
        'ล้างข้อมูลทั้งหมด',
        style: TextStyle(color: Colors.grey),
      ),
    ),
  );
}
