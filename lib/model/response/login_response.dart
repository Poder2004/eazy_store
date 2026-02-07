class LoginResponse {
  final String message;
  final String? token;
  final UserData? user;
  final String? error;

  LoginResponse({required this.message, this.token, this.user, this.error});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message'] ?? "",
      token: json['token'],
      user: json['user'] != null ? UserData.fromJson(json['user']) : null,
      error: json['error'],
    );
  }
}

class UserData {

  final int id;
  final String username;
  final String email;
  final String phone;

  UserData({
    required this.id, // แก้เป็น id
    required this.username,
    required this.email,
    required this.phone,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? 0, // แก้เป็น id รับค่าจาก json key 'id'
      username: json['username'] ?? "",
      email: json['email'] ?? "",
      phone: json['phone'] ?? "",
    );
  }
}
