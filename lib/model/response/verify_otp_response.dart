class VerifyOtpResponse {
  String message;
  String? error;
  String? status;

  VerifyOtpResponse({required this.message, this.error, this.status});

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      message: json['message'] ?? "",
      error: json['error'],
      status: json['status'],
    );
  }
}
