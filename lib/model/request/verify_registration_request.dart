class VerifyRegistrationRequest {
  final String email;
  final String otp;
  VerifyRegistrationRequest({required this.email, required this.otp});
  Map<String, dynamic> toJson() => {"email": email, "otp": otp};
}
