import 'dart:convert';
import 'package:eazy_store/model/request/register_request.dart';
import 'package:eazy_store/model/request/reset_request.dart';
import 'package:eazy_store/model/request/update_password_request.dart';
import 'package:eazy_store/model/request/verify_otp_request.dart';
import 'package:eazy_store/model/response/register_response.dart';
import 'package:eazy_store/model/response/reset_response.dart';
import 'package:eazy_store/model/response/update_password_response.dart';
import 'package:eazy_store/model/response/verify_otp_response.dart';
import 'package:http/http.dart' as http;
import 'package:eazy_store/config/app_config.dart'; // import config ของคุณ
import 'package:eazy_store/model/request/login_request.dart';
import 'package:eazy_store/model/response/login_response.dart';

class ApiService {
  // ฟังก์ชัน Login
  static Future<LoginResponse> login(LoginRequest request) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(request.toJson()), // แปลงข้อมูลเป็น JSON
      );

      print("Status Code: ${response.statusCode}");
      print("Body: ${response.body}");

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // กรณีสำเร็จ (200 OK)
        return LoginResponse.fromJson(responseData);
      } else {
        // กรณี Server ตอบ Error กลับมา (เช่น 400, 401, 500)
        return LoginResponse(
          message: "Error",
          error: responseData['error'] ?? "เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ",
        );
      }
    } catch (e) {
      // กรณีเชื่อมต่อไม่ได้ (เน็ตหลุด, Server ปิด)
      return LoginResponse(
        message: "Error",
        error: "ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้: $e",
      );
    }
  }

  // ฟังก์ชัน Register (เพิ่มใหม่)
  // ---------------------------------------------------------
  static Future<RegisterResponse> register(RegisterRequest request) async {
    // URL ปลายทาง (ระวังเรื่อง IP Address ถ้าใช้ Emulator/เครื่องจริง)
    final url = Uri.parse('${AppConfig.baseUrl}/api/auth/register');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(request.toJson()), // แปลง Model เป็น JSON
      );

      print("Register Status: ${response.statusCode}");
      print("Register Body: ${response.body}");

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // สำเร็จ (200 OK)
        return RegisterResponse.fromJson(responseData);
      } else {
        // ไม่สำเร็จ (เช่น 400, 500) มี Error กลับมา
        return RegisterResponse(
          message: "Error",
          error: responseData['error'] ?? "เกิดข้อผิดพลาดจากเซิร์ฟเวอร์",
        );
      }
    } catch (e) {
      // เชื่อมต่อไม่ได้
      return RegisterResponse(
        message: "Error",
        error: "ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้: $e",
      );
    }
  }

  // ✨ ฟังก์ชันสำหรับขอรหัส OTP
  static Future<ResetResponse> requestResetOTP(ResetRequest request) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/auth/request-reset');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(request.toJson()),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ResetResponse.fromJson(responseData);
      } else {
        return ResetResponse(
          message: "Error",
          error: responseData['error'] ?? "ไม่สามารถส่งคำขอได้",
        );
      }
    } catch (e) {
      return ResetResponse(message: "Error", error: "การเชื่อมต่อขัดข้อง: $e");
    }
  }

  static Future<VerifyOtpResponse> verifyOTP(VerifyOtpRequest request) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/auth/verify-otp');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(request.toJson()),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return VerifyOtpResponse.fromJson(responseData);
      } else {
        return VerifyOtpResponse(
          message: "Error",
          error: responseData['error'] ?? "รหัส OTP ไม่ถูกต้อง",
        );
      }
    } catch (e) {
      return VerifyOtpResponse(
        message: "Error",
        error: "การเชื่อมต่อขัดข้อง: $e",
      );
    }
  }

  static Future<UpdatePasswordResponse> updatePassword(
    UpdatePasswordRequest request,
  ) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/auth/reset-password');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(request.toJson()),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return UpdatePasswordResponse.fromJson(responseData);
      } else {
        return UpdatePasswordResponse(
          message: "Error",
          error: responseData['error'] ?? "ไม่สามารถเปลี่ยนรหัสผ่านได้",
        );
      }
    } catch (e) {
      return UpdatePasswordResponse(
        message: "Error",
        error: "การเชื่อมต่อขัดข้อง: $e",
      );
    }
  }
}
