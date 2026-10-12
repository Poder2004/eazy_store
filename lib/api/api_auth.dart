import 'dart:convert';
import 'package:eazy_store/model/request/register_request.dart';
import 'package:eazy_store/model/request/reset_request.dart';
import 'package:eazy_store/model/request/update_password_request.dart';
import 'package:eazy_store/model/request/verify_otp_request.dart';
import 'package:eazy_store/model/request/verify_registration_request.dart';
import 'package:eazy_store/model/request/change_email_verify_request.dart';
import 'package:eazy_store/model/response/register_response.dart';
import 'package:eazy_store/model/response/reset_response.dart';
import 'package:eazy_store/model/response/update_password_response.dart';
import 'package:eazy_store/model/response/verify_otp_response.dart';
import 'package:http/http.dart' as http;
import 'package:eazy_store/config/app_config.dart'; // import config ของคุณ
import 'package:eazy_store/model/request/login_request.dart';
import 'package:eazy_store/model/response/login_response.dart';

class ApiAuth {
  static Future<LoginResponse> login(LoginRequest request) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(request.toJson()),
      );

      print("Status Code: ${response.statusCode}");
      print("Body: ${response.body}");

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 ||
          response.statusCode == 403 ||
          response.statusCode == 401) {
        return LoginResponse.fromJson(responseData);
      } else {
        return LoginResponse(
          message: "ผิดพลาด",
          error:
              responseData['error'] ??
              "เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุจากเซิร์ฟเวอร์",
        );
      }
    } catch (e) {
      // กรณีเชื่อมต่อไม่ได้ (เน็ตหลุด, Server ปิด)
      return LoginResponse(
        message: "ผิดพลาด",
        error:
            "ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้ กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่",
      );
    }
  }

  static Future<RegisterResponse> register(RegisterRequest request) async {
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
        return RegisterResponse.fromJson(responseData);
      } else {
        return RegisterResponse(
          message: "ผิดพลาด",
          error: responseData['error'] ?? "เกิดข้อผิดพลาดจากเซิร์ฟเวอร์",
        );
      }
    } catch (e) {
      return RegisterResponse(
        message: "ผิดพลาด",
        error:
            "ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้ กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่",
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
          message: "ผิดพลาด",
          error: responseData['error'] ?? "ไม่สามารถส่งคำขอได้",
        );
      }
    } catch (e) {
      return ResetResponse(
        message: "ผิดพลาด",
        error: "การเชื่อมต่อขัดข้อง กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่",
      );
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
          message: "ผิดพลาด",
          error: responseData['error'] ?? "รหัส OTP ไม่ถูกต้อง",
        );
      }
    } catch (e) {
      return VerifyOtpResponse(
        message: "ผิดพลาด",
        error: "การเชื่อมต่อขัดข้อง กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่",
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
          message: "ผิดพลาด",
          error: responseData['error'] ?? "ไม่สามารถเปลี่ยนรหัสผ่านได้",
        );
      }
    } catch (e) {
      return UpdatePasswordResponse(
        message: "ผิดพลาด",
        error: "การเชื่อมต่อขัดข้อง กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่",
      );
    }
  }

  static Future<RegisterResponse> verifyRegistration(
    VerifyRegistrationRequest request,
  ) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/auth/verify-registration');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(request.toJson()),
      );
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return RegisterResponse.fromJson(responseData);
    } catch (e) {
      return RegisterResponse(
        error: "เชื่อมต่อไม่สำเร็จ กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่",
      );
    }
  }

  static Future<RegisterResponse> changeEmailVerify(
    ChangeEmailVerifyRequest request,
  ) async {
    final url = Uri.parse('${AppConfig.baseUrl}/api/auth/change-email-verify');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(request.toJson()),
      );
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return RegisterResponse.fromJson(responseData);
    } catch (e) {
      return RegisterResponse(
        error: "เชื่อมต่อไม่สำเร็จ กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่",
      );
    }
  }
}
