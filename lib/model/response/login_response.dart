class LoginResponse {
  final String message;
  final String? token;         // backward compat (token เดิม)
  final String? accessToken;   // access_token จาก spec ใหม่
  final String? refreshToken;  // refresh_token
  final int? expiresIn;        // expires_in (วินาที)
  final UserData? user;
  final String? error;
  final String? email;
  final String? username;

  LoginResponse({
    required this.message,
    this.token,
    this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.user,
    this.error,
    this.email,
    this.username,
  });

  // ดึง access token ที่ใช้จริง (รองรับทั้ง format เก่าและใหม่)
  String? get effectiveToken => accessToken ?? token;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message'] ?? "",
      token: json['token'],
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      expiresIn: json['expires_in'],
      user: json['user'] != null ? UserData.fromJson(json['user']) : null,
      error: json['error'],
      email: json['email'],
      username: json['username'],
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
