import 'dart:convert';

class RegisterRequest {
  final String username; // ใน Backend รับเป็น field "username"
  final String password;
  final String email;
  final String phone;

  RegisterRequest({
    required this.username,
    required this.password,
    required this.email,
    required this.phone,
  });

  // แปลง Object เป็น JSON String เพื่อส่งให้ Server
  Map<String, dynamic> toJson() {
    return {
      "username": username,
      "password": password,
      "email": email,
      "phone": phone,
    };
  }
}
