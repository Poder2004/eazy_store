class SalesSummaryModel {
  final double totalRevenue; // ยอดขายรวมตามบิล (เช่น 500)
  final double actualPaid; // เงินที่ได้รับจริงเข้ากระเป๋า (เช่น 200)
  final double debtAmount; // ยอดค้างชำระที่เกิดขึ้นใหม่ (เช่น 300)
  final double cost; // ต้นทุนรวม
  final double profit; // กำไรตามบัญชี
  final int transactions; // จำนวนธุรกรรม
  final double paidCash;
  final double paidTransfer;

  SalesSummaryModel({
    required this.totalRevenue,
    required this.actualPaid,
    required this.debtAmount,
    required this.cost,
    required this.profit,
    required this.transactions,
    required this.paidCash,
    required this.paidTransfer,
  });

  // ✅ ฟังก์ชันแปลง JSON จาก API เวอร์ชันใหม่
  factory SalesSummaryModel.fromJson(Map<String, dynamic> json) {
    return SalesSummaryModel(
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      actualPaid: (json['actual_paid'] ?? 0).toDouble(),
      debtAmount: (json['debt_amount'] ?? 0).toDouble(),
      cost: (json['cost'] ?? 0).toDouble(),
      profit: (json['profit'] ?? 0).toDouble(),
      transactions: json['transactions'] ?? 0,
      paidCash: (json['paid_cash'] ?? 0).toDouble(),
      paidTransfer: (json['paid_transfer'] ?? 0).toDouble(),
    );
  }
}
