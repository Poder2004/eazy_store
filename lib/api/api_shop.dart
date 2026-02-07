import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/request/create_shop_request.dart';
import 'package:eazy_store/config/app_config.dart';
import '../model/response/shop_response.dart';

class ApiShop {

  // ไม่ต้องรับ File แยกแล้ว เพราะมันอยู่ใน request object แล้ว
  Future<bool> createShop(CreateShopRequest request) async {
    final url = Uri.parse("${AppConfig.baseUrl}/api/createShop"); // เช็ค path ให้ตรงกับ router go (/api/createShop หรือ /createShop)

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: request.toRawJson(), // ส่ง JSON ที่มี Base64 รูปภาพอยู่ข้างใน
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("Error API: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("Exception: $e");
      return false;
    }
  }

  Future<List<ShopResponse>> getShops() async {
    final url = Uri.parse("${AppConfig.baseUrl}/api/getShop");

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // ส่ง Token ไปด้วย
        },
      );

      if (response.statusCode == 200) {
        // แปลง JSON String เป็น List<ShopResponse>
        return shopResponseFromJson(response.body);
      } else {
        // กรณี Error หรือ 404
        return [];
      }
    } catch (e) {
      print("Error fetching shops: $e");
      return [];
    }
  }
}