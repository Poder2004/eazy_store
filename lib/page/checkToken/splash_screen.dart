import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/api_health.dart';
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

  // ปลุกเซิร์ฟเวอร์ (Render ฟรีหลับเมื่อไม่มีคนใช้) — ถ้ารอเกิน 4 วิ ให้บอกผู้ใช้ว่ากำลังเชื่อมต่อ
  bool _serverReady = false;
  bool _showSlowHint = false;

  @override
  void initState() {
    super.initState();

    ApiHealth.wakeUp().whenComplete(() {
      if (mounted) setState(() => _serverReady = true);
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && !_serverReady) setState(() => _showSlowHint = true);
    });

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

    await AuthGuard.checkAndRefreshIfNeeded();

    // ยืนยันกับ backend ว่า token ยังใช้ได้
    bool isTokenValid = await ApiUser.verifyToken();
    if (!isTokenValid) {
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

      await GoogleFonts.pendingFonts().timeout(
        const Duration(seconds: 5),
        onTimeout: () => [],
      );
    } catch (_) {}
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
      body: Stack(
        children: [
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Image.asset("assets/image/playstore-icon.png", width: 200),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 80,
            child: AnimatedOpacity(
              opacity: _showSlowHint && !_serverReady ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: Text(
                'กำลังเชื่อมต่อเซิร์ฟเวอร์... อาจใช้เวลาครู่หนึ่ง',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
