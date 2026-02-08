import 'dart:convert';
import 'package:eazy_store/model/request/category_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eazy_store/config/app_config.dart';
import '../model/request/product_model.dart';

class ApiProduct {
  // ฟังก์ชันสำหรับบันทึกสินค้าใหม่
  static Future<Map<String, dynamic>> createProduct(Product product) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/createProduct');

    try {
      // 1. ดึง Token จาก SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // 2. ยิง API พร้อมส่ง Header Authorization (Bearer Token)
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // ส่ง Token ไปยืนยันตัวตน
        },
        body: jsonEncode(product.toJson()),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": responseData['message'],
          "data": Product.fromJson(responseData['data']),
        };
      } else {
        return {
          "success": false,
          "error": responseData['error'] ?? "ไม่สามารถบันทึกสินค้าได้",
        };
      }
    } catch (e) {
      return {"success": false, "error": "การเชื่อมต่อขัดข้อง: $e"};
    }
  }

  static Future<List<CategoryModel>> getCategories() async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/categories');
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => CategoryModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching categories: $e");
      return [];
    }
  }

  static Future<List<Product>> getProductsByShop(int shopId) async {
    // ส่ง shop_id ไปเป็น Query String
    final url = Uri.parse('${AppConfig.baseUrl}/api/products?shop_id=$shopId');

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        // Map ข้อมูล JSON กลับเป็น List ของ Object Product
        return body.map((item) => Product.fromJson(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching products: $e");
      return [];
    }
  }
}
