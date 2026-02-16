import 'dart:convert';

class PayDebtRequest {
  final int shopId;
  final int debtorId;
  final double amountPaid;
  final String paymentMethod;
  final String payWith;
  final String pinCode;

  PayDebtRequest({
    required this.shopId,
    required this.debtorId,
    required this.amountPaid,
    required this.paymentMethod,
    required this.payWith,
    required this.pinCode,
  });

  // แปลงข้อมูลเป็น JSON เพื่อส่งให้ Server
  Map<String, dynamic> toJson() {
    return {
      "shop_id": shopId,
      "debtor_id": debtorId,
      "amount_paid": amountPaid,
      "payment_method": paymentMethod,
      "pay_with": payWith,
      "pin_code": pinCode,
    };
  }
}