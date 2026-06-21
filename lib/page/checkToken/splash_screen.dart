import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    await Future.delayed(const Duration(seconds: 2));

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    int? shopId = prefs.getInt('shopId');

    if (token == null || token.isEmpty) {
      // ไม่มี token → ไปหน้า Login
      Get.off(() => const LoginPage());
    } else if (shopId == null || shopId == 0) {
      // มี token แต่ยังไม่ได้เลือกร้านค้า → ไปหน้า MyShop
      Get.off(() => const MyShopPage());
    } else {
      // มีทั้ง token และ shopId → เข้าหน้า Home ได้เลย
      Get.off(() => const HomePage());
    }
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
