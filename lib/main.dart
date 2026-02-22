import 'package:eazy_store/page/auth/login.dart';
import 'package:eazy_store/page/homepage/home_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // 1. ต้องเพิ่ม Import นี้ครับ

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. เปลี่ยนจุดนี้จาก MaterialApp เป็น GetMaterialApp
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Eazy Store',
      theme: ThemeData(
        fontFamily: 'AbhayaLibre',
        useMaterial3: true, // แนะนำให้เปิด Material 3 เพื่อ UI ที่ดูทันสมัยขึ้น
      ),
      // จุดนี้กำหนดหน้าแรกที่จะให้แอปเปิด
      home: const LoginPage(),
    );
  }
}
