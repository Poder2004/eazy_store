import 'dart:convert';
import 'dart:typed_data'; // สำหรับจัดการ Byte ข้อมูล PDF
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eazy_store/config/app_config.dart';

class ApiOrderList {
  // ฟังก์ชันยิง API เพื่อขอไฟล์ PDF
  static Future<Uint8List?> exportOrderPdf(Map<String, dynamic> data) async {
    final Uri url = Uri.parse('${AppConfig.baseUrl}/api/orderlist');

    try {
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
        // คืนค่ากลับเป็น bytes เพื่อเอาไปเขียนไฟล์ในเครื่อง
        return response.bodyBytes;
      } else {
        print("API Error (Export PDF): ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Exception in exportOrderPdf: $e");
      return null;
    }
  }
}