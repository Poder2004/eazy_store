import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eazy_store/config/app_config.dart';

class ApiUser {
  // ✅ 1. ฟังก์ชันดึงข้อมูลโปรไฟล์ล่าสุด (GET)
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final url = Uri.parse(
        '${AppConfig.baseUrl}/api/profile',
      ); // ต้องเพิ่มเส้นนี้ใน Go ด้วยนะ

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // คืนค่าเป็น Map (JSON)
      } else {
        print("Get Profile Error: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Get Profile Exception: $e");
      return null;
    }
  }

  // ✅ 2. ฟังก์ชันอัปเดตข้อมูลโปรไฟล์ (PUT)
  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> updateData,
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final url = Uri.parse('${AppConfig.baseUrl}/api/profile/update');

      final response = await http.put(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(
          updateData,
        ), // ส่งแค่ฟิลด์ที่ถูกแก้ไขไป (Partial Update)
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // สำเร็จ (statusCode 200)
      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": responseData['message'],
          "user": responseData['user'],
          "require_auth":
              responseData['require_auth'] ??
              false, // 🔥 เช็คว่าต้องยืนยันอีเมลไหม
        };
      } else {
        // กรณี Error เช่น อีเมลซ้ำ ชื่อซ้ำ
        return {
          "success": false,
          "error": responseData['error'] ?? "อัปเดตข้อมูลไม่สำเร็จ",
        };
      }
    } catch (e) {
      return {"success": false, "error": "การเชื่อมต่อขัดข้อง: $e"};
    }
  }
}
