class ResetRequest {
  String email;

  ResetRequest({required this.email});

  Map<String, dynamic> toJson() {
    return {"email": email};
  }
}
