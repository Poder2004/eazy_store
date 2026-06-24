import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/request/pay_debt_request.dart';
import 'package:eazy_store/config/app_config.dart';
import 'package:eazy_store/utils/auth_guard.dart';

class ApiPayment {

  static Future<Map<String, dynamic>> payDebt(PayDebtRequest request) async {
    try {
      await AuthGuard.checkAndRefreshIfNeeded();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        Uri.parse("${AppConfig.baseUrl}/api/payments"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(request.toJson()),
      );

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (_) {
        return {"error": "เซิร์ฟเวอร์ตอบกลับผิดพลาด กรุณาลองใหม่"};
      }

      if (response.statusCode == 200) {
        return responseData;
      } else {
        if (AuthGuard.isUnauthorized(response.statusCode)) {
          await AuthGuard.handleUnauthorized();
        }
        print("Pay Debt Error: ${responseData['error']}");
        return {"error": responseData['error'] ?? "เกิดข้อผิดพลาดในการชำระเงิน"};
      }
    } catch (e) {
      print("Pay Debt Exception: $e");
      return {"error": "ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้"};
    }
  }

  static Future<List<dynamic>?> getPaymentHistory(int debtorId) async {
    final Uri url = Uri.parse('${AppConfig.baseUrl}/api/payments/$debtorId');

    try {
      await AuthGuard.checkAndRefreshIfNeeded();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body);
        } catch (_) {
          return null;
        }
      } else {
        if (AuthGuard.isUnauthorized(response.statusCode)) {
          await AuthGuard.handleUnauthorized();
        }
        print("API Error (Payments): ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Exception in getPaymentHistory: $e");
      return null;
    }
  }
}