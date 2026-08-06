import 'package:eazy_store/api/api_auth.dart';
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
    if (!GetUtils.isEmail(email)) {
      _showWarning("แจ้งเตือน", "รูปแบบอีเมลไม่ถูกต้อง");
      return;
    }
    if (password.length < 6) {
      _showWarning("แจ้งเตือน", "รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร");
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
          "อีเมลหรือเบอร์โทรนี้ถูกใช้งานไปแล้ว กรุณาใช้ข้อมูลอื่น",
        );
      } else {
        _showError("ไม่สำเร็จ", response.error ?? "เกิดข้อผิดพลาด");
      }
    }
  }

  // --- Helper UI Functions ---
  void _showWarning(String title, String msg) {
    _showPopup(
      title: title,
      message: msg,
      icon: Icons.error_outline_rounded,
      color: Colors.orange,
    );
  }

  void _showError(String title, String msg) {
    _showPopup(
      title: title,
      message: msg,
      icon: Icons.cancel_rounded,
      color: Colors.redAccent,
    );
  }

  void _showSuccessPopup(String title, String msg, String email, String name) {
    const Color primaryGreen = Color(0xFF00C853);

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 30),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 42),
              padding: const EdgeInsets.fromLTRB(24, 54, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    msg,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: primaryGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: primaryGreen.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          size: 16,
                          color: primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            email,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shadowColor: primaryGreen.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Get.back(); // ปิด Dialog
                        // ไปหน้ายืนยัน OTP พร้อมส่ง Arguments
                        Get.to(
                          () => const VerifyRegistrationPage(),
                          arguments: {"email": email, "username": name},
                        );
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text(
                        "ไปหน้ายืนยัน OTP",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 550),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF00E676), primaryGreen],
                  ),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _showPopup({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    String confirmText = "ตกลง",
    bool barrierDismissible = true,
    VoidCallback? onConfirm,
  }) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onConfirm ?? () => Get.back(),
                  child: Text(
                    confirmText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: barrierDismissible,
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
  late final SignupController controller;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    controller = Get.put(SignupController());
    controller.nameController.addListener(_onTextChanged);
    controller.phoneController.addListener(_onTextChanged);
    controller.emailController.addListener(_onTextChanged);
    controller.passwordController.addListener(_onTextChanged);
    controller.confirmPasswordController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    controller.nameController.removeListener(_onTextChanged);
    controller.phoneController.removeListener(_onTextChanged);
    controller.emailController.removeListener(_onTextChanged);
    controller.passwordController.removeListener(_onTextChanged);
    controller.confirmPasswordController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  // --- Dynamic Validation Color Helpers ---
  bool? _isNameValid(String text) {
    if (text.isEmpty) return null;
    return text.trim().isNotEmpty;
  }

  bool? _isPhoneValid(String text) {
    if (text.isEmpty) return null;
    return text.length == 10;
  }

  bool? _isEmailValid(String text) {
    if (text.isEmpty) return null;
    return GetUtils.isEmail(text);
  }

  bool? _isPasswordValid(String text) {
    if (text.isEmpty) return null;
    return text.length >= 6;
  }

  bool? _isConfirmPasswordValid(String text, String password) {
    if (text.isEmpty) return null;
    return text == password;
  }

  @override
  Widget build(BuildContext context) {
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
                isValid: _isNameValid(controller.nameController.text),
              ),

              _buildLineInput(
                label: "เบอร์โทรศัพท์",
                hint: "0xxxxxxxxx",
                controller: controller.phoneController,
                inputType: TextInputType.number,
                isPhone: true,
                isValid: _isPhoneValid(controller.phoneController.text),
              ),

              _buildLineInput(
                label: "อีเมล",
                hint: "example@email.com",
                controller: controller.emailController,
                inputType: TextInputType.emailAddress,
                isValid: _isEmailValid(controller.emailController.text),
              ),

              _buildLineInput(
                label: "รหัสผ่าน",
                hint: "อย่างน้อย 6 ตัวอักษร",
                controller: controller.passwordController,
                isPassword: true,
                obscureText: _obscurePassword,
                onPressStart: () {
                  setState(() {
                    _obscurePassword = false;
                  });
                },
                onPressEnd: () {
                  setState(() {
                    _obscurePassword = true;
                  });
                },
                isValid: _isPasswordValid(controller.passwordController.text),
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
                  obscureText: _obscureConfirmPassword,
                  onPressStart: () {
                    setState(() {
                      _obscureConfirmPassword = false;
                    });
                  },
                  onPressEnd: () {
                    setState(() {
                      _obscureConfirmPassword = true;
                    });
                  },
                  isValid: _isConfirmPasswordValid(
                    controller.confirmPasswordController.text,
                    controller.passwordController.text,
                  ),
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
    bool obscureText = false,
    VoidCallback? onPressStart,
    VoidCallback? onPressEnd,
    bool isLast = false,
    bool isPhone = false,
    TextInputType inputType = TextInputType.text,
    Function(String)? onChanged,
    String? errorText,
    bool? isValid,
  }) {
    Color borderSideColor = Colors.grey[300]!;
    Color focusedBorderSideColor = const Color(0xFF00C853);

    if (isValid == false) {
      borderSideColor = Colors.redAccent;
      focusedBorderSideColor = Colors.redAccent;
    }

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
          obscureText: isPassword ? obscureText : false,
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
              borderSide: BorderSide(color: borderSideColor),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: focusedBorderSideColor, width: 2),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent, width: 2),
            ),
            suffixIcon: isPassword
                ? Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (_) => onPressStart?.call(),
                    onPointerUp: (_) => onPressEnd?.call(),
                    onPointerCancel: (_) => onPressEnd?.call(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      child: Icon(
                        obscureText ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : null,
          ),
        ),
        if (!isLast) const SizedBox(height: 20),
      ],
    );
  }
}
