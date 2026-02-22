import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

// Import Model และ API
import '../../model/response/shop_response.dart'; 
import '../../api/api_shop.dart'; 

class EditShopController extends GetxController {
  final ShopResponse shop;
  EditShopController({required this.shop});

  // ✅ 1. สร้าง Instance ของ ApiShop เพื่อเรียกใช้งาน
  final ApiShop _apiShop = ApiShop();

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
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 80);
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
      Get.snackbar("แจ้งเตือน", "กรุณากรอกชื่อร้านและเบอร์โทร", 
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    try {
      // 2. เตรียม URL รูปภาพ
      String imageUrl = shop.imgShop; // ค่าเริ่มต้นคือรูปเดิม (กรณีไม่ได้เปลี่ยนรูป)

      // ถ้ามีการเลือกรูปใหม่ (File) -> ต้องทำการอัปโหลดก่อนเพื่อเอา URL
      if (selectedImage.value != null) {
        // TODO: ตรงนี้ต้องเรียก API Upload รูปภาพจริงๆ ของคุณ
        // ตัวอย่าง: imageUrl = await _apiShop.uploadImage(selectedImage.value!);
        
        // *สมมติว่าอัปโหลดเสร็จแล้วได้ URL มา (Mock URL)*
        imageUrl = "https://res.cloudinary.com/ddcuq2vh9/image/upload/v1770480984/twwca6tnsxqhvah3anao.jpg"; 
      }

      // 3. เตรียมข้อมูล (Map) เพื่อส่งเป็น JSON
      Map<String, dynamic> data = {
        "name": nameController.text,
        "phone": phoneController.text,
        "address": addressController.text,
        "pin_code": pinCodeController.text, // เช็ค Key ให้ตรงกับ Backend
        "img_shop": imageUrl, // ส่ง URL รูป
        "img_qrcode": shop.imgQrcode, // ส่งค่าเดิม
      };

      // ✅ 4. เรียก API UpdateShop (ใช้ _apiShop ที่ประกาศไว้ข้างบน)
      bool success = await _apiShop.updateShop(shop.shopId, data);

      if (success) {
        Get.back(result: true); // ปิดหน้าและส่งค่า true กลับไปให้หน้ารายการ Refresh
        Get.snackbar("สำเร็จ", "แก้ไขข้อมูลร้านค้าเรียบร้อย", 
            backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar("ผิดพลาด", "ไม่สามารถแก้ไขข้อมูลได้", 
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      print("Error SaveShop: $e");
      Get.snackbar("Error", "เกิดข้อผิดพลาด: $e", 
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}