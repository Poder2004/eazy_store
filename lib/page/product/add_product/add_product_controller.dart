import 'dart:io';
import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/api/api_service_image.dart';
import 'package:eazy_store/page/homepage/home_page.dart';
import 'package:eazy_store/model/request/category_model.dart';
import 'package:eazy_store/model/request/product_request.dart';
import 'package:eazy_store/utils/thai_sort.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/image_picker_sheet.dart';

// แถวฟอร์มของหน่วยขายเพิ่มเติม 1 หน่วย (เช่น "ลัง = 12 ขวด")
class UnitFormEntry {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController conversionCtrl = TextEditingController();
  final TextEditingController barcodeCtrl = TextEditingController();
  final TextEditingController sellPriceCtrl = TextEditingController();
  final TextEditingController costPriceCtrl = TextEditingController();

  void dispose() {
    nameCtrl.dispose();
    conversionCtrl.dispose();
    barcodeCtrl.dispose();
    sellPriceCtrl.dispose();
    costPriceCtrl.dispose();
  }
}

class AddProductController extends GetxController {
  var selectedIndex = 0.obs;
  final _picker = ImagePicker();
  var categoryList = <CategoryModel>[].obs;

  final List<String> unitOptions =
      ['ชิ้น', 'กล่อง', 'ลัง', 'ขวด', 'ซอง', 'กิโลกรัม', 'แพ็ค']
        ..sort((a, b) => thaiSortKey(a).compareTo(thaiSortKey(b)));

  final nameController = TextEditingController();
  final costController = TextEditingController();
  final salePriceController = TextEditingController();
  final stockController = TextEditingController();
  final unitController = TextEditingController();
  final idController = TextEditingController();

  Rx<File?> imageFile = Rx<File?>(null);
  Rx<CategoryModel?> selectedCategoryObject = Rx<CategoryModel?>(null);
  var isSaving = false.obs;

  // หน่วยขายเพิ่มเติม (ลัง/แพ็ค) — ไม่บังคับมี พับเก็บไว้ก่อนเพราะสินค้าส่วนใหญ่ไม่ได้ใช้
  var unitForms = <UnitFormEntry>[].obs;
  var isUnitsSectionExpanded = false.obs;

  void toggleUnitsSection() =>
      isUnitsSectionExpanded.value = !isUnitsSectionExpanded.value;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  @override
  void onClose() {
    nameController.dispose();
    costController.dispose();
    salePriceController.dispose();
    stockController.dispose();
    unitController.dispose();
    idController.dispose();
    for (final f in unitForms) {
      f.dispose();
    }
    super.onClose();
  }

  void addUnitForm() {
    unitForms.add(UnitFormEntry());
    isUnitsSectionExpanded.value = true;
  }

  void removeUnitForm(int index) {
    unitForms[index].dispose();
    unitForms.removeAt(index);
  }

  // ---------------- Functions ----------------
  Future<void> fetchCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getInt('shopId') ?? 0;
    final list = await ApiProduct.getCategories(shopId);
    
    // Remove duplicates by categoryId
    final seen = <int>{};
    final uniqueList = list.where((cat) => seen.add(cat.categoryId)).toList();
    
