import 'package:eazy_store/auth/register.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ----------------------------------------------------------------------
// 1. Controller: สมองของหน้านี้ (GetX Logic)
// ----------------------------------------------------------------------
class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // ตัวแปรสำหรับเช็คว่ากำลังโหลดอยู่ไหม (เผื่อต่อ API จริง)
  var isLoading = false.obs;

  void login() {
    // จำลองการ Login
    isLoading.value = true;
    print("Email: ${emailController.text}");
    print("Password: ${passwordController.text}");

    Future.delayed(const Duration(seconds: 2), () {
      isLoading.value = false;
      Get.snackbar(
        "สำเร็จ",
        "เข้าสู่ระบบเรียบร้อย",
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      // ใส่คำสั่งเปลี่ยนหน้าตรงนี้ เช่น Get.offAll(() => HomePage());
    });
  }

  void goToSignup() {
    Get.to(() => SignupPage());
  }

  void goToForgotPassword() {
    print("ไปหน้าลืมรหัสผ่าน");
    // Get.to(() => ForgotPasswordPage());
  }
}

// ----------------------------------------------------------------------
// 2. The View: หน้าจอ UI
// ----------------------------------------------------------------------
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject Controller เข้ามาใช้งาน
    final LoginController controller = Get.put(LoginController());

    // สีหลักตาม Ref (ฟ้าสดใส)
    final Color primaryColor = const Color(0xFF00A3FF);
    // สีพื้นหลัง (เทาอมฟ้าอ่อนๆ)
    final Color backgroundColor = const Color(0xFFF3F7FB);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Center(
                  // จัดให้อยู่ตรงกลางเสมอ สำหรับจอ Tablet/Desktop
                  child: Container(
                    // Responsive: ล็อคความกว้างสูงสุดไว้ที่ 500 เพื่อไม่ให้ยืดน่าเกลียดบน iPad
                    constraints: const BoxConstraints(maxWidth: 500),
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start, // จัดชิดซ้าย
                      children: [
                        // Responsive Spacing: เว้นระยะด้านบน 10% ของความสูงจอ
                        SizedBox(height: Get.height * 0.1),

                        // --- LOGO ---
                        Center(
                          child: Container(
                            // Responsive Logo:
                            // ใช้ความกว้างจอ * 0.6 แต่ไม่เกิน 250px (ใหญ่สะใจแต่ไม่ล้น)
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

                        SizedBox(
                          height: Get.height * 0.05,
                        ), // เว้นระยะห่าง dynamic
                        // --- HEADER TEXT ---
                        const Text(
                          "เข้าสู่ระบบ",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // --- INPUT: EMAIL ---
                        _buildCustomTextField(
                          controller: controller.emailController,
                          hintText: "กรอกอีเมลหรือเบอร์โทร",
                          icon: Icons.person_outline,
                        ),

                        const SizedBox(height: 20),

                        // --- INPUT: PASSWORD ---
                        _buildCustomTextField(
                          controller: controller.passwordController,
                          hintText: "กรอกรหัสผ่าน",
                          isPassword: true,
                          icon: Icons.lock_outline,
                        ),

                        // --- FORGOT PASSWORD ---
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

                        // --- LOGIN BUTTON ---
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
                                elevation: 2, // เงาปุ่ม
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

                        // --- SPACER ---
                        // ดันเนื้อหาด้านล่างลงไปติดขอบจอ
                        const Spacer(),

                        // --- BOTTOM TEXT ---
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
                                    color: Colors
                                        .purpleAccent[400], // สีม่วงตาม Ref
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

  // Widget แยกสำหรับ TextField เพื่อความสะอาดของโค้ด
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
            offset: const Offset(0, 3), // เงาตกกระทบด้านล่าง
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
