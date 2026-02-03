class UpdatePasswordRequest {
  String email;
  String otpCode;
  String newPassword;

  UpdatePasswordRequest({
    required this.email,
    required this.otpCode,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {"email": email, "otp_code": otpCode, "new_password": newPassword};
  }
}
