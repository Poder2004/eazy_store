import 'dart:async';
import 'package:eazy_store/auth/login.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eazy_store/api/api_service.dart';
import 'package:eazy_store/model/request/verify_registration_request.dart';
import 'package:eazy_store/model/request/change_email_verify_request.dart';

class VerifyRegistrationPage extends StatefulWidget {
  const VerifyRegistrationPage({super.key});
  @override
  State<VerifyRegistrationPage> createState() => _VerifyRegistrationPageState();
}

class _VerifyRegistrationPageState extends State<VerifyRegistrationPage> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (i) => TextEditingController(),
  );
  final List<FocusNode> _nodes = List.generate(6, (i) => FocusNode());

  int _counter = 60;
  Timer? _timer;
  bool _isLoading = false;

  late String email, username;

  // โทนสีฟ้าสมัยใหม่
  final Color primaryColor = const Color(0xFF0288D1);
  final Color bgColor = const Color(0xFFF5FAFF);

  @override
  void initState() {
    super.initState();
    email = Get.arguments['email'];
    username = Get.arguments['username'];
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _counter = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          if (_counter > 0) {
            _counter--;
          } else {
            _timer?.cancel();
          }
        });
      }
    });
  }

  // ฟังก์ชันส่งรหัสใหม่ (จะทำงานเมื่อกดปุ่ม Resend และ Timer เป็น 0)
  void _resendCode() async {
    setState(() => _isLoading = true);

    // เรียกใช้ changeEmailVerify เพื่ออัปเดตอีเมลปัจจุบันใน DB และส่งรหัส
    final res = await ApiService.changeEmailVerify(
      ChangeEmailVerifyRequest(username: username, newEmail: email),
    );

    setState(() => _isLoading = false);

    if (res.error == null) {
      _startTimer();
      Get.snackbar(
        "สำเร็จ",
        "เราได้ส่งรหัสใหม่ไปยัง $email แล้ว",
        backgroundColor: Colors.white,
        colorText: primaryColor,
        icon: const Icon(Icons.check_circle),
      );
    } else {
      Get.snackbar(
        "ผิดพลาด",
        res.error!,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  void _verify() async {
    // 1. เช็คว่ากำลังโหลดอยู่ไหม ถ้าโหลดอยู่ห้ามทำงานซ้ำ
    if (_isLoading) return;

    String otp = _controllers.map((e) => e.text).join();
    if (otp.length < 6) return;

    setState(() => _isLoading = true);
    final res = await ApiService.verifyRegistration(
      VerifyRegistrationRequest(email: email, otp: otp),
    );

    // สำคัญ: อย่าเพิ่ง setState _isLoading เป็น false ทันทีถ้าสำเร็จ
    // เพื่อป้องกันการยิงซ้ำระหว่างกำลังเปลี่ยนหน้า

    if (res.error == null) {
      Get.defaultDialog(
        title: "สำเร็จ",
        titleStyle: const TextStyle(
          color: Color(0xFF0288D1),
          fontWeight: FontWeight.bold,
        ),
        middleText: "ยืนยันตัวตนสำเร็จแล้ว!\nคุณสามารถเข้าสู่ระบบได้ทันที",
        radius: 15,
        barrierDismissible: false,
        confirm: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0288D1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Get.offAll(() => const LoginPage()),
            child: const Text(
              "ไปหน้าล็อกอิน",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    } else {
      setState(() => _isLoading = false); // ถ้าผิดค่อยเปิดให้กดใหม่
      Get.snackbar(
        "รหัสไม่ถูกต้อง",
        res.error!,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  // ปรับปรุง Popup แก้ไขอีเมลให้สวยงามขึ้น
  void _changeEmailDialog() {
    final newEmailController = TextEditingController(text: email);
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.edit_note_rounded,
                size: 50,
                color: Color(0xFF0288D1),
              ),
              const SizedBox(height: 16),
              const Text(
                "แก้ไขอีเมลของคุณ",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "ระบุอีเมลที่ถูกต้องเพื่อรับรหัส",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: newEmailController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  hintText: "example@gmail.com",
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: const Text("ยกเลิก"),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (newEmailController.text.trim().isNotEmpty) {
                          setState(
                            () => email = newEmailController.text.trim(),
                          );
                          Get.back();
                          Get.snackbar(
                            "เปลี่ยนอีเมลแล้ว",
                            "กรุณากด 'ส่งรหัสอีกครั้ง' เพื่อรับรหัสใหม่",
                            backgroundColor: Colors.white,
                            colorText: Colors.black87,
                          );
                        }
                      },
                      child: const Text(
                        "บันทึก",
                        style: TextStyle(color: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // รูปประกอบ Illustration
              Container(
                height: 150,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://cdn-icons-png.flaticon.com/512/6681/6681204.png',
                    ),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "ยืนยันอีเมลของคุณ",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: "ป้อนรหัส 6 หลักที่ส่งไปยัง\n"),
                    TextSpan(
                      text: email,
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // OTP Input Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => _otpBox(i)),
              ),
              const SizedBox(height: 40),

              // ส่วนควบคุมการส่งรหัสและแก้ไข
              if (_isLoading)
                const CircularProgressIndicator()
              else ...[
                TextButton(
                  onPressed: _counter == 0 ? _resendCode : null,
                  child: Text(
                    _counter == 0
                        ? "ส่งรหัสอีกครั้ง"
                        : "ส่งรหัสอีกครั้งใน ($_counter)",
                    style: TextStyle(
                      color: _counter == 0 ? primaryColor : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _changeEmailDialog,
                  child: Text(
                    "ใส่อีเมลผิด? แก้ไขที่นี่",
                    style: TextStyle(
                      color: Colors.grey[600],
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "ยืนยันตัวตน",
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
      ),
    );
  }

  Widget _otpBox(int i) {
    return Container(
      width: 48,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _nodes[i].hasFocus ? primaryColor : Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _controllers[i],
        focusNode: _nodes[i],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
        ),
        onChanged: (v) {
          if (v.isNotEmpty && i < 5) _nodes[i + 1].requestFocus();
          if (v.isEmpty && i > 0) _nodes[i - 1].requestFocus();
          if (i == 5 && v.isNotEmpty) _verify();
        },
      ),
    );
  }
}
