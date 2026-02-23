import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  // static String get baseUrl {
  //   if (kIsWeb) return 'http://localhost:8080';

  //   // ถ้าเป็น Android Emulator ต้องใช้ 10.0.2.2
  //   // ถ้าเป็นเครื่องจริง หรือ iOS ให้ใช้ IP LAN ของคุณ
  //   if (Platform.isAndroid) {
  //     // ตรงนี้อาจจะใช้ package device_info_plus เช็คว่าเป็น emulator หรือไม่
  //     return 'http://10.0.2.2:8080';
  //   }
  //   return 'http://192.168.6.1:8080';
  // }

  static const String baseUrl = "https://eazystoreapi.onrender.com";
}
