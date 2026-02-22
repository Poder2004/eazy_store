import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/response/shop_response.dart';
import 'package:eazy_store/config/app_config.dart';


class ApiShop {
  // ไม่ต้องรับ File แยกแล้ว เพราะมันอยู่ใน request object แล้ว
  Future<bool> createShop(ShopResponse request) async {
    final url = Uri.parse("${AppConfig.baseUrl}/api/shops"); 

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        // ✅ 3. ใช้ toRawJson() หรือ json.encode(request.toJson())
        body: request.toRawJson(), 
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // หากสร้างสำเร็จ อาจจะดึงข้อมูลร้านค้าที่สร้างเสร็จแล้วเก็บลงเครื่อง
        // เช่น เก็บ shopId ลง SharedPreferences
        final responseData = json.decode(response.body);
        if (responseData['shop_id'] != null) {
           await prefs.setInt('shopId', responseData['shop_id']);
        }
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
    final url = Uri.parse("${AppConfig.baseUrl}/api/shops");

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return shopResponseFromJson(response.body);
      } else {
        print("API Error: ${response.statusCode} - ${response.body}");
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
        "${AppConfig.baseUrl}/api/shops/$shopId",
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
    final url = Uri.parse('${AppConfig.baseUrl}/api/shops/$shopId');

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

  // เปลี่ยนชื่อฟังก์ชันเป็น getCurrentShop 
  Future<ShopResponse?> getCurrentShop() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int currentShopId = prefs.getInt('shopId') ?? 0;

      // ถ้ายังไม่มีการเลือกร้านค้า ให้จบการทำงาน
      if (currentShopId == 0) return null;

      // ✅ ไปเรียกฟังก์ชัน getShops() ด้านบน เพื่อดึงลิสต์ร้านค้ามาทั้งหมด
      List<ShopResponse> allShops = await getShops();

      // ✅ กรองหาร้านที่ ID ตรงกับ currentShopId
      for (var shop in allShops) {
        if (shop.shopId == currentShopId) {
          return shop; // เจอแล้ว ส่งกลับไปเลย
        }
      }
    } catch (e) {
      print("Error in getCurrentShop: $e");
    }
    return null;
  }
}
