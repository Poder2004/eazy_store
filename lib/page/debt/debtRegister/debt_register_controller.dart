import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
// --- Imports ไฟล์ของคุณ (ตรวจสอบ Path ให้ตรงกับโปรเจกต์ของคุณด้วยนะครับ) ---
import '../../../api/api_debtor.dart';
import '../../../api/api_service_image.dart';
import '../../../model/request/debtor_request.dart';
import '../../../model/response/debtor_response.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/image_picker_sheet.dart';
import 'package:eazy_store/utils/thai_sort.dart';

class DebtRegisterController extends GetxController {
  // --- Controllers สำหรับ TextFields ---
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressDetailController = TextEditingController();
  final creditLimitController = TextEditingController();

  // --- State Variables (ใช้ .obs เพื่อให้ UI อัปเดตอัตโนมัติ) ---
  // ใช้ XFile + bytes แทน File เพื่อให้ใช้งานได้ทั้งบนเว็บและมือถือ
  var imageFile = Rx<XFile?>(null);
  var imageBytes = Rx<Uint8List?>(null);
  final ImagePicker picker = ImagePicker();

  var selectedProvince = Rx<String?>(null);
  var selectedDistrict = Rx<String?>(null);
  var selectedSubdistrict = Rx<String?>(null);

  var fullAddressData = Rx<Map<String, dynamic>?>(null);
  var districts = <String>[].obs;
  var subdistricts = <String>[].obs;

  // ข้อความ error ของช่องเบอร์โทร แสดงสดขณะพิมพ์ (ไม่ใช่แค่ตอนกดบันทึก)
  var phoneError = Rx<String?>(null);

  // สีเดียวกับปุ่ม "บันทึกข้อมูลลูกหนี้" ในหน้า UI (เขียว) ให้ต่อเนื่องกับ
  // dialog ยืนยันและ loading spinner ตอนกดปุ่มนั้น
  final Color primaryColor = const Color(0xFF10B981);

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

