import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // สำหรับ FilteringTextInputFormatter
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

// Import Model และ API ของคุณ (ตรวจสอบ path ให้ถูกต้อง)
import '../model/response/shop_response.dart'; 
import '../api/api_shop.dart'; 

// ----------------------------------------------------------------------
// 1. Controller สำหรับหน้าแก้ไข
// ----------------------------------------------------------------------
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

// ----------------------------------------------------------------------
// 2. UI หน้าจอแก้ไข
// ----------------------------------------------------------------------
class EditShopScreen extends StatelessWidget {
  final ShopResponse shop;

  const EditShopScreen({Key? key, required this.shop}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EditShopController(shop: shop));
    final Color primaryGreen = const Color(0xFF00C853);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("แก้ไขร้านค้า", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // --- ส่วนรูปภาพ ---
              Center(
                child: Stack(
                  children: [
                    Obx(() {
                      ImageProvider? imageProvider;
                      if (controller.selectedImage.value != null) {
                        imageProvider = FileImage(controller.selectedImage.value!);
                      } else if (shop.imgShop.isNotEmpty) {
                        imageProvider = NetworkImage(shop.imgShop);
                      }

                      return Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300, width: 2),
                          image: imageProvider != null
                              ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                              : null,
                        ),
                        child: imageProvider == null
                            ? Icon(Icons.store, size: 60, color: Colors.grey[400])
                            : null,
                      );
                    }),
                    
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          Get.bottomSheet(
                            Container(
                              color: Colors.white,
                              child: Wrap(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.camera_alt),
                                    title: const Text('ถ่ายรูป'),
                                    onTap: () {
                                      Get.back();
                                      controller.pickImage(ImageSource.camera);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.photo_library),
                                    title: const Text('เลือกจากอัลบั้ม'),
                                    onTap: () {
                                      Get.back();
                                      controller.pickImage(ImageSource.gallery);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryGreen,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),

              // --- ฟอร์มข้อมูล ---
              _buildLabel("ชื่อร้านค้า"),
              _buildTextField(controller.nameController, Icons.store),
              const SizedBox(height: 15),

              _buildLabel("เบอร์โทรศัพท์"),
              _buildTextField(
                controller.phoneController, 
                Icons.phone, 
                inputType: TextInputType.phone
              ),
              const SizedBox(height: 15),

              _buildLabel("ที่อยู่ร้านค้า"),
              _buildTextField(
                controller.addressController, 
                Icons.location_on, 
                maxLines: 3, 
                hint: "กรอกที่อยู่ร้านค้า"
              ),
              const SizedBox(height: 15),

              _buildLabel("รหัส Pin Code (สำหรับยืนยัน)"),
              _buildTextField(
                controller.pinCodeController, 
                Icons.lock, 
                inputType: TextInputType.number, 
                isPassword: true, 
                maxLength: 6,
                isNumberOnly: true, 
              ),

              const SizedBox(height: 40),

              // ปุ่มบันทึก
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value ? null : () => controller.saveShop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          width: 20, height: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Text("บันทึกการเปลี่ยนแปลง", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 5),
      child: Text(
        text,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700]),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    IconData icon, 
    {
      TextInputType inputType = TextInputType.text, 
      bool isPassword = false, 
      int maxLines = 1, 
      int? maxLength, 
      String? hint,
      bool isNumberOnly = false, 
    }
  ) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      obscureText: isPassword,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: isNumberOnly 
          ? [FilteringTextInputFormatter.digitsOnly] 
          : [],
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[50],
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00C853)),
        ),
        counterText: "",
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      ),
    );
  }
}