import 'dart:async';
import 'package:eazy_store/page/auth/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:eazy_store/api/api_auth.dart';
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
  final List<FocusNode> _nodes = [];

  int _counter = 60;
  Timer? _timer;
  bool _isLoading = false;
  late String email, username;


  final Color primaryColor = const Color(0xFF0288D1);
  final Color bgColor = const Color(0xFFF8FBFF);

  @override
  void initState() {
    super.initState();
    email = Get.arguments['email'];
    username = Get.arguments['username'];
    
    for (int i = 0; i < 6; i++) {
      final node = FocusNode(onKeyEvent: (node, event) => _handleBackspaceKey(i, event));
    
      node.addListener(() {
        if (node.hasFocus) {
          _controllers[i].selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controllers[i].text.length,
          );
        }
      });
      _nodes.add(node);
    }
   
    _startTimer();
  }

  KeyEventResult _handleBackspaceKey(int index, KeyEvent event) {
    if (event is KeyDownEvent &&  event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&  index > 0) {
     
      _controllers[index - 1].clear();
      _nodes[index - 1].requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) c.dispose();
    for (var n in _nodes) n.dispose();
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

  void _resendCode() async {
    setState(() => _isLoading = true);

    final res = await ApiAuth.changeEmailVerify(
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
        icon: const Icon(Icons.check_circle, color: Colors.green),
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
    if (_isLoading) return;
    String otp = _controllers.map((e) => e.text).join();
    if (otp.length < 6) return;

    setState(() => _isLoading = true);
    final res = await ApiAuth.verifyRegistration(
      VerifyRegistrationRequest(email: email, otp: otp),
    );

    if (res.error == null) {
      _showSuccessDialog();
    } else {
      setState(() => _isLoading = false);
      Get.snackbar(
        "รหัสไม่ถูกต้อง",
        res.error!,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  void _showSuccessDialog() {
    // หยุด timer ก่อน เพื่อป้องกัน setState ถูกเรียกหลัง dispose
    _timer?.cancel();

    Get.dialog(
      WillPopScope(
        onWillPop: () async => false, // ป้องกันกดปุ่ม back ปิด dialog
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 70,
                  color: Colors.green,
                ),
                const SizedBox(height: 20),
                const Text(
                  "ยืนยันสำเร็จ",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "บัญชีของคุณพร้อมใช้งานแล้ว\nกรุณาเข้าสู่ระบบเพื่อเริ่มใช้งาน",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      // ปิด dialog ก่อน แล้วค่อย navigate
                      Get.back();
                      Future.microtask(() => Get.offAll(() => const LoginPage()));
                    },
                    child: const Text(
                      "ไปหน้าล็อกอิน",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }


  void _changeEmailDialog() {
    final newEmailController = TextEditingController(text: email);
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.mark_email_read_rounded,
                size: 50,
                color: Color(0xFF0288D1),
              ),
              const SizedBox(height: 16),
              const Text(
                "แก้ไขอีเมล",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "เปลี่ยนอีเมลที่จะใช้รับรหัส OTP",
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
                    borderRadius: BorderRadius.circular(15),
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
                      child: const Text(
                        "ยกเลิก",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final newEmail = newEmailController.text.trim();
                        if (!GetUtils.isEmail(newEmail)) {
                          Get.snackbar(
                            "รูปแบบอีเมลไม่ถูกต้อง",
                            "กรุณากรอกอีเมลให้ถูกต้อง",
                            backgroundColor: Colors.white,
                            colorText: Colors.black87,
                          );
                          return;
                        }
                        setState(() => email = newEmail);
                        Get.back();
                     
                        Future.delayed(const Duration(milliseconds: 300), () {
                          Get.snackbar(
                            "อัปเดตแล้ว",
                            "เปลี่ยนอีเมลเป็น $newEmail เรียบร้อย\nกรุณากด 'ส่งรหัสอีกครั้ง'",
                            backgroundColor: Colors.white,
                            colorText: Colors.black87,
                          );
                        });
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
    ).whenComplete(() {
      Future.delayed(const Duration(milliseconds: 500), () {
        newEmailController.dispose();
      });
    });
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
              const Icon(
                Icons.mail_lock_rounded,
                size: 90,
                color: Color(0xFF0288D1),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => _otpBox(i)),
              ),
              const SizedBox(height: 40),
              if (_isLoading)
                const CircularProgressIndicator()
              else ...[
                TextButton(
                  onPressed: _counter == 0 ? _resendCode : null,
                  child: Text(
                    _counter == 0
                        ? "ส่งรหัสอีกครั้ง"
                        : "ส่งอีกครั้งใน ($_counter)",
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
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _otpBox(int i) {
    return Container(
      width: 45,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        
        border: Border.all(
          color: _nodes[i].hasFocus ? primaryColor : Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
       
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
        ),
        onTap: () {
        
          _controllers[i].selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controllers[i].text.length,
          );
        },
        onChanged: (v) {
        
          if (v.length > 1) {
            v = v.substring(v.length - 1);
            _controllers[i].value = TextEditingValue(
              text: v,
              selection: TextSelection.collapsed(offset: v.length),
            );
          }
         
          if (v.isNotEmpty && i < 5) _nodes[i + 1].requestFocus();
          if (i == 5 && v.isNotEmpty) _verify();
        },
      ),
    );
  }
}
