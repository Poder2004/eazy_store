// ไฟล์: lib/sale_producct/edit_product_controller.dart (ปรับ path ตามจริงของคุณ)
import 'dart:io';
import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/api/api_service_image.dart';
import 'package:eazy_store/model/response/product_response.dart';
import 'package:eazy_store/model/request/category_model.dart';
import 'package:eazy_store/utils/thai_sort.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/image_picker_sheet.dart';

class EditProductController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // ---------------- Controllers ----------------
  late TextEditingController nameCtrl;
  late TextEditingController barcodeCtrl;
  late TextEditingController stockCtrl;
  late TextEditingController unitCtrl;

  // เก็บราคาเดิมไว้ใช้ส่งกลับ API (ราคาแก้ไขได้ผ่านหน้า Add Stock)
  double _currentSellPrice = 0.0;
  double _currentCostPrice = 0.0;

  // ---------------- Data Variables ----------------
  late ProductResponse originalProduct;
  var isLoading = false.obs;

  // 📷 ส่วนจัดการรูปภาพ
  var selectedImage = Rxn<File>();
  final ImagePicker _picker = ImagePicker();
  final ImageUploadService _imageService = ImageUploadService();

  // 📂 ส่วนจัดการหมวดหมู่
  var categories = <CategoryModel>[].obs;
  var selectedCategory = Rxn<CategoryModel>();

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is ProductResponse) {
      originalProduct = Get.arguments as ProductResponse;

      // Setup ค่าเริ่มต้น
      nameCtrl = TextEditingController(text: originalProduct.name);
      barcodeCtrl = TextEditingController(text: originalProduct.barcode ?? "");
      _currentSellPrice = originalProduct.sellPrice;
      _currentCostPrice = originalProduct.costPrice;
      stockCtrl = TextEditingController(text: originalProduct.stock.toString());
      unitCtrl = TextEditingController(text: originalProduct.unit);

      // โหลดหมวดหมู่
      fetchCategories();
    } else {
      // ถ้าไม่มีข้อมูลส่งมา ให้เด้งกลับทันที
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.back();
      });
    }
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    barcodeCtrl.dispose();
    stockCtrl.dispose();
    unitCtrl.dispose();
    super.onClose();
  }

  // ---------------- Functions ----------------

  Future<void> fetchCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shopId = prefs.getInt('shopId') ?? originalProduct.shopId;
      var list = await ApiProduct.getCategories(shopId);
      
      // Remove duplicates by categoryId
      final seen = <int>{};
      final uniqueList = list.where((cat) => seen.add(cat.categoryId)).toList();
      
      uniqueList.sort((a, b) => thaiSortKey(a.name).compareTo(thaiSortKey(b.name)));
      final preferredCategoryId =
          selectedCategory.value?.categoryId ?? originalProduct.categoryId;
      categories.assignAll(uniqueList);

      if (preferredCategoryId != 0) {
        selectedCategory.value = categories.firstWhere(
          (cat) => cat.categoryId == preferredCategoryId,
          orElse: () => CategoryModel(
            categoryId: 0,
            shopId: originalProduct.shopId,
            name: "ไม่ระบุ",
            status: true,
          ),
        );
      }
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  void showImagePickerOptions() {
    ImagePickerSheet.show(
      title: "เปลี่ยนรูปสินค้า",
      onImagePicked: (source) {
        pickImage(source);
      },
    );
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (image != null) {
        selectedImage.value = File(image.path);
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  // แสดง Dialog ยืนยันก่อนบันทึก
  void confirmSave(BuildContext context) {
    if (!formKey.currentState!.validate()) return;
    if (selectedCategory.value == null) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณาเลือกหมวดหมู่สินค้า",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B8E23).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.save_as_rounded,
                  size: 40,
                  color: Color(0xFF6B8E23),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "ยืนยันการแก้ไข?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "ข้อมูลสินค้าจะถูกอัปเดตเข้าสู่ระบบ\nคุณตรวจสอบความถูกต้องเรียบร้อยแล้วใช่ไหม?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        "ตรวจสอบก่อน",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        saveProduct();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B8E23),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "ยืนยันบันทึก",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // 💾 บันทึกข้อมูล (ยิง API)
  Future<void> saveProduct() async {
    isLoading.value = true;

    try {
      String? newImageUrl;

      if (selectedImage.value != null) {
        Get.snackbar(
          "กำลังประมวลผล",
          "กำลังอัปโหลดรูปภาพ...",
          showProgressIndicator: true,
        );
        newImageUrl = await _imageService.uploadImage(selectedImage.value!);

        if (newImageUrl == null) {
          isLoading.value = false;
          Get.snackbar(
            "ผิดพลาด",
            "อัปโหลดรูปไม่ผ่าน กรุณาลองใหม่",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
      }

      Map<String, dynamic> updateData = {
        "name": nameCtrl.text.trim(),
        "barcode": barcodeCtrl.text.trim().isEmpty
            ? null
            : barcodeCtrl.text.trim(),
        "sell_price": _currentSellPrice,
        "cost_price": _currentCostPrice,
        "unit": unitCtrl.text.trim(),
        "category_id": selectedCategory.value!.categoryId,
      };

      if (newImageUrl != null) {
        updateData["img_product"] = newImageUrl;
      }

      ProductResponse? updatedProduct = await ApiProduct.updateProduct(
        originalProduct.productId!,
        updateData,
      );

      isLoading.value = false;

      if (updatedProduct != null) {
        Get.back(result: updatedProduct);
        Get.snackbar(
          "สำเร็จ",
          "แก้ไขข้อมูลเรียบร้อย",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          "ผิดพลาด",
          "บันทึกข้อมูลไม่สำเร็จ",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", "เกิดข้อผิดพลาด: $e", backgroundColor: Colors.red);
    }
  }

  Future<bool> addNewCategory(String categoryName) async {
    try {
      final name = categoryName.trim();
      final prefs = await SharedPreferences.getInstance();
      final shopId = prefs.getInt('shopId') ?? originalProduct.shopId;

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
      selectedCategory.value = created;

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
      final shopId = prefs.getInt('shopId') ?? originalProduct.shopId;

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

      if (selectedCategory.value?.categoryId == categoryId) {
        selectedCategory.value = CategoryModel(
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
    final shopId = prefs.getInt('shopId') ?? originalProduct.shopId;
    if (shopId == 0) return 0;
    return ApiProduct.getCategoryProductCount(
      shopId: shopId,
      categoryId: categoryId,
    );
  }

  Future<bool> disableCategory(CategoryModel category) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shopId = prefs.getInt('shopId') ?? originalProduct.shopId;

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

      if (selectedCategory.value?.categoryId == category.categoryId) {
        selectedCategory.value = null;
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
