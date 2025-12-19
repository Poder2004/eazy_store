class RegisterResponse {
  final String? message;
  final String? error;
  final Map<String, dynamic>?
  data; // เพิ่มส่วน data เผื่อเอาไปใช้ (เช่น user_id)

  RegisterResponse({this.message, this.error, this.data});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      // ถ้า Backend ส่ง "message" มา ให้รับค่ามาเก็บไว้
      message: json['message'],
      // ถ้า Backend ส่ง "error" มา (กรณีพัง)
      error: json['error'],
      // เก็บก้อน data (user_id, email, etc.)
      data: json['data'] != null ? json['data'] as Map<String, dynamic> : null,
    );
  }
}
