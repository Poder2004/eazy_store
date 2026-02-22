import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Imports ไฟล์ของคุณ (ตรวจสอบ Path ให้ตรงกับโปรเจกต์ของคุณด้วยนะครับ) ---
import '../../../api/api_debtor.dart';
import '../../../api/api_service_image.dart';
import '../../../model/request/debtor_request.dart';

class DebtRegisterController extends GetxController {
  // --- Controllers สำหรับ TextFields ---
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressDetailController = TextEditingController();
  final creditLimitController = TextEditingController();

  // --- State Variables (ใช้ .obs เพื่อให้ UI อัปเดตอัตโนมัติ) ---
  var imageFile = Rx<File?>(null);
  final ImagePicker picker = ImagePicker();

  var selectedProvince = Rx<String?>(null);
  var selectedDistrict = Rx<String?>(null);
  var selectedSubdistrict = Rx<String?>(null);

  var fullAddressData = Rx<Map<String, dynamic>?>(null);
  var districts = <String>[].obs;
  var subdistricts = <String>[].obs;

  final Color primaryColor = const Color(0xFF6B8E23);

  @override
  void onInit() {
    super.onInit();
    loadAddressData(); // โหลดข้อมูลที่อยู่เมื่อ Controller ถูกสร้าง
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    addressDetailController.dispose();
    creditLimitController.dispose();
    super.onClose();
  }

  // 📌 1. Logic การโหลดข้อมูลที่อยู่
  Future<void> loadAddressData() async {
    try {
      const assetPath = 'assets/data_address/province_with_district_and_sub_district.json';
      final String response = await rootBundle.loadString(assetPath);
      final List<dynamic> rawData = jsonDecode(response);

      final Map<String, dynamic> structuredData = {};
      for (var province in rawData) {
        String provinceName = province['name_th'] as String? ?? 'ไม่ระบุจังหวัด';
        structuredData[provinceName] = province;
      }
      fullAddressData.value = structuredData;
    } catch (e) {
      debugPrint("🚨 Error loading address data: $e");
      fullAddressData.value = {};
    }
  }

  // 📌 2. Logic Cascading สำหรับที่อยู่
  void onProvinceChanged(String? newValue) {
    if (newValue == null) return;
    selectedProvince.value = newValue;
    selectedDistrict.value = null;
    selectedSubdistrict.value = null;
    subdistricts.clear();

    final provinceData = fullAddressData.value![newValue];
    final List<dynamic>? rawDistricts = provinceData?['districts'] as List<dynamic>?;
    districts.value = rawDistricts?.map((d) => d['name_th'] as String).toList() ?? [];
  }

  void onDistrictChanged(String? newValue) {
    if (newValue == null) return;
    selectedDistrict.value = newValue;
    selectedSubdistrict.value = null;

    final provinceData = fullAddressData.value![selectedProvince.value!];
    final List<dynamic> rawDistricts = provinceData?['districts'];
    final selectedDistrictData = rawDistricts.firstWhere((d) => d['name_th'] == newValue);
    final List<dynamic>? rawSubs = selectedDistrictData['sub_districts'] as List<dynamic>?;
    subdistricts.value = rawSubs?.map((s) => s['name_th'] as String).toList() ?? [];
  }

  // 📌 3. Logic เลือกรูปภาพ
  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        imageFile.value = File(pickedFile.path);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // 📌 4. Logic การส่งข้อมูลไป API
  Future<void> submitDebtorData() async {
    if (nameController.text.isEmpty || phoneController.text.isEmpty) {
      Get.snackbar("แจ้งเตือน", "กรุณากรอกชื่อและเบอร์โทรศัพท์",
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    // แสดง Loading
    Get.dialog(
      Center(child: CircularProgressIndicator(color: primaryColor)),
      barrierDismissible: false,
    );

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;

      if (shopId == 0) {
        Get.back(); // ปิด Loading
        Get.snackbar("ผิดพลาด", "ไม่พบข้อมูลร้านค้า กรุณาล็อกอินใหม่",
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      String imageUrl = "";

      if (imageFile.value != null) {
        final uploadService = ImageUploadService();
        String? uploadedUrl = await uploadService.uploadImage(imageFile.value!);

        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        } else {
          Get.back(); // ปิด loading
          Get.snackbar("ผิดพลาด", "ไม่สามารถอัปโหลดรูปภาพได้ กรุณาลองใหม่",
              backgroundColor: Colors.red, colorText: Colors.white);
          return;
        }
      }

      String fullAddress = "${addressDetailController.text} "
          "ต.${selectedSubdistrict.value ?? '-'} "
          "อ.${selectedDistrict.value ?? '-'} "
          "จ.${selectedProvince.value ?? '-'}";

      DebtorRequest newDebtor = DebtorRequest(
        shopId: shopId,
        name: nameController.text,
        phone: phoneController.text,
        address: fullAddress,
        imgDebtor: imageUrl,
        creditLimit: double.tryParse(creditLimitController.text) ?? 0.0,
        currentDebt: 0.0,
      );

      var result = await ApiDebtor.createDebtor(newDebtor);

      Get.back(); // ปิด Loading

      if (result['success']) {
        Get.snackbar("สำเร็จ", result['message'],
            backgroundColor: Colors.green, colorText: Colors.white);

        Future.delayed(const Duration(seconds: 1), () {
          Get.back(); // ปิดหน้าจอเมื่อสำเร็จ
        });
      } else {
        Get.snackbar("ผิดพลาด", result['message'],
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      Get.back(); // ปิด Loading
      Get.snackbar("Error", "เกิดข้อผิดพลาด: $e",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}