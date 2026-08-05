import 'package:eazy_store/page/checkToken/splash_screen.dart';
import 'package:eazy_store/page/sale_producct/sale/park_order_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  Get.put(ParkOrderController(), permanent: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. ปลี่ยนจุดนี้จาก MaterialApp เป็น GetMaterialApp
    return GetMaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // ✅ ให้ภาษาอังกฤษเป็นลำดับแรก (ค่าเริ่มต้น)
        Locale('th', 'TH'), // ✅ เตรียมภาษาไทยไว้ให้ปฏิทินเรียกใช้
      ],
      locale: const Locale(
        'en',
        'US',
      ), // ✅ บังคับหน้าอื่นๆ ให้เป็นอังกฤษไว้ก่อนฎ

      debugShowCheckedModeBanner: false,
      title: 'Eazy Store',
      // ✨ ใช้ฟอนต์ Prompt เป็นฟอนต์เดียวกันทั้งแอป (ของเดิม 'AbhayaLibre' ไม่ได้
      // ถูกประกาศไว้ใน pubspec.yaml เลย ทำให้ทุกหน้าตกไปใช้ฟอนต์ default ของ
      // เครื่องแทนแบบเงียบๆ โดยไม่มีใครตั้งใจ)
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.promptTextTheme(Theme.of(context).textTheme),
      ),
      home: const SplashScreen(),
    );
  }
}
