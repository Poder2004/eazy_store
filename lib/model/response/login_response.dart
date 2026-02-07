class LoginResponse {
  final String message;
  final String? token;
  final UserData? user;
  final String? error;
  final String? email; // ✨ เพิ่มฟิลด์นี้เพื่อรับค่าอีเมลจริงจาก Backend
  final String? username; // ✨ เพิ่มเพื่อรับค่า Username จริง

  LoginResponse({
    required this.message,
    this.token,
    this.user,
    this.error,
    this.email, // เพิ่มใน constructor
    this.username, // เพิ่มใน constructor
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message'] ?? "",
      token: json['token'],
      user: json['user'] != null ? UserData.fromJson(json['user']) : null,
      error: json['error'],
      email: json['email'], // ✨ Map ค่าจาก json key 'email'
      username: json['username'], // ✨ Map ค่าจาก JSON
    );
  }
}

class UserData {
  final int id;
  final String username;
  final String email;
  final String phone;

  UserData({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? 0,
      username: json['username'] ?? "",
      email: json['email'] ?? "",
      phone: json['phone'] ?? "",
    );
  }
}
