import 'dart:convert';
import 'dart:typed_data'; // สำหรับจัดการ Byte ข้อมูล PDF
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eazy_store/config/app_config.dart';
import 'package:eazy_store/utils/auth_guard.dart';

class ApiOrderList {
  // ฟังก์ชันยิง API เพื่อขอไฟล์ PDF
  static Future<Uint8List?> exportOrderPdf(Map<String, dynamic> data) async {
    final Uri url = Uri.parse('${AppConfig.baseUrl}/api/orderlist');

    try {
      await AuthGuard.checkAndRefreshIfNeeded();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        if (AuthGuard.isUnauthorized(response.statusCode)) {
          await AuthGuard.handleUnauthorized();
        }
        print("API Error (Export PDF): ${response.statusCode}");
        print("API Error Response Body (Export PDF): ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception in exportOrderPdf: $e");
      return null;
    }
  }
}