import 'package:eazy_store/auth/verify_otp_page.dart';
import 'package:flutter/material.dart';
import 'package:eazy_store/api/api_service.dart';
import 'package:eazy_store/model/request/reset_request.dart';
import 'package:get/get.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  // สีธีมหลักของแอป
  final Color _primaryColor = const Color(0xFF6200EE);

  // --- ฟังก์ชันแสดง Popup แทน Snackbar ---
  void _showPopup({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    VoidCallback? onConfirm,
  }) {
    Get.defaultDialog(
      title: "", // ซ่อนหัวข้อมาตรฐานเพื่อออกแบบเองใน content
      titleStyle: const TextStyle(fontSize: 0),
      radius: 15,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      content: Column(
        children: [
          Icon(icon, size: 60, color: color),
          const SizedBox(height: 15),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: onConfirm ?? () => Get.back(),
              child: const Text(
                "ตกลง",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleRequestOTP() async {
    // 1. ตรวจสอบการกรอกอีเมล
    if (_emailController.text.isEmpty) {
      _showPopup(
        title: "แจ้งเตือน",
        message: "กรุณากรอกอีเมลของคุณก่อนดำเนินการต่อ",
        icon: Icons.info_outline,
        color: Colors.orange,
      );
      return;
    }

    setState(() => _isLoading = true);
    final request = ResetRequest(email: _emailController.text.trim());
    final response = await ApiService.requestResetOTP(request);
    setState(() => _isLoading = false);

    // 2. กรณีส่งสำเร็จ
    if (response.error == null) {
      _showPopup(
        title: "ส่งรหัสสำเร็จ",
        message:
            "ระบบได้ส่งรหัส OTP ไปยังอีเมลของท่านแล้ว\nกรุณาตรวจสอบกล่องจดหมาย",
        icon: Icons.check_circle_outline,
        color: Colors.green,
        onConfirm: () {
          Get.back(); // ปิด Popup
          // ✨ แก้บรรทัดนี้เพื่อไปหน้า Verify OTP
          Get.to(
            () => const VerifyOtpPage(),
            arguments: _emailController.text.trim(),
          );
        },
      );
    }
    // 3. กรณีเกิดข้อผิดพลาด
    else {
      _showPopup(
        title: "เกิดข้อผิดพลาด",
        message: response.error!,
        icon: Icons.error_outline,
        color: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black54),
          onPressed: () => Get.back(),
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_reset_rounded,
                  size: 80,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                "ลืมรหัสผ่าน ?",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 15),
              Text(
                "ไม่ต้องกังวล! กรุณากรอกอีเมลที่คุณใช้สมัครสมาชิก\nเราจะส่งรหัส OTP ไปให้คุณตั้งรหัสผ่านใหม่",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "อีเมลของคุณ",
                    labelStyle: TextStyle(color: Colors.grey[600]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: _primaryColor,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRequestOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text("ส่งรหัส OTP"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
