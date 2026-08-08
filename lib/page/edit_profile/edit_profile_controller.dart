import 'package:eazy_store/api/api_user.dart';
import 'package:eazy_store/page/auth/verify_register.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileController extends GetxController {
  var isLoading = false.obs;

  late TextEditingController usernameCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController passwordCtrl;

  var initialEmail = "".obs;

  // ✨ เพิ่มตัวแปรสำหรับเปิด-ปิดตา (ซ่อนรหัสผ่าน)
  var isPasswordHidden = true.obs;

  // ✨ ข้อความแจ้งเตือนแบบ real-time ใต้ช่องกรอกแต่ละช่อง (ว่าง = ไม่มีปัญหา)
  var phoneError = "".obs;
  var emailError = "".obs;
  var passwordError = "".obs;

  @override
  void onInit() {
    super.onInit();
    usernameCtrl = TextEditingController();
    emailCtrl = TextEditingController();
    phoneCtrl = TextEditingController();
    passwordCtrl = TextEditingController();
    phoneCtrl.addListener(_validatePhone);
    emailCtrl.addListener(_validateEmail);
    passwordCtrl.addListener(_validatePassword);
    _loadInitialData();
  }

  @override
  void onClose() {
    phoneCtrl.removeListener(_validatePhone);
    emailCtrl.removeListener(_validateEmail);
    passwordCtrl.removeListener(_validatePassword);
    usernameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }

  void _validatePhone() {
    final v = phoneCtrl.text.trim();
    phoneError.value = (v.isNotEmpty && v.length != 10) ? "ยังไม่ครบ 10 หลัก" : "";
  }

  void _validateEmail() {
    final v = emailCtrl.text.trim();
    emailError.value = (v.isNotEmpty && !GetUtils.isEmail(v)) ? "รูปแบบอีเมลไม่ถูกต้อง" : "";
  }

  void _validatePassword() {
    final v = passwordCtrl.text;
    passwordError.value = (v.isNotEmpty && v.length <= 6) ? "รหัสผ่านต้องมากกว่า 6 ตัวอักษร" : "";
  }

  Future<void> _loadInitialData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    usernameCtrl.text = prefs.getString('username') ?? '';
    emailCtrl.text = prefs.getString('email') ?? '';
    phoneCtrl.text = prefs.getString('phone') ?? '';
    initialEmail.value = emailCtrl.text;
  }

  // ✨ ฟังก์ชันเปิด-ปิดตา
  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  // ฟังก์ชันสำหรับเรียก Popup แจ้งเตือนสวยหรู
  void _showPremiumDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    VoidCallback? onConfirm,
  }) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 45),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey.shade500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: onConfirm ?? () => Get.back(),
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

  // ✨ 1. เพิ่มฟังก์ชันถามยืนยันก่อน Save
  void confirmSaveProfile() {
    // สั่งตรวจซ้ำอีกครั้งตอนกดบันทึก เผื่อ error ใต้ช่องยังไม่ทันอัปเดต
    _validatePhone();
    _validateEmail();
    _validatePassword();

    // เช็คค่าว่างก่อนถามยืนยัน
    if (usernameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) {
      _showPremiumDialog(
        title: "ข้อมูลไม่ครบ",
        message: "กรุณากรอกชื่อผู้ใช้งานและอีเมลให้ครบถ้วน",
        icon: Icons.warning_rounded,
        color: const Color(0xFFF59E0B),
      );
      return;
    }

    if (emailError.value.isNotEmpty) {
      _showPremiumDialog(
        title: "อีเมลไม่ถูกต้อง",
        message: "กรุณากรอกอีเมลให้ถูกต้อง",
        icon: Icons.warning_rounded,
        color: const Color(0xFFF59E0B),
      );
      return;
    }

    if (phoneError.value.isNotEmpty) {
      _showPremiumDialog(
        title: "เบอร์โทรไม่ถูกต้อง",
        message: "เบอร์โทรต้องมี 10 หลัก",
        icon: Icons.warning_rounded,
        color: const Color(0xFFF59E0B),
      );
      return;
    }

    if (passwordError.value.isNotEmpty) {
      _showPremiumDialog(
        title: "รหัสผ่านสั้นเกินไป",
        message: "รหัสผ่านต้องมากกว่า 6 ตัวอักษร",
        icon: Icons.shield_outlined,
        color: const Color(0xFFF59E0B),
      );
      return;
    }

    // โชว์ Dialog ถามความแน่ใจ
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  color: Color(0xFF4F46E5),
                  size: 45,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "ยืนยันการบันทึก",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "คุณตรวจสอบความถูกต้อง\nของข้อมูลครบถ้วนแล้วใช่หรือไม่?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey.shade500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      onPressed: () => Get.back(),
                      child: const Text(
                        "ตรวจสอบใหม่",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Get.back(); // ปิด Dialog ถาม
                        saveProfile(); // ✨ เรียกฟังก์ชันบันทึกจริง
                      },
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

  // ฟังก์ชันบันทึกจริง
  Future<void> saveProfile() async {
    isLoading.value = true;

    Map<String, dynamic> updateData = {
      'username': usernameCtrl.text.trim(),
      'email': emailCtrl.text.trim(),
      'phone': phoneCtrl.text.trim(),
    };

    if (passwordCtrl.text.isNotEmpty) {
      updateData['password'] = passwordCtrl.text;
    }

    final response = await ApiUser.updateProfile(updateData);
    isLoading.value = false;

    if (response['success'] == true) {
      if (response['require_auth'] == true) {
        _showPremiumDialog(
          title: "อัปเดตอีเมลใหม่",
          message:
              "ระบบได้ส่งรหัส OTP ไปยังอีเมลใหม่ของคุณแล้ว\nกรุณายืนยันตัวตนเพื่อเปิดใช้งาน",
          icon: Icons.mark_email_read_rounded,
          color: const Color(0xFF0288D1),
          onConfirm: () {
            Get.back();
            Get.off(
              () => const VerifyRegistrationPage(),
              arguments: {
                'email': emailCtrl.text.trim(),
                'username': usernameCtrl.text.trim(),
              },
            );
          },
        );
      } else {
        _showPremiumDialog(
          title: "บันทึกสำเร็จ",
          message: "อัปเดตข้อมูลส่วนตัวของคุณเรียบร้อยแล้ว",
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF10B981),
          onConfirm: () {
            Get.back();
            Get.back(result: true);
          },
        );
      }
    } else {
      _showPremiumDialog(
        title: "เกิดข้อผิดพลาด",
        message: response['error'] ?? "ไม่สามารถบันทึกข้อมูลได้",
        icon: Icons.error_outline_rounded,
        color: const Color(0xFFE11D48),
      );
    }
  }
}
