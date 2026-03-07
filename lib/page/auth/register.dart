import 'package:eazy_store/api/api_auth.dart';
import 'package:eazy_store/page/auth/login.dart';
import 'package:eazy_store/page/auth/verify_register.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:eazy_store/model/request/register_request.dart';

// ----------------------------------------------------------------------
// 1. Controller
// ----------------------------------------------------------------------
class SignupController extends GetxController {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  var isLoading = false.obs;
  var confirmPasswordError = RxnString();

  void validateConfirmPassword(String val) {
    if (val.isEmpty) {
      confirmPasswordError.value = null;
    } else if (val != passwordController.text) {
      confirmPasswordError.value = "รหัสผ่านไม่ตรงกัน";
    } else {
      confirmPasswordError.value = null;
    }
  }

  Future<void> register() async {
    String name = nameController.text.trim();
    String phone = phoneController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;

    // --- Validation Checks ---
    if (name.isEmpty || phone.isEmpty || email.isEmpty || password.isEmpty) {
      _showWarning("แจ้งเตือน", "กรุณากรอกข้อมูลให้ครบ");
      return;
    }
    if (phone.length != 10) {
      _showWarning("แจ้งเตือน", "เบอร์โทรต้องมี 10 หลัก");
      return;
    }
    if (password.length <= 5) {
      _showWarning("แจ้งเตือน", "รหัสผ่านต้องมากกว่า 5 ตัว");
      return;
    }
    if (password != confirmPassword) {
      _showWarning("แจ้งเตือน", "รหัสผ่านไม่ตรงกัน");
      return;
    }

    isLoading.value = true;

    final request = RegisterRequest(
      username: name,
      phone: phone,
      email: email,
      password: password,
    );

    final response = await ApiAuth.register(request);
    isLoading.value = false;

    if (response.error == null) {
      _showSuccessPopup(
        "สำเร็จ",
        response.message ?? "ระบบได้ส่งรหัส OTP ไปยังอีเมลของท่านแล้ว",
        email,
        name,
      );
    } else {
      if (response.error!.contains("ถูกใช้งานแล้ว")) {
        _showError(
          "สมัครไม่สำเร็จ",
          "อีเมลหรือข้อมูลนี้ถูกใช้งานและยืนยันตัวตนไปแล้ว กรุณาใช้ข้อมูลอื่น",
        );
      } else {
        _showError("ไม่สำเร็จ", response.error ?? "เกิดข้อผิดพลาด");
      }
    }
  }

  // --- Helper UI Functions ---
  void _showWarning(String title, String msg) {
    Get.snackbar(
      title,
      msg,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  void _showError(String title, String msg) {
    Get.snackbar(
      title,
      msg,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  void _showSuccessPopup(String title, String msg, String email, String name) {
    Get.defaultDialog(
      title: title,
      middleText: msg,
      radius: 15,
      barrierDismissible: false,
      textConfirm: "ไปหน้ายืนยัน OTP",
      buttonColor: const Color(0xFF00C853),
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back(); // ปิด Dialog
        // ไปหน้ายืนยัน OTP พร้อมส่ง Arguments
        Get.to(
          () => const VerifyRegistrationPage(),
          arguments: {"email": email, "username": name},
        );
      },
    );
  }
}

// ----------------------------------------------------------------------
// 2. The View
// ----------------------------------------------------------------------
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  @override
  Widget build(BuildContext context) {
    final SignupController controller = Get.put(SignupController());
    const Color primaryGreen = Color(0xFF00C853);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.grey),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                "สร้างบัญชีใหม่",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "กรุณากรอกข้อมูลให้ครบถ้วนเพื่อเริ่มใช้งาน",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 30),

              _buildLineInput(
                label: "ชื่อ นามสกุล",
                hint: "กรอกชื่อ-นามสกุลของคุณ",
                controller: controller.nameController,
              ),

              _buildLineInput(
                label: "เบอร์โทรศัพท์",
                hint: "0xxxxxxxxx",
                controller: controller.phoneController,
                inputType: TextInputType.number,
                isPhone: true,
              ),

              _buildLineInput(
                label: "อีเมล",
                hint: "example@email.com",
                controller: controller.emailController,
                inputType: TextInputType.emailAddress,
              ),

              _buildLineInput(
                label: "รหัสผ่าน",
                hint: "อย่างน้อย 6 ตัวอักษร",
                controller: controller.passwordController,
                isPassword: true,
                onChanged: (val) {
                  if (controller.confirmPasswordController.text.isNotEmpty) {
                    controller.validateConfirmPassword(
                      controller.confirmPasswordController.text,
                    );
                  }
                },
              ),

              Obx(
                () => _buildLineInput(
                  label: "ยืนยันรหัสผ่านอีกครั้ง",
                  hint: "กรอกรหัสผ่านให้ตรงกัน",
                  controller: controller.confirmPasswordController,
                  isPassword: true,
                  isLast: true,
                  errorText: controller.confirmPasswordError.value,
                  onChanged: (val) => controller.validateConfirmPassword(val),
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 2,
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                            height: 25,
                            width: 25,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "สมัครสมาชิก",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
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
    bool isPassword = false,
    bool isLast = false,
    bool isPhone = false,
    TextInputType inputType = TextInputType.text,
    Function(String)? onChanged,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: inputType,
          onChanged: onChanged,
          maxLength: isPhone ? 10 : null,
          inputFormatters: isPhone
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            errorText: errorText,
            errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
            counterText: "",
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF00C853), width: 2),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent, width: 2),
            ),
          ),
        ),
        if (!isLast) const SizedBox(height: 20),
      ],
    );
  }
}
