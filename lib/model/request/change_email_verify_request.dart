class ChangeEmailVerifyRequest {
  final String username;
  final String newEmail;
  ChangeEmailVerifyRequest({required this.username, required this.newEmail});
  Map<String, dynamic> toJson() => {
    "username": username,
    "new_email": newEmail,
  };
}
