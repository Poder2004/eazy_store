import 'dart:async';
import 'package:eazy_store/auth/reset_password.dart';
import 'package:flutter/material.dart';
import 'package:eazy_store/api/api_service.dart';
import 'package:eazy_store/model/request/reset_request.dart';
import 'package:eazy_store/model/request/verify_otp_request.dart';
import 'package:get/get.dart';

class VerifyOtpPage extends StatefulWidget {
  const VerifyOtpPage({super.key});

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isLoading = false;
  int _secondsRemaining = 60; // ตัวนับเวลาถอยหลัง 60 วินาที
  Timer? _timer;
  bool _canResend = false;

  final Color _primaryColor = const Color(0xFF6200EE);
  late String _email;

  @override
  void initState() {
    super.initState();
    _email = Get.arguments ?? "";
    _startTimer(); // เริ่มนับเวลาถอยหลังทันทีที่เข้าหน้านี้
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // ฟังก์ชันนับเวลาถอยหลังสำหรับการส่งรหัสใหม่
  void _startTimer() {
    _secondsRemaining = 60;
    _canResend = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          _timer?.cancel();
        }
      });
    });
  }

  // ฟังก์ชันขอส่งรหัส OTP อีกครั้ง
  void _handleResendOTP() async {
    setState(() => _isLoading = true);
    final response = await ApiService.requestResetOTP(
      ResetRequest(email: _email),
    );
    setState(() => _isLoading = false);

    if (response.error == null) {
      _showPopup(
        title: "สำเร็จ",
        message: "ระบบได้ส่งรหัสใหม่ไปที่เมลของคุณแล้ว",
        icon: Icons.mark_email_read,
        color: Colors.green,
      );
      _startTimer(); // รีเซ็ตเวลาถอยหลังใหม่
    } else {
      _showPopup(
        title: "ผิดพลาด",
        message: response.error!,
        icon: Icons.error,
        color: Colors.red,
      );
    }
  }

  void _handleVerify() async {
    String otp = _controllers.map((e) => e.text).join();
    if (otp.length < 6) return;

    setState(() => _isLoading = true);
    final response = await ApiService.verifyOTP(
      VerifyOtpRequest(email: _email, otpCode: otp),
    );
    setState(() => _isLoading = false);

    if (response.error == null) {
      _showPopup(
        title: "ยืนยันสำเร็จ",
        message: "รหัส OTP ถูกต้อง คุณสามารถตั้งรหัสผ่านใหม่ได้ทันที",
        icon: Icons.verified_user_rounded,
        color: Colors.green,
        onConfirm: () {
          Get.back(); // ปิด Popup
          // ✨ แก้บรรทัดนี้เพื่อส่งข้อมูลไปยังหน้าตั้งรหัสผ่านใหม่
          Get.to(
            () => const ResetPasswordPage(),
            arguments: {
              "email": _email,
              "otp": _controllers.map((e) => e.text).join(),
            },
          );
        },
      );
    } else {
      _showPopup(
        title: "รหัสผิด",
        message: response.error!,
        icon: Icons.lock_clock,
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
            style: TextStyle(color: Colors.grey[600]),
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
              ),
              onPressed: onConfirm ?? () => Get.back(),
              child: const Text("ตกลง", style: TextStyle(color: Colors.white)),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // 1. เพิ่มรูปภาพประกอบให้ดูมีอะไร (Illustration)
            Container(
              height: 180,
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://cdn-icons-png.freepik.com/512/7285/7285521.png',
                  ), // ใช้รูปเมล์สวยๆ
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "OTP Verification",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                children: [
                  const TextSpan(text: "กรุณากรอกรหัส 6 หลักที่ส่งไปยัง\n"),
                  TextSpan(
                    text: _email,
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // 2. ช่องกรอก OTP
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) => _buildOtpInput(index)),
            ),
            const SizedBox(height: 40),
            // 3. ปุ่ม "ส่งรหัสอีกครั้ง" พร้อมตัวนับเวลา
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("ยังไม่ได้รับรหัส? "),
                TextButton(
                  onPressed: _canResend ? _handleResendOTP : null,
                  child: Text(
                    _canResend
                        ? "ส่งรหัสอีกครั้ง"
                        : "ส่งอีกครั้งใน ($_secondsRemaining วินาที)",
                    style: TextStyle(
                      color: _canResend ? _primaryColor : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 4. ปุ่มยืนยัน
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Verify",
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

  Widget _buildOtpInput(int index) {
    return Container(
      width: 45,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5)
            _focusNodes[index + 1].requestFocus();
          if (value.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();
          if (value.isNotEmpty && index == 5)
            _handleVerify(); // พิมพ์ครบ 6 ตัวให้ Verify ทันที
        },
      ),
    );
  }
}
