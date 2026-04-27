import 'dart:io';
import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/api/api_service_image.dart';
import 'package:eazy_store/page/homepage/home_page.dart';
import 'package:eazy_store/model/request/category_model.dart';
import 'package:eazy_store/model/request/product_request.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/image_picker_sheet.dart';

class AddProductController extends GetxController {
  var selectedIndex = 0.obs;
  final _picker = ImagePicker();
  var categoryList = <CategoryModel>[].obs;

  final List<String> unitOptions = [
    'ชิ้น',
    'กล่อง',
    'ลัง',
    'ขวด',
    'ซอง',
    'กิโลกรัม',
    'แพ็ค',
  ];

  final nameController = TextEditingController();
  final costController = TextEditingController();
  final salePriceController = TextEditingController();
  final stockController = TextEditingController();
  final unitController = TextEditingController();
  final idController = TextEditingController();

  Rx<File?> imageFile = Rx<File?>(null);
  Rx<CategoryModel?> selectedCategoryObject = Rx<CategoryModel?>(null);
  var isSaving = false.obs;

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
    super.onClose();
  }

  // ---------------- Functions ----------------
  Future<void> fetchCategories() async {
    final list = await ApiProduct.getCategories();
    categoryList.value = list;
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

    isSaving.value = true;

    try {
      final uploadService = ImageUploadService();
      String? uploadedImageUrl = await uploadService.uploadImage(
        imageFile.value!,
      );

      if (uploadedImageUrl == null) throw Exception("อัปโหลดรูปไม่ผ่าน");

      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;

      ProductRequest newProduct = ProductRequest(
        shopId: shopId,
        categoryId: selectedCategoryObject.value!.categoryId,
        name: nameController.text.trim(),
        barcode: idController.text.trim().isEmpty
            ? null
            : idController.text.trim(),
        imgProduct: uploadedImageUrl,
        sellPrice: double.parse(salePriceController.text),
        costPrice: double.parse(costController.text),
        stock: int.parse(
          stockController.text.isEmpty ? "0" : stockController.text,
        ),
        unit: unitController.text.trim(),
        status: true,
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
  }
}
