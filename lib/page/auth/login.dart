import 'package:eazy_store/api/api_auth.dart';
import 'package:eazy_store/page/auth/forgot_password.dart';
import 'package:eazy_store/page/auth/register.dart';
import 'package:eazy_store/page/auth/verify_register.dart';
import 'package:eazy_store/model/request/login_request.dart';
import 'package:eazy_store/page/shop/myShop/myshop.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    var res = await ApiAuth.login(request);
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
                textAlign: TextAlign.center,
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
                        textAlign: TextAlign.center,
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
// 2. The View (หน้า UI ที่ปรับปรุงให้รองรับคนตั้งฟอนต์ใหญ่โดยเฉพาะ)
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
      body: SafeArea(
        // ✨ เคล็ดลับที่ 1: จำกัดการขยายตัวอักษรสูงสุดที่ 1.4 เท่า
        // ช่วยให้คนแก่อ่านง่าย แต่ป้องกันไม่ให้ UI พังจนปุ่มหายไปนอกขอบจอ
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.textScalerOf(
              context,
            ).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.4),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  // ✨ เคล็ดลับที่ 2: ลบการครอบ Center() ออก แล้วใช้ Padding แทน
                  // เพื่อให้เวลาเนื้อหาเยอะกว่าจอ มันจะเริ่ม Scroll จากด้านบนสุด ไม่โดนตัดโลโก้ทิ้ง
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30.0,
                      vertical: 40.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment
                          .center, // จัดให้อยู่กลางจอถ้ายาวไม่ถึงจอ
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- ส่วนโลโก้ ---
                        Center(
                          child: Container(
                            // ปรับขนาดรูปลงมานิดหน่อยเพื่อเผื่อพื้นที่ให้ตัวอักษรใหญ่
                            height: (constraints.maxWidth * 0.4).clamp(
                              100.0,
                              180.0,
                            ),
                            width: (constraints.maxWidth * 0.4).clamp(
                              100.0,
                              180.0,
                            ),
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/image/logoEazy.png'),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // --- หัวข้อเข้าสู่ระบบ ---
                        const Text(
                          "เข้าสู่ระบบ",
                          style: TextStyle(
                            fontSize:
                                24, // ไม่ต้องคูณ textScale แล้ว Flutter ขยายให้เอง
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // --- ฟอร์มกรอกข้อมูล ---
                        _buildCustomTextField(
                          controller: controller.emailController,
                          hintText: "กรอกอีเมลหรือเบอร์โทร",
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),
                        _buildCustomTextField(
                          controller: controller.passwordController,
                          hintText: "กรอกรหัสผ่าน",
                          isPassword: true,
                          icon: Icons.lock_outline,
                        ),

                        // --- ลืมรหัสผ่าน ---
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: controller.goToForgotPassword,
                            child: Text(
                              "ลืมรหัสผ่าน ?",
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // --- ปุ่มเข้าสู่ระบบ ---
                        SizedBox(
                          width: double.infinity,
                          child: Obx(
                            () => ElevatedButton(
                              onPressed: controller.isLoading.value
                                  ? null
                                  : controller.login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                // ใช้ Padding แทนความสูง เพื่อให้ปุ่มขยายรับฟอนต์ใหญ่ได้
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 2,
                              ),
                              child: controller.isLoading.value
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
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

                        const SizedBox(
                          height: 40,
                        ), // ระยะห่างดันส่วนสมัครไปข้างล่างสุด
                        // --- ส่วนสมัครสมาชิก ---
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                "คุณยังไม่มีบัญชีผู้ใช้หรือไม่ ",
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: controller.goToSignup,
                                child: Text(
                                  "สมัคร",
                                  style: TextStyle(
                                    color: Colors.purpleAccent[400],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
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
              );
            },
          ),
        ),
      ),
    );
  }

  // สร้าง Textfield ปกติ (Flutter จะขยายตัวอักษรให้อัตโนมัติอยู่แล้ว)
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
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: icon != null ? Icon(icon, color: Colors.grey[400]) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }
}
