class ResetResponse {
  String message;
  String? error;

  ResetResponse({required this.message, this.error});

  factory ResetResponse.fromJson(Map<String, dynamic> json) {
    return ResetResponse(message: json['message'] ?? "", error: json['error']);
  }
}
