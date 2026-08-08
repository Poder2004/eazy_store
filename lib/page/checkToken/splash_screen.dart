import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/api_user.dart';
import '../../utils/auth_guard.dart';
import '../auth/login.dart';
import '../homepage/home_page.dart';
import '../shop/myShop/myshop.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    checkLogin();
  }

  Future<void> checkLogin() async {
    // ✅ โหลดฟอนต์ Prompt ให้เสร็จก่อนเข้าหน้าถัดไป กัน bug ตอนเปิดแอปครั้งแรกหลังติดตั้ง
    // (google_fonts จะดึงไฟล์ฟอนต์จากเน็ตตอนใช้ครั้งแรกเท่านั้น ถ้ายังโหลดไม่เสร็จตอนพิมพ์
    // ในช่อง user/password ตัวอักษรจะไม่ขึ้นจนกว่าฟอนต์จะโหลดเสร็จ) รวมกับดีเลย์ 2 วิ
    // เดิมไปเลย เพื่อไม่ให้หน้า splash ช้าลงถ้าเน็ตปกติ (โหลดฟอนต์เสร็จเร็วกว่า 2 วิอยู่แล้ว)
    await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      _warmUpFont(),
    ]);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    int? shopId = prefs.getInt('shopId');

    if (token == null || token.isEmpty) {
      Get.off(() => const LoginPage());
      return;
    }

    // ถ้า token ใกล้หมดหรือหมดแล้ว ลอง refresh ก่อน
    await AuthGuard.checkAndRefreshIfNeeded();

    // ยืนยันกับ backend ว่า token ยังใช้ได้
    bool isTokenValid = await ApiUser.verifyToken();
    if (!isTokenValid) {
      // Refresh ไม่ได้แล้ว → ล้าง session ไปหน้า Login
      await prefs.remove('token');
      await prefs.remove('refresh_token');
      await prefs.remove('token_expires_at');
      await prefs.remove('shopId');
      await prefs.remove('shopName');
      Get.off(() => const LoginPage());
      return;
    }

    if (shopId == null || shopId == 0) {
      Get.off(() => const MyShopPage());
    } else {
      Get.off(() => const HomePage());
    }
  }

  Future<void> _warmUpFont() async {
    try {
      GoogleFonts.promptTextTheme();
      // จำกัดเวลารอไว้ 5 วิ กันเน็ตช้า/ออฟไลน์ตอนเปิดแอปครั้งแรกทำให้ splash ค้าง
      // ถ้าไม่ทันก็ปล่อยผ่าน หน้าถัดไปจะ fallback ไปฟอนต์ระบบก่อนจนกว่าฟอนต์จะโหลดเสร็จเอง
      await GoogleFonts.pendingFonts().timeout(
        const Duration(seconds: 5),
        onTimeout: () => [],
      );
    } catch (_) {
      // ไม่ critical ปล่อยผ่านได้ ไม่ต้อง block การเข้าแอป
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Image.asset("assets/image/playstore-icon.png", width: 200),
        ),
      ),
    );
  }
}
