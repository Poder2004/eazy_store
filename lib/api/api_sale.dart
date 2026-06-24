import 'dart:convert';
import 'package:eazy_store/model/request/sales_model_request.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eazy_store/config/app_config.dart';
import 'package:eazy_store/utils/auth_guard.dart';

class ApiSale {
  static Future<Map<String, dynamic>?> createSale(SaleRequest saleData) async {
    try {
      await AuthGuard.checkAndRefreshIfNeeded();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        Uri.parse("${AppConfig.baseUrl}/api/sales"), // ✅ ต่อ URL อัตโนมัติ
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(saleData.toJson()),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        if (AuthGuard.isUnauthorized(response.statusCode)) {
          await AuthGuard.handleUnauthorized();
        }
        print("Sale API Error: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Sale API Exception: $e");
      return null;
    }
  }


  static Future<Map<String, dynamic>?> createCreditSale(SaleRequest saleData) async {
    try {
      await AuthGuard.checkAndRefreshIfNeeded();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // ยิงไปที่ Path /api/CreateCreditSale ตามที่เราตั้งค่าไว้ใน Go
      final response = await http.post(
        Uri.parse("${AppConfig.baseUrl}/api/sales/credit"), 
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(saleData.toJson()),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        if (AuthGuard.isUnauthorized(response.statusCode)) {
          await AuthGuard.handleUnauthorized();
        }
        try {
          final errorData = jsonDecode(response.body);
          print("Credit Sale Error: ${errorData['error']}");
          return {"error": errorData['error'] ?? "บันทึกไม่สำเร็จ"};
        } catch (_) {
          return {"error": "เซิร์ฟเวอร์ตอบกลับผิดพลาด (${response.statusCode})"};
        }
      }
    } catch (e) {
      print("Credit Sale Exception: $e");
      return {"error": "ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้"};
    }
  }
}
