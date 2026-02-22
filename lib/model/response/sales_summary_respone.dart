class SalesSummaryModel {
  final double sales;
  final double cost;
  final double profit;
  final int transactions;

  SalesSummaryModel({
    required this.sales,
    required this.cost,
    required this.profit,
    required this.transactions,
  });

  // ฟังก์ชันแปลง JSON จาก API มาเป็น Model
  factory SalesSummaryModel.fromJson(Map<String, dynamic> json) {
    return SalesSummaryModel(
      sales: (json['sales'] ?? 0).toDouble(),
      cost: (json['cost'] ?? 0).toDouble(),
      profit: (json['profit'] ?? 0).toDouble(),
      transactions: json['transactions'] ?? 0,
    );
  }
}