    uniqueList.sort((a, b) => thaiSortKey(a.name).compareTo(thaiSortKey(b.name)));
    categoryList.value = uniqueList;
  }

  void showImagePickerOptions() {
    ImagePickerSheet.show(
      title: "อัปโหลดรูปสินค้า",
      onImagePicked: (source) {
        pickImage(source);
      },
    );
  }

  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      imageFile.value = File(pickedFile.path);
    }
  }

  Future<void> handleSaveProduct() async {
    if (imageFile.value == null) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณาเลือกรูปภาพสินค้า",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    if (nameController.text.isEmpty ||
        selectedCategoryObject.value == null ||
        costController.text.isEmpty ||
        salePriceController.text.isEmpty ||
        unitController.text.isEmpty) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณากรอกข้อมูลให้ครบถ้วน",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final unitsPayload = _buildUnitsPayload();
    if (unitsPayload == null) return; // แจ้งเตือนไปแล้วใน _buildUnitsPayload

    isSaving.value = true;

    try {
      final uploadService = ImageUploadService();
      String? uploadedImageUrl = await uploadService.uploadImage(
        imageFile.value!,
      );

      if (uploadedImageUrl == null) throw Exception("อัปโหลดรูปไม่ผ่าน");

      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;

      if (shopId == 0) {
        throw Exception("ไม่พบข้อมูลร้านค้า กรุณาเลือกร้านค้าก่อน");
      }

      ProductRequest newProduct = ProductRequest(
        shopId: shopId,
        categoryId: selectedCategoryObject.value!.categoryId,
        name: nameController.text.trim(),
        barcode: idController.text.trim().isEmpty
            ? null
            : idController.text.trim(),
        imgProduct: uploadedImageUrl,
        sellPrice: double.tryParse(salePriceController.text) ?? 0.0,
        costPrice: double.tryParse(costController.text) ?? 0.0,
        stock: int.parse(
          stockController.text.isEmpty ? "0" : stockController.text,
        ),
        unit: unitController.text.trim(),
        status: true,
        units: unitsPayload,
      );

      final result = await ApiProduct.createProduct(newProduct);

      if (result['success']) {
        showSuccessPopup();
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
      isSaving.value = false;
    }
  }

  void showSuccessPopup() {
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
                color: Color(0xFF6B8E23),
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
                    backgroundColor: const Color(0xFF6B8E23),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Get.back();
                    resetForm();
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

  void resetForm() {
    nameController.clear();
    costController.clear();
    salePriceController.clear();
    stockController.clear();
    unitController.clear();
    idController.clear();
    selectedCategoryObject.value = null;
    imageFile.value = null;
    for (final f in unitForms) {
      f.dispose();
    }
    unitForms.clear();
    isUnitsSectionExpanded.value = false;
  }

  // ตรวจสอบ + แปลงแถวฟอร์มหน่วยขายเพิ่มเติมเป็น payload สำหรับ ProductRequest
  // คืนค่า null แปลว่าข้อมูลไม่ผ่าน (แจ้งเตือนไปแล้วในนี้)
  List<Map<String, dynamic>>? _buildUnitsPayload() {
    final result = <Map<String, dynamic>>[];
    final seenNames = <String>{};
    final seenBarcodes = <String>{};
    final baseUnit = unitController.text.trim();
    final baseBarcode = idController.text.trim();

    for (final f in unitForms) {
      final uName = f.nameCtrl.text.trim();
      if (uName.isEmpty) continue; // แถวว่างข้ามไป

      if (uName == baseUnit) {
        Get.snackbar("แจ้งเตือน", "ชื่อหน่วยขาย \"$uName\" ซ้ำกับหน่วยฐานของสินค้า",
            backgroundColor: Colors.orange, colorText: Colors.white);
        return null;
      }
      if (!seenNames.add(uName)) {
        Get.snackbar("แจ้งเตือน", "มีหน่วยขายชื่อ \"$uName\" ซ้ำกันในสินค้าเดียวกัน",
            backgroundColor: Colors.orange, colorText: Colors.white);
        return null;
      }

      final conv = int.tryParse(f.conversionCtrl.text.trim());
      if (conv == null || conv <= 1) {
        Get.snackbar("แจ้งเตือน", "หน่วย \"$uName\" ต้องระบุจำนวนแปลงเป็นตัวเลขมากกว่า 1",
            backgroundColor: Colors.orange, colorText: Colors.white);
        return null;
      }

      final sell = double.tryParse(f.sellPriceCtrl.text.trim());
      if (sell == null || sell <= 0) {
        Get.snackbar("แจ้งเตือน", "กรุณากรอกราคาขายของหน่วย \"$uName\"",
            backgroundColor: Colors.orange, colorText: Colors.white);
        return null;
      }
      final cost = double.tryParse(f.costPriceCtrl.text.trim()) ?? 0;

      final barcode = f.barcodeCtrl.text.trim();
      String? bc;
      if (barcode.isNotEmpty) {
        if (barcode == baseBarcode) {
          Get.snackbar("แจ้งเตือน", "บาร์โค้ดหน่วย \"$uName\" ซ้ำกับบาร์โค้ดหลักของสินค้า",
              backgroundColor: Colors.orange, colorText: Colors.white);
          return null;
        }
        if (!seenBarcodes.add(barcode)) {
          Get.snackbar("แจ้งเตือน", "บาร์โค้ดหน่วย \"$uName\" ซ้ำกับหน่วยอื่นในสินค้าเดียวกัน",
              backgroundColor: Colors.orange, colorText: Colors.white);
          return null;
        }
        bc = barcode;
      }

      result.add({
        "unit_name": uName,
        "conversion_qty": conv,
        "barcode": bc,
        "sell_price": sell,
        "cost_price": cost,
      });
    }
    return result;
  }

  Future<bool> addNewCategory(String categoryName) async {
    try {
      final name = categoryName.trim();
      final prefs = await SharedPreferences.getInstance();
      final shopId = prefs.getInt('shopId') ?? 0;

      if (shopId == 0) {
        throw Exception("ไม่พบข้อมูลร้านค้า กรุณาเลือกร้านค้าก่อน");
      }

      final result = await ApiProduct.createCategory(shopId: shopId, name: name);
      if (result['success'] != true) {
        throw Exception(result['error'] ?? "เพิ่มหมวดหมู่ไม่สำเร็จ");
      }

      final created = CategoryModel.fromJson(
        result['data'] as Map<String, dynamic>,
      );
      selectedCategoryObject.value = created;

      Get.snackbar(
        "เพิ่มหมวดหมู่แล้ว",
        "บันทึกหมวดหมู่ $name สำเร็จ",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );

      await fetchCategories();
      return true;
    } catch (e) {
      Get.snackbar(
        "ผิดพลาด",
        "เพิ่มหมวดหมู่ไม่สำเร็จ: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<bool> editCategory(int categoryId, String newName) async {
    try {
      final name = newName.trim();
      final prefs = await SharedPreferences.getInstance();
      final shopId = prefs.getInt('shopId') ?? 0;

      if (shopId == 0) {
        throw Exception("ไม่พบข้อมูลร้านค้า กรุณาเลือกร้านค้าก่อน");
      }

      final result = await ApiProduct.updateCategory(
        categoryId: categoryId,
        shopId: shopId,
        name: name,
      );
      if (result['success'] != true) {
        throw Exception(result['error'] ?? "แก้ไขหมวดหมู่ไม่สำเร็จ");
      }

      if (selectedCategoryObject.value?.categoryId == categoryId) {
        selectedCategoryObject.value = CategoryModel(
          categoryId: categoryId,
          shopId: shopId,
          name: name,
          status: true,
        );
      }

      Get.snackbar(
        "แก้ไขแล้ว",
        "บันทึกชื่อหมวดหมู่สำเร็จ",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );

      await fetchCategories();
      return true;
    } catch (e) {
      Get.snackbar(
        "ผิดพลาด",
        "แก้ไขหมวดหมู่ไม่สำเร็จ: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<int> getCategoryProductCount(int categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getInt('shopId') ?? 0;
    if (shopId == 0) return 0;
    return ApiProduct.getCategoryProductCount(
      shopId: shopId,
      categoryId: categoryId,
    );
  }

  Future<bool> disableCategory(CategoryModel category) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shopId = prefs.getInt('shopId') ?? 0;

      if (shopId == 0) {
        throw Exception("ไม่พบข้อมูลร้านค้า กรุณาเลือกร้านค้าก่อน");
      }

      final result = await ApiProduct.deleteCategory(
        categoryId: category.categoryId,
        shopId: shopId,
      );
      if (result['success'] != true) {
        throw Exception(result['error'] ?? "ปิดใช้งานหมวดหมู่ไม่สำเร็จ");
      }

      if (selectedCategoryObject.value?.categoryId == category.categoryId) {
        selectedCategoryObject.value = null;
      }

      Get.snackbar(
        "ปิดใช้งานหมวดหมู่แล้ว",
        "หมวดหมู่ ${category.name} จะไม่แสดงให้เลือกอีก",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );

      await fetchCategories();
      return true;
    } catch (e) {
      Get.snackbar(
        "ผิดพลาด",
        "ปิดใช้งานหมวดหมู่ไม่สำเร็จ: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }
}
