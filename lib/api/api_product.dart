import 'dart:convert';
import 'package:eazy_store/model/request/category_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eazy_store/config/app_config.dart';
import 'package:eazy_store/utils/auth_guard.dart';
import '../model/request/product_request.dart';
import '../model/response/product_response.dart';

class ApiProduct {
  // ฟังก์ชันสำหรับบันทึกสินค้าใหม่
  static Future<Map<String, dynamic>> createProduct(
    ProductRequest product,
  ) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/products');

    try {
      await AuthGuard.checkAndRefreshIfNeeded();
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
          "data": ProductResponse.fromJson(responseData['data']),
        };
      } else {
        if (AuthGuard.isUnauthorized(response.statusCode)) {
          await AuthGuard.handleUnauthorized();
        }
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
  static Future<List<CategoryModel>> getCategories(
    int shopId, {
    bool includeInactive = false,
  }) async {
    if (shopId == 0) return [];
    try {
      await AuthGuard.checkAndRefreshIfNeeded();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        await AuthGuard.handleUnauthorized();
        return [];
      }
      final url = Uri.parse('${AppConfig.baseUrl}/api/categories').replace(
        queryParameters: {
          'shop_id': '$shopId',
          if (includeInactive) 'include_inactive': 'true',
        },
      );

      var response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (AuthGuard.isUnauthorized(response.statusCode)) {
        await AuthGuard.handleUnauthorized();
        prefs = await SharedPreferences.getInstance();
        token = prefs.getString('token');
        if (token == null || token.isEmpty) return [];

        response = await http.get(
          url,
          headers: {"Authorization": "Bearer $token"},
        );
      }

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => CategoryModel.fromJson(item)).toList();
      }
      print("Fetch categories failed: ${response.statusCode} ${response.body}");
      return [];
    } catch (e) {
      print("Error fetching categories: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>> createCategory({
    required int shopId,
    required String name,
  }) async {
    return _sendCategoryRequest(
      method: 'POST',
      shopId: shopId,
      name: name,
    );
  }

  static Future<Map<String, dynamic>> updateCategory({
    required int categoryId,
    required int shopId,
    required String name,
  }) async {
    return _sendCategoryRequest(
      method: 'PUT',
      categoryId: categoryId,
      shopId: shopId,
      name: name,
    );
  }

  static Future<Map<String, dynamic>> deleteCategory({
    required int categoryId,
    required int shopId,
  }) async {
    return _sendCategoryRequest(
      method: 'DELETE',
      categoryId: categoryId,
      shopId: shopId,
    );
  }

  static Future<List<CategoryModel>> getInactiveCategories(int shopId) async {
    if (shopId == 0) return [];
    try {
      await AuthGuard.checkAndRefreshIfNeeded();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      if (token == null || token.isEmpty) {
        await AuthGuard.handleUnauthorized();
        return [];
      }

      final url = Uri.parse('${AppConfig.baseUrl}/api/categories/inactive')
          .replace(queryParameters: {'shop_id': '$shopId'});

      var response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (AuthGuard.isUnauthorized(response.statusCode)) {
        await AuthGuard.handleUnauthorized();
        prefs = await SharedPreferences.getInstance();
        token = prefs.getString('token');
        if (token == null || token.isEmpty) return [];
        response = await http.get(
          url,
          headers: {"Authorization": "Bearer $token"},
        );
      }

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as List<dynamic>;
        return body.map((item) => CategoryModel.fromJson(item)).toList();
      }
      print(
        "Fetch inactive categories failed: ${response.statusCode} ${response.body}",
      );
      return [];
    } catch (e) {
      print("Error fetching inactive categories: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>> restoreCategory({
    required int categoryId,
    required int shopId,
  }) async {
    try {
      await AuthGuard.checkAndRefreshIfNeeded();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final url = Uri.parse(
        '${AppConfig.baseUrl}/api/categories/$categoryId/restore',
      );
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'shop_id': shopId}),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': data};
      }
      if (AuthGuard.isUnauthorized(response.statusCode)) {
        await AuthGuard.handleUnauthorized();
      }
      return {
        'success': false,
        'error': data['error'] ?? 'ไม่สามารถกู้คืนหมวดหมู่ได้',
      };
    } catch (e) {
      return {'success': false, 'error': 'การเชื่อมต่อขัดข้อง: $e'};
    }
  }

  static Future<Map<String, dynamic>> moveCategoryProducts({
    required int fromCategoryId,
    required int toCategoryId,
    required int shopId,
    List<int>? productIds,
  }) async {
    try {
      await AuthGuard.checkAndRefreshIfNeeded();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final url = Uri.parse(
        '${AppConfig.baseUrl}/api/categories/$fromCategoryId/move-products',
      );
      final body = <String, dynamic>{
        'shop_id': shopId,
        'target_category_id': toCategoryId,
      };
      if (productIds != null && productIds.isNotEmpty) {
        body['product_ids'] = productIds;
      }
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': data};
      }
      if (AuthGuard.isUnauthorized(response.statusCode)) {
        await AuthGuard.handleUnauthorized();
      }
      return {
        'success': false,
        'error': data['error'] ?? 'ไม่สามารถย้ายสินค้าได้',
      };
    } catch (e) {
      return {'success': false, 'error': 'การเชื่อมต่อขัดข้อง: $e'};
    }
  }

  static Future<int> getCategoryProductCount({
    required int shopId,
    required int categoryId,
  }) async {
    final result = await getProductsByShop(
      shopId,
      page: 1,
      limit: 1,
      categoryId: categoryId,
    );
    if (result is ProductPagedResponse) {
      return result.totalItems;
    }
    if (result is List) {
      return result.length;
    }
    return 0;
  }

  static Future<Map<String, dynamic>> _sendCategoryRequest({
    required String method,
    required int shopId,
    int? categoryId,
    String? name,
  }) async {
    try {
      await AuthGuard.checkAndRefreshIfNeeded();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final path = categoryId == null ? '/api/categories' : '/api/categories/$categoryId';
      final requestMethod = method;
      final url = Uri.parse('${AppConfig.baseUrl}$path').replace(
        queryParameters: method == 'DELETE'
            ? {'shop_id': '$shopId'}
            : null,
      );
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final body = name == null ? null : jsonEncode({'shop_id': shopId, 'name': name});
      final response = switch (requestMethod) {
        'POST' => await http.post(url, headers: headers, body: body),
        'PUT' => await http.put(url, headers: headers, body: body),
        _ => await http.delete(url, headers: headers),
      };
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': data};
      }
      if (AuthGuard.isUnauthorized(response.statusCode)) {
        await AuthGuard.handleUnauthorized();
      }
      return {'success': false, 'error': data['error'] ?? 'ไม่สามารถจัดการหมวดหมู่ได้'};
    } catch (e) {
      return {'success': false, 'error': 'การเชื่อมต่อขัดข้อง: $e'};
    }
  }

  // ปรับเป็น Future<dynamic> เพื่อให้รับได้ทั้ง List และ ProductPagedResponse
  static Future<dynamic> getProductsByShop(
    int shopId, {
    int? page,
    int? limit,
    String? search,
    int? categoryId,
    String? sort,
  }) async {
    // 1. สร้าง URL พร้อมตรวจสอบว่ามี page และ limit หรือไม่
    String urlString = '${AppConfig.baseUrl}/api/products?shop_id=$shopId';
    if (page != null) urlString += '&page=$page';
    if (limit != null) urlString += '&limit=$limit';
    if (search != null && search.isNotEmpty) urlString += '&search=$search';
    if (categoryId != null && categoryId != 0)
      urlString += '&category_id=$categoryId';
    if (sort != null) urlString += '&sort=$sort';

    final url = Uri.parse(urlString);

    try {
      await AuthGuard.checkAndRefreshIfNeeded();
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
        var body = jsonDecode(response.body);
        if (body is Map<String, dynamic> && body.containsKey('items')) {
          return ProductPagedResponse.fromJson(body);
        } else if (body is List) {
          return body.map((item) => ProductResponse.fromJson(item)).toList();
        }
        return [];
      } else {
        if (AuthGuard.isUnauthorized(response.statusCode)) {
          await AuthGuard.handleUnauthorized();
        }
        return null;
      }
    } catch (e) {
      print("Error fetching products: $e");
      return null;
    }
  }

  // ค้นหาสินค้า (Search) ตาม Barcode หรือ Product Code

  static Future<ProductResponse?> searchProduct(
    String keyword,
    int shopId,
  ) async {
    final url = Uri.parse(
      '${AppConfig.baseUrl}/api/products/search?keyword=$keyword&shop_id=$shopId',
    );

    try {
      await AuthGuard.checkAndRefreshIfNeeded();
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
        return ProductResponse.fromJson(data);
      } else {
        if (AuthGuard.isUnauthorized(response.statusCode)) {
          await AuthGuard.handleUnauthorized();
        }
        print("Product not found: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error searching product: $e");
      return null;
    }
  }

  // อัปเดตสต็อก (Update Stock) — ถ้าระบุ productUnitId (เช่น เติมเป็น "ลัง")
  // backend จะแปลงเป็นหน่วยฐานให้เอง (สต็อกเก็บเป็นหน่วยฐานที่เดียวเสมอ)
  static Future<bool> updateStock(
    int productId,
    int amountToAdd, {
    int? productUnitId,
  }) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/products/stock');

    try {
      await AuthGuard.checkAndRefreshIfNeeded();
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
          "product_unit_id": productUnitId,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        if (AuthGuard.isUnauthorized(response.statusCode)) {
          await AuthGuard.handleUnauthorized();
        }
        print("Update failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error updating stock: $e");
      return false;
    }
  }

  // --- หน่วยขายเพิ่มเติม (ลัง/แพ็ค) ---

  static Future<Map<String, dynamic>> createProductUnit(
    int productId,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/products/$productId/units');
    try {
      await AuthGuard.checkAndRefreshIfNeeded();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {
          "success": true,
          "data": ProductUnitResponse.fromJson(data['data']),
        };
      }
      if (AuthGuard.isUnauthorized(response.statusCode)) {
        await AuthGuard.handleUnauthorized();
      }
      return {"success": false, "error": data['error'] ?? "ไม่สามารถเพิ่มหน่วยขายได้"};
    } catch (e) {
      return {"success": false, "error": "การเชื่อมต่อขัดข้อง: $e"};
    }
  }

  static Future<Map<String, dynamic>> updateProductUnit(
    int unitId,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/products/units/$unitId');
    try {
      await AuthGuard.checkAndRefreshIfNeeded();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {
          "success": true,
          "data": ProductUnitResponse.fromJson(data['data']),
        };
      }
      if (AuthGuard.isUnauthorized(response.statusCode)) {
        await AuthGuard.handleUnauthorized();
      }
      return {"success": false, "error": data['error'] ?? "ไม่สามารถแก้ไขหน่วยขายได้"};
    } catch (e) {
      return {"success": false, "error": "การเชื่อมต่อขัดข้อง: $e"};
    }
  }

  // status = 'deleted' (ลบจริง) หรือ 'hidden' (ซ่อนเพราะเคยมีประวัติขาย)
  static Future<Map<String, dynamic>> deleteProductUnit(int unitId) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/products/units/$unitId');
    try {
      await AuthGuard.checkAndRefreshIfNeeded();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.delete(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return {"success": true, "status": data['status']};
      }
      if (AuthGuard.isUnauthorized(response.statusCode)) {
        await AuthGuard.handleUnauthorized();
      }
      return {"success": false, "error": data['error'] ?? "ไม่สามารถลบหน่วยขายได้"};
    } catch (e) {
      return {"success": false, "error": "การเชื่อมต่อขัดข้อง: $e"};
    }
  }

  // ✅ ใช้ฟังก์ชันนี้แทน (ส่ง JSON Update ปกติ)
  static Future<ProductResponse?> updateProduct(
    int productId,
    Map<String, dynamic> updateData,
  ) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/products/$productId');

    try {
      await AuthGuard.checkAndRefreshIfNeeded();
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
        return ProductResponse.fromJson(jsonResponse['data']);
      } else {
        if (AuthGuard.isUnauthorized(response.statusCode)) {
          await AuthGuard.handleUnauthorized();
        }
        print("Update failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error updating product: $e");
      return null;
    }
  }

  static Future<List<dynamic>> getNullBarcodeProducts(
    int shopId, {
    int? categoryId,
  }) async {
    // สร้าง URL พื้นฐานที่มี shop_id
    String urlString =
        '${AppConfig.baseUrl}/api/products/null-barcode?shop_id=$shopId';

    // ถ้ามีการส่ง categoryId มา (และไม่ใช่ค่าว่าง/0) ให้ต่อท้าย URL
    if (categoryId != null && categoryId != 0) {
      urlString += '&category_id=$categoryId';
    }

    final url = Uri.parse(urlString);

    try {
      await AuthGuard.checkAndRefreshIfNeeded();
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
        if (AuthGuard.isUnauthorized(response.statusCode)) {
          await AuthGuard.handleUnauthorized();
        }
        throw Exception("Failed to load products: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error connecting to API: $e");
    }
  }

  // ✅ ฟังก์ชันสำหรับลบสินค้า (Smart Delete)
  static Future<Map<String, dynamic>> deleteProduct(int productId) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/products/$productId');

    try {
      await AuthGuard.checkAndRefreshIfNeeded();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.delete(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": responseData['message'],
          "status": responseData['status'], // 'deleted' หรือ 'hidden'
        };
      } else {
        return {
          "success": false,
          "error": responseData['error'] ?? "ไม่สามารถลบสินค้าได้",
        };
      }
    } catch (e) {
      return {"success": false, "error": "การเชื่อมต่อขัดข้อง: $e"};
    }
  }
}
