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

// 🎨 Theme Constants
const Color _kPrimaryColor = Color(0xFF6B8E23);
const Color _kBackgroundColor = Color(
  0xFFF2F4F7,
); // สีพื้นหลังเทาอ่อนแบบ Modern
const Color _kCardColor = Colors.white;
const Color _kInputFillColor = Color(0xFFF9FAFB); // สีพื้นหลังช่องกรอก

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
    'แพ็ค',
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
    if (mounted) setState(() => _categoryList = list);
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
            const SizedBox(height: 20),
            const Center(
              child: Text(
                "อัปโหลดรูปสินค้า",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library, color: Colors.blue),
              ),
              title: const Text('เลือกจากคลังภาพ'),
              onTap: () {
                Get.back();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: Colors.green),
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
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<void> _handleSaveProduct() async {
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
      final uploadService = ImageUploadService();
      String? uploadedImageUrl = await uploadService.uploadImage(_imageFile!);

      if (uploadedImageUrl == null) throw Exception("อัปโหลดรูปไม่ผ่าน");

      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;

      Product newProduct = Product(
        shopId: shopId,
        categoryId: _selectedCategoryObject!.categoryId,
        name: _nameController.text.trim(),
        barcode: _idController.text.trim().isEmpty
            ? null
            : _idController.text.trim(),
        imgProduct: uploadedImageUrl,
        sellPrice: double.parse(_salePriceController.text),
        costPrice: double.parse(_costController.text),
        stock: int.parse(
          _stockController.text.isEmpty ? "0" : _stockController.text,
        ),
        unit: _unitController.text.trim(),
        status: true,
      );

      final result = await ApiProduct.createProduct(newProduct);

      if (result['success']) {
        _showSuccessPopup();
      } else {
        throw Exception(result['error']);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 60,
                color: _kPrimaryColor,
              ),
              const SizedBox(height: 15),
              const Text(
                "เพิ่มสินค้าสำเร็จ!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "สินค้าถูกบันทึกเข้าระบบเรียบร้อยแล้ว",
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Get.back();
                    _resetForm();
                  },
                  child: const Text(
                    "เพิ่มสินค้าต่อ",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Get.back();
                  Get.offAll(() => const HomePage());
                },
                child: const Text(
                  "กลับหน้าหลัก",
                  style: TextStyle(color: Colors.grey),
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

  // ==================== UI BUILDER ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        title: Text(
          'เพิ่มสินค้าใหม่',
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
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 📸 ส่วนที่ 1: รูปภาพ (Card) -> ✨ แก้ไข: ห่อด้วย Center
            _buildSectionCard(
              child: Center(
                child: Column(
                  children: [
                    _buildImagePicker(),
                    const SizedBox(height: 10),
                    Text(
                      "แตะเพื่ออัปโหลดรูปภาพ",
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 📝 ส่วนที่ 2: ข้อมูลพื้นฐาน (Card)
            _buildSectionCard(
              title: "ข้อมูลทั่วไป",
              child: Column(
                children: [
                  _buildModernField(
                    label: "ชื่อสินค้า",
                    controller: _nameController,
                    hintText: "เช่น น้ำดื่มตราสิงห์ 600ml",
                    icon: Icons.shopping_bag_outlined,
                  ),
                  const SizedBox(height: 15),
                  _buildCategoryDropdown(),
                  const SizedBox(height: 15),
                  _buildBarcodeField(),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 💰 ส่วนที่ 3: ราคาและสต็อก (Card)
            _buildSectionCard(
              title: "ราคาและคลังสินค้า",
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernField(
                          label: "ต้นทุน",
                          controller: _costController,
                          hintText: "0.00",
                          isNumber: true,
                          icon: Icons.monetization_on_outlined,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildModernField(
                          label: "ราคาขาย",
                          controller: _salePriceController,
                          hintText: "0.00",
                          isNumber: true,
                          icon: Icons.sell_outlined,
                          isHighlight: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernField(
                          label: "จำนวน",
                          controller: _stockController,
                          hintText: "0",
                          isNumber: true,
                          icon: Icons.inventory_2_outlined,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(child: _buildUnitHybridField()),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // 🔘 ปุ่มกด
            _buildAddProductButton(),
            const SizedBox(height: 15),
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

  // --- Widget Helpers ---

  // การ์ดพื้นหลังสีขาว
  Widget _buildSectionCard({required Widget child, String? title}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Divider(height: 25),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _showImagePickerOptions,
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(20),
        padding: const EdgeInsets.all(4),
        color: _kPrimaryColor.withOpacity(0.5),
        strokeWidth: 2,
        dashPattern: const [8, 4],
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: _kInputFillColor,
            borderRadius: BorderRadius.circular(16),
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
                      Icons.add_a_photo_rounded,
                      size: 40,
                      color: _kPrimaryColor,
                    ),
                  ],
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildModernField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    bool isNumber = false,
    IconData? icon,
    bool isHighlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _kInputFillColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHighlight
                  ? _kPrimaryColor.withOpacity(0.5)
                  : Colors.transparent,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: icon != null
                  ? Icon(
                      icon,
                      color: isHighlight ? _kPrimaryColor : Colors.grey[400],
                      size: 20,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "หมวดหมู่",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _kInputFillColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<CategoryModel>(
              isExpanded: true,
              value: _selectedCategoryObject,
              hint: Text(
                "เลือกหมวดหมู่",
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              items: _categoryList
                  .map(
                    (cat) =>
                        DropdownMenuItem(value: cat, child: Text(cat.name)),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedCategoryObject = val),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitHybridField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "หน่วยนับ",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _kInputFillColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _unitController,
            decoration: InputDecoration(
              hintText: "เช่น ชิ้น",
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: Icon(Icons.scale, color: Colors.grey[400], size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: PopupMenuButton<String>(
                icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                onSelected: (val) => setState(() => _unitController.text = val),
                itemBuilder: (ctx) => _unitOptions
                    .map((e) => PopupMenuItem(value: e, child: Text(e)))
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarcodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "บาร์โค้ด",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _kInputFillColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _idController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "พิมพ์หรือสแกน",
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: Icon(
                      Icons.qr_code,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // ✨ ปุ่มสแกนแบบ Modern
            InkWell(
              onTap: () async {
                var result = await Get.to(() => const ScanBarcodePage());
                if (result != null && result is String) {
                  setState(() => _idController.text = result);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kPrimaryColor),
                ),
                child: const Icon(Icons.qr_code_scanner, color: _kPrimaryColor),
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
      child: ElevatedButton(
        onPressed: _isSaving ? null : _handleSaveProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 5,
          shadowColor: _kPrimaryColor.withOpacity(0.4),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                "บันทึกสินค้า",
                style: TextStyle(
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
      label: const Text('ล้างข้อมูล', style: TextStyle(color: Colors.grey)),
    ),
  );
}
