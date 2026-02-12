import 'package:eazy_store/model/request/shop_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/request/create_shop_request.dart';
import 'package:eazy_store/config/app_config.dart';
import '../model/response/shop_response.dart';

class ApiShop {
  // ไม่ต้องรับ File แยกแล้ว เพราะมันอยู่ใน request object แล้ว
  Future<bool> createShop(CreateShopRequest request) async {
    final url = Uri.parse(
      "${AppConfig.baseUrl}/api/createShop",
    ); // เช็ค path ให้ตรงกับ router go (/api/createShop หรือ /createShop)

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

  // ฟังก์ชันลบร้านค้า
  Future<bool> deleteShop(int shopId) async {
    try {
      // 1. ดึง Token จากเครื่อง (ต้องรอ await)
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString(
        'token',
      ); // **ต้องใช้ key เดียวกับตอน Login**

      // ถ้าไม่มี Token ให้ return false เลย (เพราะยังไงก็ยิงไม่ผ่าน)
      if (token == null) {
        print("Error: ไม่พบ Token ในเครื่อง");
        return false;
      }

      final url = Uri.parse(
        "${AppConfig.baseUrl}/api/deleteShop/$shopId",
      ); // เช็ค URL ให้ตรงกับ Backend

      final response = await http.delete(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // <--- **สำคัญมาก! ต้องบรรทัดนี้**
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("ลบไม่สำเร็จ: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error Delete Shop: $e");
      return false;
    }
  }

  // ฟังก์ชันแก้ไขร้านค้า
  Future<bool> updateShop(int shopId, Map<String, dynamic> data) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/updateShop/$shopId');

    try {
      // --- เพิ่มส่วนนี้เข้ามาเหมือน createShop ---
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      // -------------------------------------

      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null)
            "Authorization": "Bearer $token", // ใช้ token ที่เพิ่งดึงมา
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('แก้ไขไม่สำเร็จ: ${response.body}');
        return false;
      }
    } catch (e) {
      print("Exception Update: $e");
      return false;
    }
  }

  // เปลี่ยนชื่อฟังก์ชันเป็น getCurrentShop เพื่อสื่อความหมายให้ชัดเจน
  static Future<ShopModel?> getCurrentShop() async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/getShop');

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // ✅ 1. ดึง ID ของร้านที่ User กำลังใช้งานอยู่
      int currentShopId = prefs.getInt('shopId') ?? 0;

      // ถ้ายังไม่ได้เลือกร้าน หรือ ID เป็น 0 ให้จบการทำงานเลย
      if (currentShopId == 0) return null;

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        // Backend ส่งมาเป็น List ของร้านค้าทั้งหมดที่ User เป็นเจ้าของ
        List<dynamic> jsonList = jsonDecode(response.body);

        // ✅ 2. วนลูปหา Shop ที่ shop_id ตรงกับ currentShopId
        for (var jsonItem in jsonList) {
          ShopModel shop = ShopModel.fromJson(jsonItem);

          if (shop.shopId == currentShopId) {
            return shop; // เจอแล้ว! ส่งร้านนี้กลับไป
          }
        }

        // ถ้าวนจนจบแล้วไม่เจอ (กรณีผิดพลาด) อาจจะ return null
      } else {
        print("API Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error fetching shop: $e");
    }
    return null;
  }
}
