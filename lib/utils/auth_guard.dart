import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eazy_store/config/app_config.dart';
import 'package:eazy_store/page/auth/login.dart';

class AuthGuard {
  // ป้องกันการ refresh ซ้อนกันโดยใช้ Completer เพื่อให้ request อื่นรอผลลัพธ์
  static Completer<bool>? _refreshCompleter;

  /// เรียก /api/auth/refresh เพื่อขอ access_token ใหม่
  static Future<bool> refreshToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? refreshToken = prefs.getString('refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter!.complete(false);
        return false;
      }

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/auth/refresh'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refresh_token": refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['access_token'] as String?;
        final newRefreshToken = data['refresh_token'] as String?;
        final expiresIn = (data['expires_in'] as int?) ?? 900;
        if (newToken == null) {
          _refreshCompleter!.complete(false);
          return false;
        }

        final expiresAt = DateTime.now().millisecondsSinceEpoch ~/ 1000 + expiresIn;
        await prefs.setString('token', newToken);
        await prefs.setInt('token_expires_at', expiresAt);
        if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
          await prefs.setString('refresh_token', newRefreshToken);
        }
        _refreshCompleter!.complete(true);
        return true;
      }
      _refreshCompleter!.complete(false);
      return false;
    } catch (e) {
      print("refreshToken error: $e");
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
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

  static DateTime? _lastSnackbarTime;
  static bool _isLoggingOut = false;

  /// เรียกเมื่อได้รับ 401 — ลอง refresh ก่อน ถ้าไม่ได้ค่อย logout
  static Future<void> handleUnauthorized() async {
    bool refreshed = await refreshToken();
    if (refreshed) {
      final now = DateTime.now();
      // แสดง Snackbar จำกัดสูงสุด 1 ครั้งทุกๆ 10 วินาที เพื่อป้องกันการเปิดค้างหรือแสดงซ้อนกันหลายๆ อัน (Snackbar Storm)
      if (_lastSnackbarTime == null || now.difference(_lastSnackbarTime!) > const Duration(seconds: 10)) {
        _lastSnackbarTime = now;
        Get.closeAllSnackbars(); // ล้างคิว Snackbar ที่ค้างอยู่ทั้งหมดออกไปก่อน
        Get.snackbar(
          "Session ต่ออายุแล้ว",
          "กรุณาลองใหม่อีกครั้ง",
          backgroundColor: Get.theme.colorScheme.surface,
          duration: const Duration(seconds: 3),
        );
      }
    } else {
      await _clearSessionAndLogout();
    }
  }

  static Future<void> _clearSessionAndLogout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final refreshToken = prefs.getString('refresh_token');

      // ถ้าออกจากระบบไปแล้ว (ไม่มี Token ทั้งสองตัว) ไม่ต้องประมวลผลซ้ำ
      if (token == null && refreshToken == null) {
        return;
      }

      // แจ้ง backend ให้ยกเลิก refresh token ด้วย (best effort)
      try {
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
      
      Get.closeAllSnackbars(); // ล้าง Snackbar ทั้งหมดเมื่อสลับไปหน้าล็อคอิน
      Get.offAll(() => const LoginPage());
    } finally {
      _isLoggingOut = false;
    }
  }

  static bool isUnauthorized(int statusCode) => statusCode == 401;
}
