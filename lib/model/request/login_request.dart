class LoginRequest {
  String
  username; // ใช้ชื่อ username ตามที่ Backend Go กำหนด (แม้จะเป็น email/phone)
  String password;

  LoginRequest({required this.username, required this.password});

  // แปลงข้อมูลเป็น JSON เพื่อส่งไป Backend
  Map<String, dynamic> toJson() {
    return {"username": username, "password": password};
  }
}
