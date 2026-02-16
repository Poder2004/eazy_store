import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/request/pay_debt_request.dart'; // Import Model ของคุณ
import 'package:eazy_store/config/app_config.dart';

class ApiPayment {

  static Future<Map<String, dynamic>> payDebt(PayDebtRequest request) async {
    try {
      // 1. ดึง Token จากเครื่อง
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // 2. ยิง API ไปที่ /api/paymentDebt
      final response = await http.post(
        Uri.parse("${AppConfig.baseUrl}/api/paymentDebt"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // แนบ Token ไปด้วย
        },
        body: jsonEncode(request.toJson()), // แปลง Model เป็น JSON
      );

      // 3. แปลงข้อมูลตอบกลับ
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // ✅ สำเร็จ: ส่งข้อมูลกลับไป (มี message, new_debt, payment_id)
        return responseData; 
      } else {
        // ❌ ไม่สำเร็จ: ส่ง error กลับไป
        print("Pay Debt Error: ${responseData['error']}");
        return {"error": responseData['error'] ?? "เกิดข้อผิดพลาดในการชำระเงิน"};
      }
    } catch (e) {
      // ❌ Error การเชื่อมต่อ
      print("Pay Debt Exception: $e");
      return {"error": "ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้"};
    }
  }
}