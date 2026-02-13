class DebtorResponse {
  final int debtorId;
  final String name;
  final String phone;
  final String address;
  final String imgDebtor;
  final double creditLimit;
  final double currentDebt;

  DebtorResponse({
    required this.debtorId,
    required this.name,
    required this.phone,
    required this.address,
    required this.imgDebtor,
    required this.creditLimit,
    required this.currentDebt,
  });

  factory DebtorResponse.fromJson(Map<String, dynamic> json) {
    return DebtorResponse(
      debtorId: json['debtor_id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      imgDebtor: json['img_debtor'] ?? '',
      creditLimit: double.tryParse(json['credit_limit']?.toString() ?? '0') ?? 0.0,
      currentDebt: double.tryParse(json['current_debt']?.toString() ?? '0') ?? 0.0,
    );
  }
}