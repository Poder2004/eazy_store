class VerifyOtpRequest {
  String email;
  String otpCode;

  VerifyOtpRequest({required this.email, required this.otpCode});

  Map<String, dynamic> toJson() {
    return {"email": email, "otp_code": otpCode};
  }
}
