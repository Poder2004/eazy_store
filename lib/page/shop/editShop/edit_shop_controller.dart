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
    String phone = phoneController.text.trim();
    // 1. เช็คข้อมูลว่าง
    if (nameController.text.isEmpty ||
        phone.isEmpty ||
        addressController.text.isEmpty) {
      _showWarningDialog("ข้อมูลไม่ครบถ้วน", "กรุณากรอกข้อมูลให้ครบทุกช่อง");
      return;
    }

    // 🔥 2. เช็คเบอร์โทรศัพท์ (ตัวเลข 10 หลัก)
    if (phone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      _showWarningDialog(
        "เบอร์โทรศัพท์ไม่ถูกต้อง",
        "กรุณากรอกเป็นตัวเลขให้ครบ 10 หลัก",
      );
      return;
    }

    isLoading.value = true;
    try {
      String imageUrl = shop.imgShop;

      // 3. จัดการอัปโหลดรูปภาพ
      if (selectedImage.value != null) {
        String? uploadedUrl = await _uploadService.uploadImage(
          selectedImage.value!,
        );
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        } else {
          isLoading.value = false;
          _showWarningDialog(
            "อัปโหลดล้มเหลว",
            "ไม่สามารถอัปโหลดรูปภาพได้ กรุณาลองใหม่",
          );
          return;
        }
      }

      // 4. เตรียมข้อมูล
      Map<String, dynamic> data = {
        "name": nameController.text,
        "phone": phone,
        "address": addressController.text,
        "pin_code": pinCodeController.text,
        "img_shop": imageUrl,
        "img_qrcode": shop.imgQrcode,
      };

      // 5. เรียก API Update
      bool success = await _apiShop.updateShop(shop.shopId, data);

      if (success) {
        // ✅ แสดง Dialog สีเขียวเมื่อสำเร็จ
        _showSuccessDialog("สำเร็จ", "แก้ไขข้อมูลร้านค้าเรียบร้อยแล้ว");
      } else {
        _showWarningDialog(
          "ผิดพลาด",
          "ไม่สามารถแก้ไขข้อมูลได้ กรุณาลองใหม่ภายหลัง",
        );
      }
    } catch (e) {
      print("Error SaveShop: $e");
      _showWarningDialog("Error", "เกิดข้อผิดพลาด: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ ฟังก์ชันแจ้งเตือน (สีส้ม)
  void _showWarningDialog(String title, String message) {
    _buildDialog(title, message, Colors.orange, Icons.warning_amber_rounded);
  }

  // ✅ ฟังก์ชันสำเร็จ (สีเขียว)
  void _showSuccessDialog(String title, String message) {
    _buildDialog(
      title,
      message,
      Colors.green,
      Icons.check_circle_outline_rounded,
    );
  }

  // ฟังก์ชันกลางสำหรับสร้าง UI Dialog
  void _buildDialog(String title, String message, Color color, IconData icon) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 60),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Get.back();
                    // ถ้าเป็นเคสสำเร็จ (สีเขียว) ให้ปิดหน้า Edit ไปด้วยเลย
                    if (color == Colors.green) {
                      Get.back(result: true);
                    }
                  },
                  child: const Text(
                    "ตกลง",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
}
