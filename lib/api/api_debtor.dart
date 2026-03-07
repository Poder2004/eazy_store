import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eazy_store/config/app_config.dart';
import '../model/request/debtor_request.dart';
import '../model/response/debtor_response.dart';

class ApiDebtor {
  static Future<Map<String, dynamic>> createDebtor(
    DebtorRequest debtorData,
  ) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/debtors');

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
          "data": DebtorResponse.fromJson(
            responseData['data'],
          ), // ใช้ fromJson จาก Response Model
        };
      } else {
        return {
          "success": false,
          "message": responseData['error'] ?? "เกิดข้อผิดพลาด",
        };
      }
    } catch (e) {
      return {"success": false, "message": "เชื่อมต่อเซิร์ฟเวอร์ล้มเหลว: $e"};
    }
  }

  // --- เพิ่มฟังก์ชันค้นหาลูกหนี้ ---
  static Future<List<DebtorResponse>> searchDebtor(String keyword) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      int? shopId = prefs.getInt('shopId'); // ดึง shopId จากเครื่อง

      // Backend เช็คว่า shopID == "" จะ error ดังนั้นต้องเช็คตรงนี้ก่อน
      if (token == null || shopId == null) {
        // ถ้าไม่มี shopId ไม่ควรยิง request ไป เพราะ backend จะด่าว่า 400 Bad Request
        print("Error: Token or ShopID is missing");
        return [];
      }

      // สร้าง URL พร้อม Query Parameters
      final uri = Uri.parse('${AppConfig.baseUrl}/api/debtors/search');

      // ✅ ต้องใช้ key ว่า 'keyword' และ 'shop_id' ให้ตรงกับ c.Query() ใน Go
      final url = uri.replace(
        queryParameters: {
          'keyword': keyword, // ตรงกับ c.Query("keyword")
          'shop_id': shopId.toString(), // ตรงกับ c.Query("shop_id")
        },
      );

      print("Calling API: $url"); // Log ดู URL ที่ยิงออกไป

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        // กรณีเจอข้อมูล
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => DebtorResponse.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        // กรณี Backend ตอบว่า "ไม่พบข้อมูลลูกหนี้"
        return [];
      } else {
        // กรณี Error อื่นๆ เช่น 400 (ลืมส่ง shop_id) หรือ 500
        print("API Error: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      print("Exception in searchDebtor: $e");
      return [];
    }
  }

  static Future<dynamic> getDebtorsByShop(
    int shopId, {
  int? page,
  int? limit,
  String? search,
}) async {
  String urlString = '${AppConfig.baseUrl}/api/debtors?shop_id=$shopId';
  if (page != null) urlString += '&page=$page';
  if (limit != null) urlString += '&limit=$limit';
  if (search != null && search.isNotEmpty) urlString += '&search=$search';

  final url = Uri.parse(urlString);
    try {
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
        var body = jsonDecode(response.body);
        if (body is Map<String, dynamic> && body.containsKey('items')) {
          return DebtorPagedResponse.fromJson(body);
        }
        return (body as List).map((i) => DebtorResponse.fromJson(i)).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getDebtorHistory(int debtorId) async {
    // สร้าง URL: /api/debtor/{id}/history
    final Uri url = Uri.parse(
      '${AppConfig.baseUrl}/api/debtors/$debtorId/history',
    );

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      print("Calling API: $url"); // Log ดู URL

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // API ส่งข้อมูลกลับมาเป็น Object {} ของลูกหนี้พร้อมประวัติ
        // เรา decode เป็น Map<String, dynamic> แล้วส่งกลับไปให้ UI ใช้ได้เลย
        return jsonDecode(response.body);
      } else {
        // กรณี Error อื่นๆ เช่น 400, 404, 500
        print("API Error: ${response.statusCode} - ${response.body}");
        return null; // คืนค่า null เพื่อบอก UI ว่าโหลดไม่สำเร็จ
      }
    } catch (e) {
      print("Exception in getDebtorHistory: $e");
      return null;
    }
  }
}
