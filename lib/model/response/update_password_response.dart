class UpdatePasswordResponse {
  String message;
  String? error;

  UpdatePasswordResponse({required this.message, this.error});

  factory UpdatePasswordResponse.fromJson(Map<String, dynamic> json) {
    return UpdatePasswordResponse(
      message: json['message'] ?? "",
      error: json['error'],
    );
  }
}
