import 'package:eazy_store/homepage/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
// import 'package:eazy_store/homepage/home_page.dart'; // สมมติว่ามีหน้านี้อยู่
import '../model/request/create_shop_request.dart';
import '../api/api_shop.dart';
import '../shop/myshop.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../shop/set_shop_pin_page.dart';
import '../api/api_service_image.dart';

class CreateShopController extends GetxController {
  // --- Input Controllers ---
  final shopNameController = TextEditingController();
  final shopPhoneController = TextEditingController();
  final addressController = TextEditingController();
  final zipCodeController = TextEditingController();
  
  var isLoading = false.obs;

  // --- Image Picker ---
  final ImagePicker _picker = ImagePicker();
  Rx<File?> profileImage = Rx<File?>(null); // shopImage
  Rx<File?> qrImage = Rx<File?>(null);

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
      Get.snackbar("เกิดข้อผิดพลาด", "ไม่สามารถเลือกรูปภาพได้");
    }
  }

  // --- Address Logic ---
  final selectedProvince = Rx<String?>(null);
  final selectedDistrict = Rx<String?>(null);
  final selectedSubDistrict = Rx<String?>(null);
  Map<String, dynamic>? _fullAddressData;
  final provinces = <String>[].obs;
  final districts = <String>[].obs;
  final subdistricts = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadAddressData();
  }

  Future<void> _loadAddressData() async {
    try {
      const assetPath = 'assets/data_address/province_with_district_and_sub_district.json';
      final String response = await rootBundle.loadString(assetPath);
      final List<dynamic> rawData = jsonDecode(response);
      final Map<String, dynamic> structuredData = {};
      for (var province in rawData) {
        String provinceName = province['name_th'] as String? ?? 'ไม่ระบุจังหวัด';
        structuredData[provinceName] = province;
      }
      _fullAddressData = structuredData;
      provinces.value = _fullAddressData!.keys.toList();
    } catch (e) {
      print("Error load address: $e");
    }
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

  void onProvinceChanged(String? newValue) {
    if (newValue == null || _fullAddressData == null) {
      _resetDistrictAndSubdistrict();
      return;
    }
    selectedProvince.value = newValue;
    _resetDistrictAndSubdistrict();
    final provinceData = _fullAddressData![newValue];
    final List<dynamic>? rawDistricts = provinceData?['districts'] as List<dynamic>?;
    if (rawDistricts != null) {
      districts.value = rawDistricts
          .map((district) => district['name_th'] as String? ?? '')
          .whereType<String>().toList();
    }
  }

  void onDistrictChanged(String? newValue) {
    if (newValue == null || selectedProvince.value == null || _fullAddressData == null) {
      _resetSubdistrict();
      return;
    }
    selectedDistrict.value = newValue;
    _resetSubdistrict();
    final provinceData = _fullAddressData![selectedProvince.value!];
    final List<dynamic>? rawDistricts = provinceData?['districts'] as List<dynamic>?;
    if (rawDistricts != null) {
      final selectedDistrictData = rawDistricts.firstWhere((d) => d['name_th'] == newValue, orElse: () => null);
      if (selectedDistrictData != null) {
        final List<dynamic>? rawSubdistricts = selectedDistrictData['sub_districts'] as List<dynamic>?;
        if (rawSubdistricts != null) {
          subdistricts.value = rawSubdistricts
              .map((sub) => sub['name_th'] as String? ?? '')
              .whereType<String>().toList();
        }
      }
    }
  }
  
  void onSubDistrictChanged(String? newValue) {
    selectedSubDistrict.value = newValue;
  }

  // =========================================================
  // 🔥 ส่วนที่เพิ่มใหม่: Logic การจัดการ PIN และ Validate
  // =========================================================

  var currentPin = "".obs;        // PIN ที่กำลังพิมพ์
  var isConfirmPinStep = false.obs; // อยู่หน้ายืนยันไหม?
  String firstPin = "";           // PIN รอบแรก

  // 1. ฟังก์ชัน Validate ก่อนไปหน้า PIN
  void validateAndGoToPin() {
    if (shopNameController.text.isEmpty ||
        shopPhoneController.text.isEmpty ||
        addressController.text.isEmpty ||
        selectedProvince.value == null ||
        profileImage.value == null || 
        qrImage.value == null) {
      
      Get.snackbar(
        "ข้อมูลไม่ครบถ้วน",
        "กรุณากรอกข้อมูลและอัปโหลดรูปภาพให้ครบ",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    // เคลียร์ค่า PIN เก่า และไปหน้า SetShopPinPage
    currentPin.value = "";
    firstPin = "";
    isConfirmPinStep.value = false;
    Get.to(() => const SetShopPinPage());
  }

  // 2. Logic Numpad
  void addPinDigit(String digit) {
    if (currentPin.value.length < 6) {
      currentPin.value += digit;
    }
  }

  void deletePinDigit() {
    if (currentPin.value.isNotEmpty) {
      currentPin.value = currentPin.value.substring(0, currentPin.value.length - 1);
    }
  }

  // 3. Logic ยืนยัน PIN
  void confirmCurrentPin() {
    if (currentPin.value.length != 6) return;

    if (!isConfirmPinStep.value) {
      // จบรอบแรก
      firstPin = currentPin.value;
      currentPin.value = "";
      isConfirmPinStep.value = true;
    } else {
      // จบรอบสอง (ยืนยัน)
      if (currentPin.value == firstPin) {
        // PIN ตรงกัน -> แสดง Dialog สำเร็จ -> ส่งข้อมูล
        _showPinSuccessDialog(firstPin);
      } else {
        // PIN ไม่ตรง
        Get.snackbar("รหัสไม่ตรงกัน", "กรุณาตั้งรหัสใหม่อีกครั้ง", backgroundColor: Colors.red, colorText: Colors.white);
        currentPin.value = "";
        firstPin = "";
        isConfirmPinStep.value = false;
      }
    }
  }

  // Dialog ตั้ง PIN สำเร็จ
  void _showPinSuccessDialog(String finalPin) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFFFDD835), size: 80),
              const SizedBox(height: 20),
              const Text("ตั้งรหัส PIN สำเร็จ", 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: const StadiumBorder()),
                  onPressed: () {
                    Get.back(); // ปิด Dialog PIN
                    // 🔥 เริ่มส่งข้อมูลทั้งหมดเข้า Backend
                    _submitAllDataToBackend(finalPin);
                  },
                  child: const Text("ตกลง", style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // 4. ฟังก์ชันส่งข้อมูลจริง (ย้ายมาจาก submitShopInfo เดิม)
  Future<void> _submitAllDataToBackend(String confirmedPin) async {
    // แสดง Loading
    Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    isLoading.value = true;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int userId = prefs.getInt('userId') ?? 0;

      if (userId == 0) {
        Get.back();
        Get.snackbar("ข้อผิดพลาด", "ไม่พบข้อมูลผู้ใช้");
        return;
      }

      // --- Upload Images (แนะนำใช้ Cloudinary ตามที่คุยกัน) ---
      final uploadService = ImageUploadService();
      String? shopImageUrl = await uploadService.uploadImage(profileImage.value!);
      String? qrImageUrl = await uploadService.uploadImage(qrImage.value!);

      if (shopImageUrl == null || qrImageUrl == null) {
        Get.back();
        Get.snackbar("ผิดพลาด", "อัปโหลดรูปภาพไม่สำเร็จ");
        return;
      }

      // --- เตรียมที่อยู่ ---
      String fullAddress = "${addressController.text} "
          "ต.${selectedSubDistrict.value ?? ''} "
          "อ.${selectedDistrict.value ?? ''} "
          "จ.${selectedProvince.value ?? ''} "
          "${zipCodeController.text}";

      // --- สร้าง Request (ใส่ PIN ที่ได้มา) ---
      CreateShopRequest request = CreateShopRequest(
        userId: userId,
        name: shopNameController.text,
        phone: shopPhoneController.text,
        address: fullAddress,
        pinCode: confirmedPin, // ✅ ใช้ PIN ที่ User ตั้ง
        imgShop: shopImageUrl,
        imgQrcode: qrImageUrl,
      );

      // --- เรียก API ---
      bool isSuccess = await ApiShop().createShop(request);

      Get.back(); // ปิด Loading
      isLoading.value = false;

      if (isSuccess) {
        _showShopCreatedSuccessDialog();
      } else {
        Get.snackbar("ล้มเหลว", "สร้างร้านค้าไม่สำเร็จ");
      }

    } catch (e) {
      Get.back();
      isLoading.value = false;
      print("Error submit: $e");
      Get.snackbar("เกิดข้อผิดพลาด", "$e");
    }
  }

  void _showShopCreatedSuccessDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 80, width: 80,
                decoration: BoxDecoration(color: const Color(0xFFFDD835).withOpacity(0.2), shape: BoxShape.circle),
                child: const Center(child: Icon(Icons.check, color: Color(0xFFFDD835), size: 40)),
              ),
              const SizedBox(height: 20),
              const Text("สมัครร้านค้าสำเร็จ", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF8BC34A))),
              const SizedBox(height: 10),
              Text('ชื่อร้าน: ${shopNameController.text}', style: const TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    Get.offAll(() => const HomePage());
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                  child: const Text("ตกลง", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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


class CreateShopPage extends StatelessWidget {
  const CreateShopPage({super.key});

  // --- ✨ ฟังก์ชันแสดง Popup เลือกรูปภาพแบบใหม่ (สวยงามขึ้น) ---
  void _showImagePickerOptions(
    BuildContext context,
    CreateShopController controller, {
    required bool isProfile,
  }) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: 40,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(30),
          ), // มุมโค้งมนสวยๆ
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ขีดเล็กๆ ด้านบนเพื่อให้รู้ว่ารูดลงได้
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 25),

            const Text(
              "เลือกรูปภาพ",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // ปุ่มเลือก 2 อันเรียงกัน (กล้อง - อัลบั้ม)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 1. ปุ่มถ่ายภาพ
                _buildPickerButton(
                  icon: Icons.camera_alt_rounded,
                  label: "ถ่ายภาพ",
                  color: Colors.blueAccent,
                  onTap: () {
                    Get.back();
                    controller.pickImage(
                      ImageSource.camera,
                      isProfile: isProfile,
                    );
                  },
                ),

                // 2. ปุ่มเลือกจากอัลบั้ม
                _buildPickerButton(
                  icon: Icons.photo_library_rounded,
                  label: "คลังรูปภาพ",
                  color: Colors.purpleAccent,
                  onTap: () {
                    Get.back();
                    controller.pickImage(
                      ImageSource.gallery,
                      isProfile: isProfile,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent, // ให้พื้นหลังใสเพื่อโชว์มุมโค้ง
      isScrollControlled: true,
    );
  }

  // Widget สร้างปุ่มเลือกรูป (วงกลมสีๆ + ไอคอน + ข้อความ)
  Widget _buildPickerButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1), // สีพื้นหลังจางๆ
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 35, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ใช้ Get.put เพื่อสร้าง Controller และทำให้เข้าถึงได้
    // (ใช้ Get.find() ใน BuildContext หรือ Get.put() ก่อนหน้านี้)
    // การเรียก Get.put ใน Build method อาจทำให้เกิดการสร้างใหม่
    // แต่เพื่อความง่ายในตัวอย่างนี้ เราจะคงไว้ตามโค้ดเดิม
    final CreateShopController controller = Get.put(CreateShopController());
    final Color primaryGreen = const Color(0xFF00C853);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "ข้อมูลร้านค้า",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // --- 1. Profile Image Picker ---
              const Text(
                "โปรไฟล์",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Center(
                child: GestureDetector(
                  onTap: () => _showImagePickerOptions(
                    context,
                    controller,
                    isProfile: true,
                  ),
                  child: Obx(
                    () => Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                        image: controller.profileImage.value != null
                            ? DecorationImage(
                                image: FileImage(
                                  controller.profileImage.value!,
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: controller.profileImage.value == null
                          ? Icon(
                              Icons.camera_alt,
                              color: Colors.grey[600],
                              size: 40,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // --- Inputs ---
              _buildLineInput(
                label: "ชื่อร้านค้า",
                hint: "ชื่อร้านค้า",
                controller: controller.shopNameController,
              ),

              _buildLineInput(
                label: "เบอร์ร้าน",
                hint: "เบอร์ร้าน",
                controller: controller.shopPhoneController,
                inputType: TextInputType.phone,
              ),

              const SizedBox(height: 20),
              
              // ----------------------------------------------------
              // ➡️ 4. ส่วน Dropdown ที่อยู่ (ใหม่)
              // ----------------------------------------------------
              const Text(
                "ที่อยู่ร้าน",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF333333)),
              ),
              
              // Dropdown จังหวัด
              Obx(() => _buildAddressDropdown<String>(
                hint: 'จังหวัด',
                selectedValue: controller.selectedProvince.value,
                items: controller.provinces.toList(), // แปลง RxList เป็น List
                onChanged: controller.onProvinceChanged,
                disabled: controller.provinces.isEmpty,
              )),

              // Dropdown อำเภอ
              Obx(() => _buildAddressDropdown<String>(
                hint: 'อำเภอ',
                selectedValue: controller.selectedDistrict.value,
                items: controller.districts.toList(), // แปลง RxList เป็น List
                onChanged: controller.onDistrictChanged,
                // Disabled ถ้ายังไม่เลือกจังหวัด หรือไม่มีรายการอำเภอ
                disabled: controller.selectedProvince.value == null || controller.districts.isEmpty,
              )),

              // Dropdown ตำบล
              Obx(() => _buildAddressDropdown<String>(
                hint: 'ตำบล',
                selectedValue: controller.selectedSubDistrict.value,
                items: controller.subdistricts.toList(), // แปลง RxList เป็น List
                onChanged: controller.onSubDistrictChanged,
                // Disabled ถ้ายังไม่เลือกอำเภอ หรือไม่มีรายการตำบล
                disabled: controller.selectedDistrict.value == null || controller.subdistricts.isEmpty,
              )),

              // บ้านเลขที่
              _buildLineInput(
                label: "",
                hint: "บ้านเลขที่ หมู่ที่",
                controller: controller.addressController,
                noLabel: true,
              ),
              // ----------------------------------------------------
              // ⬅️ สิ้นสุดส่วน Dropdown ที่อยู่
              // ----------------------------------------------------

              const SizedBox(height: 20),

              // --- 2. Upload QR Section ---
              const Text(
                "ลิงก์ภาพ QR สำหรับลูกค้าชำระเงินโอน",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),

              GestureDetector(
                onTap: () => _showImagePickerOptions(
                  context,
                  controller,
                  isProfile: false,
                ),
                child: Container(
                  width: 150,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      "อัพโหลดภาพ QR",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),
              Obx(() {
                if (controller.qrImage.value != null) {
                  return Stack(
                    children: [
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: FileImage(controller.qrImage.value!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 5,
                        top: 5,
                        child: GestureDetector(
                          onTap: () => controller.qrImage.value = null,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),

              const SizedBox(height: 40),

              // ปุ่มดำเนินการต่อ
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: controller.validateAndGoToPin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    "ดำเนินการต่อ",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType inputType = TextInputType.text,
    bool noLabel = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!noLabel) ...[
          const SizedBox(height: 20),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
        TextField(
          controller: controller,
          keyboardType: inputType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: const Color(0xFF00C853).withOpacity(0.3)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF00C853)),
            ),
          ),
        ),
      ],
    );
  }

  // Helper Widget สำหรับ Dropdown ที่อยู่
  Widget _buildAddressDropdown<T>({
    required String hint,
    required T? selectedValue,
    required List<T> items, // เปลี่ยนเป็น List<T> ธรรมดา
    required void Function(T?) onChanged,
    required bool disabled,
  }) {
    final Color primaryGreen = const Color(0xFF00C853);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: DropdownButtonFormField<T>(
        value: selectedValue,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: primaryGreen.withOpacity(0.3)),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: primaryGreen),
          ),
          disabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        isExpanded: true,
        icon: Icon(Icons.keyboard_arrow_down, color: disabled ? Colors.grey[300] : primaryGreen),
        style: TextStyle(color: disabled ? Colors.grey : Colors.black, fontSize: 16),
        dropdownColor: Colors.white,
        // ถ้า disabled ให้เป็น null เพื่อไม่ให้เลือกได้
        onChanged: disabled ? null : onChanged, 
        items: items.isEmpty
            ? null // ถ้าไม่มีรายการ ให้ items เป็น null เพื่อไม่ให้เกิด error
            : items.map((T value) {
                return DropdownMenuItem<T>(
                  value: value,
                  child: Text(value.toString()),
                );
              }).toList(),
      ),
    );
  }
}
