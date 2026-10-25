import 'package:eazy_store/config/app_config.dart';
import 'package:http/http.dart' as http;

class ApiHealth {
  /// ยิงปลุกเซิร์ฟเวอร์ (และ connection ไปยังฐานข้อมูล) ตั้งแต่เปิดแอป
  ///
  /// เซิร์ฟเวอร์บน Render แพ็กเกจฟรีจะหลับเมื่อไม่มีคนใช้ ~15 นาที คำขอแรกต้องรอปลุก
  /// 30–60 วินาที การยิงตั้งแต่หน้า Splash ทำให้เซิร์ฟเวอร์ตื่นระหว่างที่ผู้ใช้ยังไม่ได้
  /// กดอะไร ผลลัพธ์ไม่สำคัญ (ล้มเหลว/ช้าแค่ไหนก็ไม่ทำให้แอปพัง) คืนค่า true ถ้าตอบกลับปกติ
  static Future<bool> wakeUp() async {
    try {
      final response = await http
          .get(Uri.parse('${AppConfig.baseUrl}/health?db=1'))
          .timeout(const Duration(seconds: 60));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
