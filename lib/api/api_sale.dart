import 'dart:convert';
import 'package:eazy_store/model/request/sales_model_request.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eazy_store/config/app_config.dart';

class ApiSale {
  static Future<Map<String, dynamic>?> createSale(SaleRequest saleData) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        Uri.parse("${AppConfig.baseUrl}/api/createSale"), // ✅ ต่อ URL อัตโนมัติ
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(saleData.toJson()),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Sale API Error: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Sale API Exception: $e");
      return null;
    }
  }
}
