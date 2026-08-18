import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:eazy_store/page/homepage/home_page.dart';
import 'package:eazy_store/page/homepage/home_controller.dart';
import '../../../model/response/shop_response.dart';
import '../../../api/api_shop.dart';
import '../set_shop_pin_page.dart';
import '../../../api/api_service_image.dart';
import 'package:eazy_store/utils/error_message.dart';

class CreateShopController extends GetxController {
  // ==========================================
  // 1. ตัวแปรและ Controllers (State & Controllers)
  // ==========================================
  final shopNameController = TextEditingController();
  final shopPhoneController = TextEditingController();
  final addressController = TextEditingController();

  var isLoading = false.obs;

  final ImagePicker _picker = ImagePicker();
  Rx<File?> profileImage = Rx<File?>(null);
  Rx<File?> qrImage = Rx<File?>(null);

  final selectedProvince = Rx<String?>(null);
  final selectedDistrict = Rx<String?>(null);
  final selectedSubDistrict = Rx<String?>(null);
  Map<String, dynamic>? _fullAddressData;
  final provinces = <String>[].obs;
  final districts = <String>[].obs;
  final subdistricts = <String>[].obs;

  var currentPin = "".obs;
  var isConfirmPinStep = false.obs;
  String firstPin = "";

  @override
  void onInit() {
    super.onInit();
    _loadAddressData();
  }

