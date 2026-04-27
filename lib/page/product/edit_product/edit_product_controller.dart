// ไฟล์: lib/sale_producct/edit_product_controller.dart (ปรับ path ตามจริงของคุณ)
import 'dart:io';
import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/api/api_service_image.dart';
import 'package:eazy_store/model/request/product_request.dart';
import 'package:eazy_store/model/response/product_response.dart';
import 'package:eazy_store/model/request/category_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../widgets/image_picker_sheet.dart';

class EditProductController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // ---------------- Controllers ----------------
  late TextEditingController nameCtrl;
  late TextEditingController barcodeCtrl;
  late TextEditingController sellPriceCtrl;
  late TextEditingController costPriceCtrl;
  late TextEditingController stockCtrl;
  late TextEditingController unitCtrl;

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
      sellPriceCtrl = TextEditingController(
        text: originalProduct.sellPrice.toString(),
      );
      costPriceCtrl = TextEditingController(
        text: originalProduct.costPrice.toString(),
      );
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
    sellPriceCtrl.dispose();
    costPriceCtrl.dispose();
    stockCtrl.dispose();
    unitCtrl.dispose();
    super.onClose();
  }

  // ---------------- Functions ----------------

  Future<void> fetchCategories() async {
    try {
      var list = await ApiProduct.getCategories();
      categories.assignAll(list);

      if (originalProduct.categoryId != 0) {
        selectedCategory.value = categories.firstWhere(
          (cat) => cat.categoryId == originalProduct.categoryId,
          orElse: () => CategoryModel(categoryId: 0, name: "ไม่ระบุ"),
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
        "sell_price": double.tryParse(sellPriceCtrl.text) ?? 0.0,
        "cost_price": double.tryParse(costPriceCtrl.text) ?? 0.0,
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
}
