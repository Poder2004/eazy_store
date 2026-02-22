import 'dart:io';
import 'package:eazy_store/api/api_service_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

// Import Model, API และ Service
import '../../../model/response/shop_response.dart';
import '../../../api/api_shop.dart';
// ✅ 1. Import ไฟล์ Service สำหรับอัปโหลดรูปภาพ (แก้ไข path ให้ตรงกับโปรเจกต์ของคุณ)

class EditShopController extends GetxController {
  final ShopResponse shop;
  EditShopController({required this.shop});

  // สร้าง Instance ของ ApiShop และ ImageUploadService
  final ApiShop _apiShop = ApiShop();
  final ImageUploadService _uploadService =
      ImageUploadService(); // ✅ เพิ่มบรรทัดนี้

  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController addressController;
  late TextEditingController pinCodeController;

  var selectedImage = Rxn<File>();
  final ImagePicker _picker = ImagePicker();

  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // นำข้อมูลเดิมมาแสดงในช่องกรอก
    nameController = TextEditingController(text: shop.name);
    phoneController = TextEditingController(text: shop.phone);
    addressController = TextEditingController(text: shop.address);
    pinCodeController = TextEditingController(text: shop.pinCode ?? "");
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    pinCodeController.dispose();
    super.onClose();
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

  Future<void> saveShop() async {
    // 1. เช็คความถูกต้องข้อมูลพื้นฐาน
    if (nameController.text.isEmpty || phoneController.text.isEmpty) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณากรอกชื่อร้านและเบอร์โทร",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    try {
      // 2. เตรียม URL รูปภาพ
      String imageUrl =
          shop.imgShop; // ค่าเริ่มต้นคือรูปเดิม (กรณีไม่ได้เปลี่ยนรูป)

      // ✅ 3. ถ้ามีการเลือกรูปใหม่ ให้ทำการอัปโหลดขึ้น Cloudinary
      if (selectedImage.value != null) {
        String? uploadedUrl = await _uploadService.uploadImage(
          selectedImage.value!,
        );

        if (uploadedUrl != null) {
          imageUrl = uploadedUrl; // ถ้าอัปโหลดสำเร็จ เอา URL ใหม่ไปใช้
        } else {
          // ถ้าอัปโหลดรูปไม่สำเร็จ ให้หยุดการทำงานแล้วแจ้งเตือน
          isLoading.value = false;
          Get.snackbar(
            "อัปโหลดล้มเหลว",
            "ไม่สามารถอัปโหลดรูปร้านค้าได้ กรุณาลองใหม่",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
      }

      // 4. เตรียมข้อมูล (Map) เพื่อส่งเป็น JSON ให้ Backend
      Map<String, dynamic> data = {
        "name": nameController.text,
        "phone": phoneController.text,
        "address": addressController.text,
        "pin_code": pinCodeController.text,
        "img_shop":
            imageUrl, // ✅ ส่ง URL รูปล่าสุด (ไม่ว่าจะเป็นรูปเก่าหรือใหม่)
        "img_qrcode": shop.imgQrcode,
      };

      // 5. เรียก API UpdateShop
      bool success = await _apiShop.updateShop(shop.shopId, data);

      if (success) {
        Get.back(
          result: true,
        ); // ปิดหน้าและส่งค่า true กลับไปให้หน้า Profile ดึงข้อมูลใหม่
        Get.snackbar(
          "สำเร็จ",
          "แก้ไขข้อมูลร้านค้าเรียบร้อย",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          "ผิดพลาด",
          "ไม่สามารถแก้ไขข้อมูลได้",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print("Error SaveShop: $e");
      Get.snackbar(
        "Error",
        "เกิดข้อผิดพลาด: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
