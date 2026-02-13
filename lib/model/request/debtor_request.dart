class DebtorRequest {
  final int shopId;
  final String name;
  final String phone;
  final String address;
  final String imgDebtor;
  final double creditLimit;
  final double currentDebt;

  DebtorRequest({
    required this.shopId,
    required this.name,
    required this.phone,
    required this.address,
    required this.imgDebtor,
    required this.creditLimit,
    required this.currentDebt,
  });

  Map<String, dynamic> toJson() {
    return {
      "shop_id": shopId,
      "name": name,
      "phone": phone,
      "address": address,
      "img_debtor": imgDebtor,
      "credit_limit": creditLimit,
      "current_debt": currentDebt,
    };
  }
}