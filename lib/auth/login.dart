import 'package:eazy_store/api/api_service.dart';
import 'package:eazy_store/auth/forgot_password.dart';
import 'package:eazy_store/auth/register.dart';
import 'package:eazy_store/auth/verify_register.dart';
import 'package:eazy_store/model/request/login_request.dart';
import 'package:eazy_store/shop/myshop.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ----------------------------------------------------------------------
// 1. Controller: จัดการ Logic การเข้าสู่ระบบ
// ----------------------------------------------------------------------
class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  var isLoading = false.obs;

  final Color primaryColor = const Color(0xFF00A3FF);

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showSnackbar("แจ้งเตือน", "กรุณากรอกข้อมูลให้ครบ", Colors.orange);
      return;
    }

    isLoading.value = true;

    LoginRequest request = LoginRequest(
      username: emailController.text.trim(),
      password: passwordController.text,
    );

    var res = await ApiService.login(request);
    isLoading.value = false;

    if (res.token != null) {
      // ✅ เคสที่ 1: Login สำเร็จ
      await _saveSession(res);
      _showSnackbar(
        "สำเร็จ",
        "ยินดีต้อนรับคุณ ${res.user?.username}",
        Colors.green,
      );
      Get.offAll(() => const MyShopPage());
    }
    // 🔥 เคสที่ 2: บัญชียังไม่ได้ยืนยันตัวตน
    else if (res.error != null && res.error!.contains("ยืนยันตัวตน")) {
      // ✨ หัวใจสำคัญ: ใช้อีเมลและชื่อจริงที่ Server ส่งกลับมา (res.email / res.username)
      // เพื่อป้องกันกรณีผู้ใช้ล็อกอินด้วยเบอร์โทร แต่ระบบต้องการอีเมลในการยืนยัน OTP
      String actualEmail = res.email ?? emailController.text.trim();
      String actualUsername = res.username ?? "User";

      _showUnverifiedDialog(actualEmail, actualUsername);
    } else {
      _showSnackbar(
        "เข้าสู่ระบบไม่สำเร็จ",
        res.error ?? "ข้อมูลไม่ถูกต้อง",
        Colors.red,
      );
    }
  }

  Future<void> _saveSession(dynamic res) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', res.token!);
    await prefs.setInt('userId', res.user?.id ?? 0);
    await prefs.setString('username', res.user?.username ?? "");
  }

  // --- ✨ Popup ดีไซน์ใหม่แบบ Premium ---
  void _showUnverifiedDialog(String email, String username) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_user_outlined,
                  size: 44,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "ยืนยันบัญชีของคุณ",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "คุณสมัครสมาชิกด้วยอีเมล $email เรียบร้อยแล้ว\nแต่ต้องยืนยันรหัส OTP ก่อนเข้าใช้งาน",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        "ยกเลิก",
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        // ✨ ส่งค่าจริง (Email และ Username) ไปที่หน้า Verify
                        Get.to(
                          () => const VerifyRegistrationPage(),
                          arguments: {"email": email, "username": username},
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "ไปหน้ายืนยัน OTP",
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
    );
  }

  void _showSnackbar(String title, String msg, Color color) {
    Get.snackbar(
      title,
      msg,
      backgroundColor: color.withOpacity(0.8),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(10),
    );
  }

  void goToSignup() => Get.to(() => const SignupPage());
  void goToForgotPassword() => Get.to(() => const ForgotPasswordPage());
}

// ----------------------------------------------------------------------
// 2. The View (คงเดิมตามโครงสร้างของคุณ)
// ----------------------------------------------------------------------
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginController controller = Get.put(LoginController());
    const Color primaryColor = Color(0xFF00A3FF);
    const Color backgroundColor = Color(0xFFF3F7FB);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: Get.height * 0.1),
                        Center(
                          child: Container(
                            height: (Get.width * 0.6).clamp(150.0, 250.0),
                            width: (Get.width * 0.6).clamp(150.0, 250.0),
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/image/logoEazy.png'),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: Get.height * 0.05),
                        const Text(
                          "เข้าสู่ระบบ",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildCustomTextField(
                          controller: controller.emailController,
                          hintText: "กรอกอีเมลหรือเบอร์โทร",
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 20),
                        _buildCustomTextField(
                          controller: controller.passwordController,
                          hintText: "กรอกรหัสผ่าน",
                          isPassword: true,
                          icon: Icons.lock_outline,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: controller.goToForgotPassword,
                            child: Text(
                              "ลืมรหัสผ่าน ?",
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: Obx(
                            () => ElevatedButton(
                              onPressed: controller.isLoading.value
                                  ? null
                                  : controller.login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 2,
                              ),
                              child: controller.isLoading.value
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      "เข้าสู่ระบบ",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 30.0, top: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "คุณยังไม่มีบัญชีผู้ใช้หรือไม่ ",
                                style: TextStyle(color: Colors.grey[800]),
                              ),
                              GestureDetector(
                                onTap: controller.goToSignup,
                                child: Text(
                                  "สมัคร",
                                  style: TextStyle(
                                    color: Colors.purpleAccent[400],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    bool isPassword = false,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
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
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: icon != null ? Icon(icon, color: Colors.grey[400]) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
