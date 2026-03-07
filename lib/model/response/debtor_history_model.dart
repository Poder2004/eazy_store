class PaymentHistoryResponse {
  final int paymentId;
  final double amountPaid;
  final String method;
  final double remainingDebt;
  final String date;
  final String recordedBy;

  PaymentHistoryResponse({
    required this.paymentId,
    required this.amountPaid,
    required this.method,
    required this.remainingDebt,
    required this.date,
    required this.recordedBy,
  });

  factory PaymentHistoryResponse.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryResponse(
      paymentId: json['payment_id'] ?? 0,
      amountPaid: (json['amount_paid'] ?? 0).toDouble(),
      method: json['method'] ?? '-',
      remainingDebt: (json['remaining_debt'] ?? 0).toDouble(),
      date: json['date'] ?? '-',
      recordedBy: json['recorded_by'] ?? '-',
    );
  }
}