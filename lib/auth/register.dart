import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ----------------------------------------------------------------------
// 1. Controller: จัดการ Logic การสมัคร
// ----------------------------------------------------------------------
class SignupController extends GetxController {
  // สร้าง Controller ให้ครบทุกช่องตามรูป
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  var isLoading = false.obs;

  void register() {
    // เช็คว่ากรอกครบไหม (ตัวอย่าง Validation)
    if (passwordController.text != confirmPasswordController.text) {
      Get.snackbar(
        "แจ้งเตือน",
        "รหัสผ่านไม่ตรงกัน",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    // จำลองการโหลด 2 วินาที
    Future.delayed(const Duration(seconds: 2), () {
      isLoading.value = false;
      Get.snackbar(
        "สำเร็จ",
        "สมัครสมาชิกเรียบร้อย",
        backgroundColor: const Color(0xFF00C853), // สีเขียว
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      // สมัครเสร็จแล้วกลับไปหน้า Login หรือไปหน้า Home
      Get.back();
    });
  }
}

// ----------------------------------------------------------------------
// 2. The View: หน้าจอ UI
// ----------------------------------------------------------------------
class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final SignupController controller = Get.put(SignupController());

    // สีหลักของหน้านี้ (เขียวตามปุ่ม)
    final Color primaryGreen = const Color(0xFF00C853);

    return Scaffold(
      backgroundColor: Colors.white, // พื้นหลังขาวคลีน
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Get.back(), // กลับไปหน้า Login
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // --- HEADER TEXT ---
              const Text(
                "สมัครผู้ใช้",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 30),

              // --- INPUT FIELDS ---
              // เรียงตามรูปเป๊ะๆ
              _buildLineInput(
                label: "ชื่อ นามสกุล",
                hint: "ชื่อ นามสกุล",
                controller: controller.nameController,
              ),

              _buildLineInput(
                label: "เบอร์โทร",
                hint: "xx-xx-xx", // ใส่ Mask หรือ hint ตามรูป
                controller: controller.phoneController,
                inputType: TextInputType.phone,
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
              ),

              _buildLineInput(
                label: "ยืนยันรหัสผ่าน",
                hint: "กรอกเพื่อยืนยันรหัสผ่าน",
                controller: controller.confirmPasswordController,
                isPassword: true,
                isLast: true, // ช่องสุดท้ายไม่ต้องเว้นเยอะ
              ),

              const SizedBox(height: 40),

              // --- REGISTER BUTTON ---
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
                        borderRadius: BorderRadius.circular(
                          25,
                        ), // ปุ่มมนๆ ตามรูป
                      ),
                      elevation: 0, // สไตล์ Flat ตามรูป
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

  // Widget สร้าง Input แบบเส้น (Line Style) ตามรูป Reference
  Widget _buildLineInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    bool isLast = false,
    TextInputType inputType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label หัวข้อ
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        // ช่องกรอกข้อมูล
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: inputType,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            // เส้นปกติ (สีเขียวอ่อนๆ หรือเทา)
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.green.withOpacity(0.5)),
            ),
            // เส้นตอนกด (สีเขียวเข้ม)
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF00C853), width: 2),
            ),
            border: const UnderlineInputBorder(),
          ),
        ),
        // เว้นระยะห่างแต่ละช่อง (ถ้าไม่ใช่ช่องสุดท้าย)
        if (!isLast) const SizedBox(height: 20),
      ],
    );
  }
}