  // ==========================================
  //  จัดการรูปภาพ (Image Picker Logic)
  // ==========================================
  Future<void> pickImage(ImageSource source, {required bool isProfile}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image != null) {
        if (isProfile) {
          profileImage.value = File(image.path);
        } else {
          qrImage.value = File(image.path);
        }
      }
    } catch (e) {
      print("Error picking image: $e");
      Get.snackbar(
        "เกิดข้อผิดพลาด",
        "ไม่สามารถเลือกรูปภาพได้ กรุณาลองใหม่อีกครั้ง",
      );
    }
  }

  // ==========================================
  // จัดการที่อยู่ (Address Logic)
  // ==========================================
  Future<void> _loadAddressData() async {
    try {
      const assetPath =
          'assets/data_address/province_with_district_and_sub_district.json';
      final String response = await rootBundle.loadString(assetPath);
      final List<dynamic> rawData = jsonDecode(response);
      final Map<String, dynamic> structuredData = {};
      for (var province in rawData) {
        String provinceName =
            province['name_th'] as String? ?? 'ไม่ระบุจังหวัด';
        structuredData[provinceName] = province;
      }
      _fullAddressData = structuredData;
      provinces.value = _fullAddressData!.keys.toList();
    } catch (e) {
      print("Error load address: $e");
    }
  }

  void onProvinceChanged(String? newValue) {
    if (newValue == null || _fullAddressData == null) {
      _resetDistrictAndSubdistrict();
      return;
    }
    selectedProvince.value = newValue;
    _resetDistrictAndSubdistrict();
    final provinceData = _fullAddressData![newValue]; //เข้าไปใน จ ที่เลือก
    final List<dynamic>? rawDistricts =
        provinceData?['districts'] as List<dynamic>?; //เเสดง  อ ออกมา

    if (rawDistricts != null) {
      districts.value = rawDistricts
          .map((district) => district['name_th'] as String? ?? '')
          .whereType<String>()
          .toList(); //เอาเข้าช่องที่ 2 เพื่อเอาไปเเสดง
    }
  }

  void onDistrictChanged(String? newValue) {
    if (newValue == null ||
        selectedProvince.value == null ||
        _fullAddressData == null) {
      _resetSubdistrict();
      return;
    }
    selectedDistrict.value = newValue;
    _resetSubdistrict();
    final provinceData = _fullAddressData![selectedProvince.value!];
    final List<dynamic>? rawDistricts =
        provinceData?['districts'] as List<dynamic>?;
    if (rawDistricts != null) {
      final selectedDistrictData = rawDistricts.firstWhere(
        (d) => d['name_th'] == newValue,
        orElse: () => null,
      );
      if (selectedDistrictData != null) {
        final List<dynamic>? rawSubdistricts =
            selectedDistrictData['sub_districts'] as List<dynamic>?;
        if (rawSubdistricts != null) {
          subdistricts.value = rawSubdistricts
              .map((sub) => sub['name_th'] as String? ?? '')
              .whereType<String>()
              .toList();
        }
      }
    }
  }

  void onSubDistrictChanged(String? newValue) {
    selectedSubDistrict.value = newValue;
  }

  void _resetDistrictAndSubdistrict() {
    selectedDistrict.value = null;
    selectedSubDistrict.value = null;
    districts.clear();
    subdistricts.clear();
  }

  void _resetSubdistrict() {
    selectedSubDistrict.value = null;
    subdistricts.clear();
  }

  // ==========================================
  //  ตรวจสอบข้อมูลก่อนไปตั้งรหัส (Validation)
  // ==========================================
  void validateAndGoToPin() {
    String phone = shopPhoneController.text.trim();

    if (shopNameController.text.trim().isEmpty ||
        phone.isEmpty ||
        addressController.text.trim().isEmpty ||
        selectedProvince.value == null ||
        profileImage.value == null ||
        qrImage.value == null) {
      _showErrorSnackbar(
        "ข้อมูลไม่ครบถ้วน",
        "กรุณากรอกข้อมูลและอัปโหลดรูปภาพให้ครบ",
      );
      return;
    }

    if (phone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      _showErrorSnackbar(
        "เบอร์โทรศัพท์ไม่ถูกต้อง",
        "กรุณากรอกเบอร์โทรศัพท์เป็นตัวเลข 10 หลัก",
      );
      return;
    }

    currentPin.value = "";
    firstPin = "";
    isConfirmPinStep.value = false;
    Get.to(() => const SetShopPinPage());
  }

  // ==========================================
  //  จัดการรหัส PIN (Numpad & Confirm)
  // ==========================================

  void confirmCurrentPin() {
    if (currentPin.value.length != 6) {
      Get.snackbar(
        "รหัส PIN ไม่ครบ",
        "กรุณากรอก PIN ให้ครบ 6 หลัก",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (!isConfirmPinStep.value) {
      firstPin = currentPin.value;
      currentPin.value = "";
      isConfirmPinStep.value = true;
    } else {
      if (currentPin.value == firstPin) {
        _showPinSuccessDialog(firstPin);
      } else {
        Get.snackbar(
          "รหัสไม่ตรงกัน",
          "กรุณาตั้งรหัสใหม่อีกครั้ง",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        currentPin.value = "";
        firstPin = "";
        isConfirmPinStep.value = false;
      }
    }
  }

  // ==========================================
  // ส่งข้อมูลขึ้นเซิร์ฟเวอร์
  // ==========================================
  Future<void> _submitAllDataToBackend(String confirmedPin) async {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    isLoading.value = true;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int userId = prefs.getInt('userId') ?? 0;

      if (userId == 0) {
        Get.back();
        Get.snackbar("ข้อผิดพลาด", "ไม่พบข้อมูลผู้ใช้");
        return;
      }

      final uploadService = ImageUploadService();
      String? shopImageUrl = await uploadService.uploadImage(
        profileImage.value!,
      );
      String? qrImageUrl = await uploadService.uploadImage(qrImage.value!);

      if (shopImageUrl == null || qrImageUrl == null) {
        Get.back();
        Get.snackbar("ผิดพลาด", "อัปโหลดรูปภาพไม่สำเร็จ");
        return;
      }

      String fullAddress =
          "${addressController.text} "
          "ต.${selectedSubDistrict.value ?? ''} "
          "อ.${selectedDistrict.value ?? ''} "
          "จ.${selectedProvince.value ?? ''}";

      ShopResponse request = ShopResponse(
        shopId: 0,
        userId: userId,
        name: shopNameController.text,
        phone: shopPhoneController.text,
        address: fullAddress,
        pinCode: confirmedPin,
        imgShop: shopImageUrl,
        imgQrcode: qrImageUrl,
      );

      bool isSuccess = await ApiShop().createShop(request);

      Get.back();
      isLoading.value = false;

      if (isSuccess) {
        await prefs.setString('shopName', shopNameController.text);
        _showShopCreatedSuccessDialog();
      } else {
        Get.snackbar("ล้มเหลว", "สร้างร้านค้าไม่สำเร็จ");
      }
    } catch (e) {
      Get.back();
      isLoading.value = false;
      print("Error submit: $e");
      Get.snackbar(
        "เกิดข้อผิดพลาด",
        friendlyError(
          e,
          fallback: "ไม่สามารถบันทึกข้อมูลร้านค้าได้ กรุณาลองใหม่อีกครั้ง",
        ),
      );
    }
  }

  // ==========================================
  // ส่วนของ Dialog (UI popups ย่อย)
  // ==========================================
  void _showErrorSnackbar(String title, String message) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 60,
              ),
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
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Get.back(),
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
      barrierDismissible: true,
    );
  }

  void _showPinSuccessDialog(String finalPin) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFFFDD835),
                size: 80,
              ),
              const SizedBox(height: 20),
              const Text(
                "ตั้งรหัส PIN สำเร็จ",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () {
                    Get.back();
                    _submitAllDataToBackend(finalPin);
                  },
                  child: const Text(
                    "ตกลง",
                    style: TextStyle(color: Colors.white),
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

  void _showShopCreatedSuccessDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDD835).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.check, color: Color(0xFFFDD835), size: 40),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "สมัครร้านค้าสำเร็จ",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8BC34A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'ชื่อร้าน: ${shopNameController.text}',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    Get.delete<HomeController>();
                    Get.offAll(() => const HomePage()); // วาร์ปเข้าร้าน!
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    "ตกลง",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
