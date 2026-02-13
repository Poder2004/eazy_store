import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eazy_store/config/app_config.dart';
import '../model/request/debtor_request.dart';    
import '../model/response/debtor_response.dart';  

class ApiDebtor {
  static Future<Map<String, dynamic>> createDebtor(DebtorRequest debtorData) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/createDebtor');

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(debtorData.toJson()), // ใช้ toJson จาก Request Model
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": responseData['message'],
          "data": DebtorResponse.fromJson(responseData['data']) // ใช้ fromJson จาก Response Model
        };
      } else {
        return {
          "success": false,
          "message": responseData['error'] ?? "เกิดข้อผิดพลาด"
        };
      }
    } catch (e) {
      return {"success": false, "message": "เชื่อมต่อเซิร์ฟเวอร์ล้มเหลว: $e"};
    }
  }
}