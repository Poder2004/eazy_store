import 'package:eazy_store/auth/login.dart';
import 'package:flutter/material.dart';
import 'package:eazy_store/api/api_service.dart';
import 'package:eazy_store/model/request/update_password_request.dart';
import 'package:get/get.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  final Color _primaryColor = const Color(0xFF6200EE);
  late String _email;
  late String _otp;

  @override
  void initState() {
    super.initState();
    // รับค่า email และ otp จากหน้า Verify OTP
    final Map<String, dynamic> args = Get.arguments;
    _email = args['email'];
    _otp = args['otp'];
  }

  void _handleResetPassword() async {
    // 1. ตรวจสอบความถูกต้องเบื้องต้น
    if (_passController.text.isEmpty || _confirmPassController.text.isEmpty) {
      _showPopup(
        title: "เตือน",
        message: "กรุณากรอกรหัสผ่านให้ครบทั้ง 2 ช่อง",
        icon: Icons.warning_amber,
        color: Colors.orange,
      );
      return;
    }
    if (_passController.text != _confirmPassController.text) {
      _showPopup(
        title: "ไม่ตรงกัน",
        message: "รหัสผ่านทั้งสองช่องไม่ตรงกัน\nกรุณาตรวจสอบอีกครั้ง",
        icon: Icons.error_outline,
        color: Colors.red,
      );
      return;
    }

    setState(() => _isLoading = true);
    final request = UpdatePasswordRequest(
      email: _email,
      otpCode: _otp,
      newPassword: _passController.text,
    );
    final response = await ApiService.updatePassword(request);
    setState(() => _isLoading = false);

    if (response.error == null) {
      _showPopup(
        title: "สำเร็จ!",
        message:
            "เปลี่ยนรหัสผ่านใหม่เรียบร้อยแล้ว\nคุณสามารถเข้าสู่ระบบได้ทันที",
        icon: Icons.check_circle,
        color: Colors.green,
        onConfirm: () {
          Get.offAll(() => const LoginPage());
        },
      );
    } else {
      _showPopup(
        title: "ผิดพลาด",
        message: response.error!,
        icon: Icons.cancel,
        color: Colors.red,
      );
    }
  }

  void _showPopup({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    VoidCallback? onConfirm,
  }) {
    Get.defaultDialog(
      title: "",
      titleStyle: const TextStyle(fontSize: 0),
      radius: 20,
      content: Column(
        children: [
          Icon(icon, size: 70, color: color),
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
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onConfirm ?? () => Get.back(),
              child: const Text(
                "ตกลง",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SizedBox(),
      ), // ไม่ให้ถอยกลับไปหน้า Verify ได้
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            Center(
              child: Image.network(
                'https://cdn-icons-png.flaticon.com/512/13731/13731152.png', // ไอคอนรูปกุญแจใหม่
                height: 150,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Set New Password",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "กรุณาตั้งรหัสผ่านใหม่ที่คุณจำได้ง่าย\nเพื่อความปลอดภัยของบัญชีคุณ",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // ช่องกรอกรหัสผ่านใหม่
            _buildPasswordField(_passController, "รหัสผ่านใหม่"),
            const SizedBox(height: 20),
            _buildPasswordField(_confirmPassController, "ยืนยันรหัสผ่านใหม่"),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleResetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Change Password",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        obscureText: _obscureText,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _obscureText = !_obscureText),
          ),
        ),
      ),
    );
  }
}
