import 'package:eazy_store/api/api_service.dart';
import 'package:eazy_store/auth/login.dart';
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
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณากรอกข้อมูลให้ครบ",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    if (phone.length != 10) {
      Get.snackbar(
        "แจ้งเตือน",
        "เบอร์โทรต้องมี 10 หลัก",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    if (password.length <= 5) {
      Get.snackbar(
        "แจ้งเตือน",
        "รหัสผ่านต้องมากกว่า 5 ตัว",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    if (password != confirmPassword) {
      Get.snackbar(
        "แจ้งเตือน",
        "รหัสผ่านไม่ตรงกัน",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    // --- Call API ---
    isLoading.value = true;

    final request = RegisterRequest(
      username: name,
      phone: phone,
      email: email,
      password: password,
    );

    final response = await ApiService.register(request);

    isLoading.value = false;

    // 🔥 ปรับปรุงการเช็ค Response และการแสดงผล
    // 3. เช็คผลลัพธ์จาก Model Response
    if (response.error == null) {
      // ✅ แก้จุดที่ 1: บังคับโชว์ข้อความไทยเสมอ (ไม่ต้องสน response.message จาก backend)
      Get.snackbar(
        "สำเร็จ",
        "สมัครสมาชิกเรียบร้อย", // ใส่ข้อความตรงนี้เลย
        backgroundColor: const Color(0xFF00C853),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );

      // ✅ แก้จุดที่ 2: เปลี่ยนจาก Get.back() เป็นการสั่งเปิดหน้า Login โดยตรง
      Future.delayed(const Duration(seconds: 2), () {
        // ใช้ Get.offAll เพื่อเคลียร์หน้าสมัครทิ้ง แล้วเปิดหน้า Login ใหม่
        // (ต้องแน่ใจว่า import ไฟล์ LoginPage เข้ามาในไฟล์นี้แล้วนะครับ)
        Get.offAll(() => const LoginPage());
      });
    } else {
      // ❌ กรณีไม่สำเร็จ
      Get.snackbar(
        "ไม่สำเร็จ",
        response.error ?? "เกิดข้อผิดพลาด",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
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
              const SizedBox(height: 10),
              const Text(
                "สมัครผู้ใช้",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 30),

              _buildLineInput(
                label: "ชื่อ นามสกุล",
                hint: "ชื่อ นามสกุล",
                controller: controller.nameController,
              ),

              _buildLineInput(
                label: "เบอร์โทร",
                hint: "0xxxxxxxxx",
                controller: controller.phoneController,
                inputType: TextInputType.number,
                isPhone: true,
              ),

              _buildLineInput(
                label: "อีเมล",
                hint: "กรอกอีเมล",
                controller: controller.emailController,
                inputType: TextInputType.emailAddress,
              ),

              _buildLineInput(
                label: "รหัสผ่าน",
                hint: "กรอกรหัสผ่าน",
                controller: controller.passwordController,
                isPassword: true,
                // เพิ่ม: ถ้าแก้รหัสผ่านหลัก ให้ไปเช็คตัวยืนยันใหม่ด้วย
                onChanged: (val) {
                  if (controller.confirmPasswordController.text.isNotEmpty) {
                    controller.validateConfirmPassword(
                      controller.confirmPasswordController.text,
                    );
                  }
                },
              ),

              // 🔥 ใช้ Obx ครอบเฉพาะช่องยืนยันรหัสผ่าน เพื่อดักจับ Error แบบ Real-time
              Obx(
                () => _buildLineInput(
                  label: "ยืนยันรหัสผ่าน",
                  hint: "กรอกเพื่อยืนยันรหัสผ่าน",
                  controller: controller.confirmPasswordController,
                  isPassword: true,
                  isLast: true,
                  // ส่งค่า Error เข้าไป (ถ้ามีค่า = แดง, ถ้า null = ปกติ)
                  errorText: controller.confirmPasswordError.value,
                  // เมื่อพิมพ์ ให้เรียกฟังก์ชันตรวจสอบทันที
                  onChanged: (val) => controller.validateConfirmPassword(val),
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "สมัคร",
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

  // ปรับแก้ Widget ให้รองรับ ErrorText และ OnChanged
  Widget _buildLineInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    bool isLast = false,
    bool isPhone = false,
    TextInputType inputType = TextInputType.text,
    Function(String)? onChanged, // รับฟังก์ชันตอนพิมพ์
    String? errorText, // รับข้อความ Error
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: inputType,
          onChanged: onChanged, // เชื่อม event
          maxLength: isPhone ? 10 : null,
          inputFormatters: isPhone
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),

            // 🔥 ส่วนแสดง Error (ถ้า errorText มีค่า มันจะแสดงเป็นสีแดงอัตโนมัติ)
            errorText: errorText,
            errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),

            counterText: "",
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.green.withOpacity(0.5)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF00C853), width: 2),
            ),
            // เส้นสีแดงตอนมี Error
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent, width: 2),
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
