import 'package:dotted_border/dotted_border.dart';
import 'package:eazy_store/api/api_product.dart';
import '../model/request/category_model.dart';
import '../model/request/product_model.dart';
import 'package:eazy_store/menu_bar/bottom_navbar.dart';
import 'package:eazy_store/sale_producct/scan_barcode.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert'; // เพิ่มสำหรับ jsonEncode/Decode
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

  // รายการหมวดหมู่จากฐานข้อมูล
  List<CategoryModel> _categoryList = [];
  CategoryModel? _selectedCategoryObject;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _salePriceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _idController = TextEditingController();

  final List<String> _unitOptions = [
    'ชิ้น',
    'กล่อง',
    'ลัง',
    'ขวด',
    'ซอง',
    'กิโลกรัม',
  ];
  Key _unitKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _fetchCategories(); // ✨ ดึงข้อมูลหมวดหมู่ทันทีที่เปิดหน้า
  }

  // ฟังก์ชันดึงหมวดหมู่จาก API
  Future<void> _fetchCategories() async {
    final list = await ApiProduct.getCategories();
    setState(() {
      _categoryList = list;
    });
  }

  Future<void> _handleSaveProduct() async {
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
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;

      if (shopId == 0) {
        Get.snackbar(
          "ผิดพลาด",
          "ไม่พบข้อมูลร้านค้าของคุณ กรุณาล็อกอินใหม่",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return;
      }

      Product newProduct = Product(
        shopId: shopId,
        categoryId: _selectedCategoryObject!.categoryId, // ✨ ใช้ ID จริงจาก DB
        name: _nameController.text.trim(),
        barcode: _idController.text.trim().isEmpty
            ? null
            : _idController.text.trim(),
        imgProduct: "https://placeholder.com/product.jpg",
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
        Get.snackbar(
          "สำเร็จ",
          "บันทึกสินค้าเรียบร้อยแล้ว",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        _resetForm();
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
      _unitKey = UniqueKey();
    });
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

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
            child: DropdownButton<CategoryModel>(
              isExpanded: true,
              value: _selectedCategoryObject,
              hint: Text(hintText),
              // ดึงรายการจาก _categoryList ที่ได้จาก API
              items: _categoryList.map((CategoryModel cat) {
                return DropdownMenuItem<CategoryModel>(
                  value: cat,
                  child: Text(cat.name),
                );
              }).toList(),
              onChanged: (CategoryModel? newValue) =>
                  setState(() => _selectedCategoryObject = newValue),
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
            ctrl.addListener(() => _unitController.text = ctrl.text);
            return _buildInputField(
              label: '',
              hintText: 'เช่น ชิ้น, ขวด',
              controller: ctrl,
            );
          },
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
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

  Widget _buildImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: () async {
          final img = await _picker.pickImage(source: ImageSource.gallery);
          if (img != null) setState(() => _imageFile = File(img.path));
        },
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

  Widget _buildResetText() => Center(
    child: TextButton.icon(
      onPressed: _resetForm,
      icon: const Icon(Icons.refresh, size: 18, color: Colors.grey),
      label: const Text('รีเซ็ตข้อมูล', style: TextStyle(color: Colors.grey)),
    ),
  );
}
