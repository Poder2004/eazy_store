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

  //หมวดสินค้า
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

  // ค้นหาสินค้า (Search) ตาม Barcode หรือ Product Code

  static Future<Product?> searchProduct(String keyword) async {
    final url = Uri.parse(
      '${AppConfig.baseUrl}/api/product/search?keyword=$keyword',
    );

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
        final data = jsonDecode(response.body);
        return Product.fromJson(data); // <--- เรียกใช้ Model ที่คุณเพิ่งเขียน
      } else {
        print("Product not found: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error searching product: $e");
      return null;
    }
  }

  // อัปเดตสต็อก (Update Stock)
  static Future<bool> updateStock(int productId, int amountToAdd) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/product/stock');

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "product_id": productId,
          "stock":
              amountToAdd, // ส่งจำนวนที่ต้องการเพิ่มไป (Backend จะไป + เอง)
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Update failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error updating stock: $e");
      return false;
    }
  }

  // ✅ ใช้ฟังก์ชันนี้แทน (ส่ง JSON Update ปกติ)
  static Future<Product?> updateProduct(
    int productId,
    Map<String, dynamic> updateData,
  ) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/products/$productId');

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json", // ส่งเป็น JSON
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(updateData), // ส่งข้อมูลรวมถึง URL รูปภาพไปในนี้
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return Product.fromJson(jsonResponse['data']);
      } else {
        print("Update failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error updating product: $e");
      return null;
    }
  }

 static Future<List<dynamic>> getNullBarcodeProducts(int shopId, {int? categoryId}) async {
    // สร้าง URL พื้นฐานที่มี shop_id
    String urlString = '${AppConfig.baseUrl}/api/getNullBarcode?shop_id=$shopId';
    
    // ถ้ามีการส่ง categoryId มา (และไม่ใช่ค่าว่าง/0) ให้ต่อท้าย URL
    if (categoryId != null && categoryId != 0) {
      urlString += '&category_id=$categoryId';
    }

    final url = Uri.parse(urlString);

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
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to load products: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error connecting to API: $e");
    }
  }
}
