// file: model/response/debtor_history_response.dart

class DebtorHistoryItem {
  final String name;
  final int qty;
  final double price;

  DebtorHistoryItem({required this.name, required this.qty, required this.price});

  factory DebtorHistoryItem.fromJson(Map<String, dynamic> json) {
    return DebtorHistoryItem(
      name: json['name'] ?? '',
      qty: json['qty'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
    );
  }
}

class DebtorHistoryResponse {
  final int orderId;
  final String date;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final List<DebtorHistoryItem> items;

  DebtorHistoryResponse({
    required this.orderId,
    required this.date,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.items,
  });

  factory DebtorHistoryResponse.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List?;
    List<DebtorHistoryItem> itemsList = list != null 
        ? list.map((i) => DebtorHistoryItem.fromJson(i)).toList() 
        : [];

    return DebtorHistoryResponse(
      orderId: json['order_id'],
      date: json['date'],
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      paidAmount: (json['paid_amount'] ?? 0).toDouble(),
      remainingAmount: (json['remaining_amount'] ?? 0).toDouble(),
      items: itemsList,
    );
  }
}