      rawData.sort((a, b) {
        final nameA = a['name_th'] as String? ?? '';
        final nameB = b['name_th'] as String? ?? '';
        return thaiSortKey(nameA).compareTo(thaiSortKey(nameB));
      });

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
    final districtList = rawDistricts?.map((d) => d['name_th'] as String).toList() ?? [];
    districtList.sort((a, b) => thaiSortKey(a).compareTo(thaiSortKey(b)));
    districts.value = districtList;
  }

  void onDistrictChanged(String? newValue) {
    if (newValue == null) return;
    selectedDistrict.value = newValue;
    selectedSubdistrict.value = null;

    final provinceData = fullAddressData.value![selectedProvince.value!];
    final List<dynamic>? rawDistricts = provinceData?['districts'] as List<dynamic>?;
    if (rawDistricts == null) return;
    final selectedDistrictData = rawDistricts.firstWhere(
      (d) => d['name_th'] == newValue,
      orElse: () => null,
    );
    if (selectedDistrictData == null) return;
    final List<dynamic>? rawSubs = selectedDistrictData['sub_districts'] as List<dynamic>?;
    final subList = rawSubs?.map((s) => s['name_th'] as String).toList() ?? [];
    subList.sort((a, b) => thaiSortKey(a).compareTo(thaiSortKey(b)));
    subdistricts.value = subList;
  }

  // ตรวจเบอร์โทร: ต้องขึ้นต้นด้วย 0 และมีครบ 10 หลักเท่านั้น
  // คืนค่า null = ถูกต้อง (หรือยังพิมพ์ไม่ครบ/ว่างอยู่ ปล่อยให้ validateForm
  // ตอน submit เป็นคนเตือนแทน ไม่ต้องขึ้น error สีแดงกวนตาระหว่างพิมพ์)
  String? _phoneValidationMessage(String phone) {
    if (phone.isEmpty) return null;
    if (!phone.startsWith('0')) return 'เบอร์โทรต้องขึ้นต้นด้วยเลข 0';
    if (phone.length != 10) return 'เบอร์โทรต้องมี 10 หลัก (ตอนนี้ ${phone.length} หลัก)';
    return null;
  }

  void onPhoneChanged(String value) {
    phoneError.value = _phoneValidationMessage(value.trim());
  }

  void showImagePickerOptions() {
    ImagePickerSheet.show(
      title: "เลือกรูปภาพลูกหนี้",
      onImagePicked: (source) {
        pickImage(source);
      },
    );
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
        // อ่านเป็น bytes เพื่อให้แสดงตัวอย่างรูปและอัปโหลดได้ทั้งบนเว็บและมือถือ
        imageBytes.value = await pickedFile.readAsBytes();
        imageFile.value = pickedFile;
      }
    } catch (e) {
      debugPrint("เลือกรูปภาพไม่สำเร็จ: $e");
      Get.snackbar(
        "เลือกรูปภาพไม่สำเร็จ",
        "ไม่สามารถเปิดรูปภาพที่เลือกได้ กรุณาลองใหม่อีกครั้ง",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // แจ้งเตือนแบบข้อมูลไม่ครบถ้วน (สีส้ม)
  void _showWarning(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
  }

  // แจ้งเตือนข้อผิดพลาด (สีแดง)
  void _showError(String message, {String title = "เกิดข้อผิดพลาด"}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  /// 📌 ตรวจสอบว่ากรอกข้อมูลครบถ้วนหรือยัง (ชื่อ / เบอร์โทร / ที่อยู่ / วงเงิน / รูปภาพ)
  /// คืนค่า true เมื่อข้อมูลครบและถูกต้อง
  bool validateForm() {
    // 1) รูปภาพลูกหนี้
    if (imageFile.value == null || imageBytes.value == null) {
      _showWarning("ข้อมูลไม่ครบถ้วน", "กรุณาเพิ่มรูปภาพลูกหนี้");
      return false;
    }

    // 2) ชื่อคนค้างชำระ
    final name = nameController.text.trim();
    if (name.isEmpty) {
      _showWarning("ข้อมูลไม่ครบถ้วน", "กรุณากรอกชื่อคนค้างชำระ");
      return false;
    }
    if (name.length < 2) {
      _showWarning("ชื่อไม่ถูกต้อง", "ชื่อคนค้างชำระต้องมีอย่างน้อย 2 ตัวอักษร");
      return false;
    }

    // 3) เบอร์โทรศัพท์ (ต้องขึ้นต้นด้วย 0 และครบ 10 หลักเท่านั้น)
    final phone = phoneController.text.trim();
    if (phone.isEmpty) {
      phoneError.value = null;
      _showWarning("ข้อมูลไม่ครบถ้วน", "กรุณากรอกเบอร์โทรศัพท์");
      return false;
    }
    final phoneMsg = _phoneValidationMessage(phone);
    if (phoneMsg != null) {
      phoneError.value = phoneMsg;
      _showWarning("เบอร์โทรไม่ถูกต้อง", phoneMsg);
      return false;
    }
    phoneError.value = null;

    // 4) ที่อยู่ (จังหวัด / อำเภอ / ตำบล / รายละเอียด)
    if (selectedProvince.value == null) {
      _showWarning("ข้อมูลไม่ครบถ้วน", "กรุณาเลือกจังหวัด");
      return false;
    }
    if (selectedDistrict.value == null) {
      _showWarning("ข้อมูลไม่ครบถ้วน", "กรุณาเลือกอำเภอ/เขต");
      return false;
    }
    if (selectedSubdistrict.value == null) {
      _showWarning("ข้อมูลไม่ครบถ้วน", "กรุณาเลือกตำบล/แขวง");
      return false;
    }
    if (addressDetailController.text.trim().isEmpty) {
      _showWarning("ข้อมูลไม่ครบถ้วน", "กรุณากรอกบ้านเลขที่/ซอย/ถนน");
      return false;
    }

    // 5) วงเงินค้างชำระ
    final creditText = creditLimitController.text.trim();
    if (creditText.isEmpty) {
      _showWarning("ข้อมูลไม่ครบถ้วน", "กรุณากรอกวงเงินค้างชำระ");
      return false;
    }
    final credit = double.tryParse(creditText);
    if (credit == null) {
      _showWarning("วงเงินไม่ถูกต้อง", "กรุณากรอกวงเงินค้างชำระเป็นตัวเลข");
      return false;
    }
    if (credit <= 0) {
      _showWarning("วงเงินไม่ถูกต้อง", "วงเงินค้างชำระต้องมากกว่า 0 บาท");
      return false;
    }

    return true;
  }

  // 📌 4. Logic การส่งข้อมูลไป API
  Future<void> submitDebtorData() async {
    if (!validateForm()) return;

    // ให้ยืนยันอีกครั้งก่อนบันทึกจริง กันกดพลาด/กดรัวจนสร้างลูกหนี้ซ้ำ
    ConfirmDialog.show(
      title: 'ยืนยันบันทึกข้อมูลลูกหนี้',
      message:
          'ต้องการบันทึกข้อมูลลูกหนี้ "${nameController.text.trim()}" '
          'ใช่หรือไม่?',
      icon: Icons.person_add_alt_1_rounded,
      iconColor: primaryColor,
      confirmLabel: 'บันทึก',
      confirmColor: primaryColor,
      onConfirm: _performSubmit,
    );
  }

  Future<void> _performSubmit() async {
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
        _showError("ไม่พบข้อมูลร้านค้า กรุณาเข้าสู่ระบบใหม่อีกครั้ง");
        return;
      }

      // อัปโหลดรูปภาพ (ผ่านการตรวจสอบจาก validateForm มาแล้วว่ามีรูปแน่นอน)
      final uploadService = ImageUploadService();
      final String? uploadedUrl = await uploadService.uploadBytes(
        imageBytes.value!,
        fileName: imageFile.value!.name,
      );

      if (uploadedUrl == null) {
        Get.back(); // ปิด loading
        _showError(
          "อัปโหลดรูปภาพไม่สำเร็จ กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่อีกครั้ง",
        );
        return;
      }

      String fullAddress = "${addressDetailController.text.trim()} "
          "ต.${selectedSubdistrict.value} "
          "อ.${selectedDistrict.value} "
          "จ.${selectedProvince.value}";

      DebtorRequest newDebtor = DebtorRequest(
        shopId: shopId,
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        address: fullAddress,
        imgDebtor: uploadedUrl,
        creditLimit: double.tryParse(creditLimitController.text.trim()) ?? 0.0,
        currentDebt: 0.0,
      );

      var result = await ApiDebtor.createDebtor(newDebtor);

      Get.back(); // ปิด Loading

      if (result['success'] == true) {
        // ข้อมูลลูกหนี้ที่เพิ่งสร้าง (มี debtor_id จากเซิร์ฟเวอร์แล้ว)
        final DebtorResponse? createdDebtor = result['data'] is DebtorResponse
            ? result['data'] as DebtorResponse
            : null;

        // ปิด Snackbar ที่ค้างอยู่ก่อน ไม่งั้น Get.back() จะไปปิด Snackbar แทนการปิดหน้าจอ
        // (สาเหตุที่เดิมกดเพิ่มลูกหนี้แล้วหน้าไม่เด้งกลับ)
        Get.closeAllSnackbars();

        // ส่งข้อมูลลูกหนี้กลับไปให้หน้าที่เรียกใช้ (เช่น หน้าบันทึกค้างชำระ) เลือกอัตโนมัติ
        Get.back(result: createdDebtor);

        Get.snackbar(
          "สำเร็จ",
          result['message'] ?? "บันทึกข้อมูลลูกหนี้เรียบร้อยแล้ว",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        _showError(
          result['message'] ?? "ไม่สามารถบันทึกข้อมูลลูกหนี้ได้ กรุณาลองใหม่",
          title: "บันทึกไม่สำเร็จ",
        );
      }
    } catch (e) {
      Get.back(); // ปิด Loading
      debugPrint("เพิ่มลูกหนี้ไม่สำเร็จ: $e");
      _showError("ไม่สามารถบันทึกข้อมูลลูกหนี้ได้ กรุณาลองใหม่อีกครั้ง");
    }
  }
}