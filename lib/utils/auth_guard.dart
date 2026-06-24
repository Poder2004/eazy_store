import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eazy_store/config/app_config.dart';
import 'package:eazy_store/page/auth/login.dart';

class AuthGuard {
  // ป้องกันการ refresh ซ้อนกัน
  static bool _isRefreshing = false;

  /// เรียก /api/auth/refresh เพื่อขอ access_token ใหม่
  static Future<bool> refreshToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? refreshToken = prefs.getString('refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/auth/refresh'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refresh_token": refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['access_token'] as String?;
        final expiresIn = (data['expires_in'] as int?) ?? 900;
        if (newToken == null) return false;

        final expiresAt = DateTime.now().millisecondsSinceEpoch ~/ 1000 + expiresIn;
        await prefs.setString('token', newToken);
        await prefs.setInt('token_expires_at', expiresAt);
        return true;
      }
      return false;
    } catch (e) {
      print("refreshToken error: $e");
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// เช็คก่อนทุก API call — ถ้า token เหลือ < 60 วินาที ให้ refresh ก่อน
  static Future<void> checkAndRefreshIfNeeded() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final expiresAt = prefs.getInt('token_expires_at') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (expiresAt > 0 && now > expiresAt - 60) {
        await refreshToken();
      }
    } catch (e) {
      print("checkAndRefreshIfNeeded error: $e");
    }
  }

  /// เรียกเมื่อได้รับ 401 — ลอง refresh ก่อน ถ้าไม่ได้ค่อย logout
  static Future<void> handleUnauthorized() async {
    bool refreshed = await refreshToken();
    if (refreshed) {
      Get.snackbar(
        "Session ต่ออายุแล้ว",
        "กรุณาลองใหม่อีกครั้ง",
        backgroundColor: Get.theme.colorScheme.surface,
        duration: const Duration(seconds: 3),
      );
    } else {
      await _clearSessionAndLogout();
    }
  }

  static Future<void> _clearSessionAndLogout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // แจ้ง backend ให้ยกเลิก refresh token ด้วย (best effort)
    try {
      final token = prefs.getString('token');
      if (token != null) {
        await http.post(
          Uri.parse('${AppConfig.baseUrl}/api/auth/logout'),
          headers: {"Authorization": "Bearer $token"},
        ).timeout(const Duration(seconds: 3));
      }
    } catch (_) {}

    await prefs.remove('token');
    await prefs.remove('refresh_token');
    await prefs.remove('token_expires_at');
    await prefs.remove('shopId');
    await prefs.remove('shopName');
    Get.offAll(() => const LoginPage());
  }

  static bool isUnauthorized(int statusCode) => statusCode == 401;
}
