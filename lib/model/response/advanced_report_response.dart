class AdvancedReportResponse {
  final List<SalesChartItem> salesChart;
  final SummaryStats summaryStats;
  final PaymentMethods paymentMethods;
  final List<TopProductItem> topProducts;
  final DebtSummary debtSummary;
  final AgingReport agingReport;
  final List<TopDebtorItem> topDebtors;
  final DebtCollection debtCollection;

  AdvancedReportResponse({
    required this.salesChart,
    required this.summaryStats,
    required this.paymentMethods,
    required this.topProducts,
    required this.debtSummary,
    required this.agingReport,
    required this.topDebtors,
    required this.debtCollection,
  });

  factory AdvancedReportResponse.fromJson(Map<String, dynamic> json) {
    return AdvancedReportResponse(
      salesChart: (json['sales_chart'] as List?)?.map((i) => SalesChartItem.fromJson(i)).toList() ?? [],
      summaryStats: SummaryStats.fromJson(json['summary_stats'] ?? {}),
      paymentMethods: PaymentMethods.fromJson(json['payment_methods'] ?? {}),
      topProducts: (json['top_products'] as List?)?.map((i) => TopProductItem.fromJson(i)).toList() ?? [],
      debtSummary: DebtSummary.fromJson(json['debt_summary'] ?? {}),
      agingReport: AgingReport.fromJson(json['aging_report'] ?? {}),
      topDebtors: (json['top_debtors'] as List?)?.map((i) => TopDebtorItem.fromJson(i)).toList() ?? [],
      debtCollection: DebtCollection.fromJson(json['debt_collection'] ?? {}),
    );
  }
}

class SalesChartItem {
  final String date;
  final double totalSales;

  SalesChartItem({required this.date, required this.totalSales});

  factory SalesChartItem.fromJson(Map<String, dynamic> json) {
    return SalesChartItem(
      date: json['date'] ?? '',
      totalSales: (json['total_sales'] ?? 0).toDouble(),
    );
  }
}

class SummaryStats {
  final int totalTransactions;
  final double totalSales;
  final double averageSales;

  SummaryStats({required this.totalTransactions, required this.totalSales, required this.averageSales});

  factory SummaryStats.fromJson(Map<String, dynamic> json) {
    return SummaryStats(
      totalTransactions: json['total_transactions'] ?? 0,
      totalSales: (json['total_sales'] ?? 0).toDouble(),
      averageSales: (json['average_sales'] ?? 0).toDouble(),
    );
  }
}

class PaymentMethods {
  final double paidCash;
  final double paidTransfer;
  final double debtAmount;

  PaymentMethods({required this.paidCash, required this.paidTransfer, required this.debtAmount});

  factory PaymentMethods.fromJson(Map<String, dynamic> json) {
    return PaymentMethods(
      paidCash: (json['paid_cash'] ?? 0).toDouble(),
      paidTransfer: (json['paid_transfer'] ?? 0).toDouble(),
      debtAmount: (json['debt_amount'] ?? 0).toDouble(),
    );
  }
}

class TopProductItem {
  final String productName;
  final int totalQty;
  final double totalSales;

  TopProductItem({required this.productName, required this.totalQty, required this.totalSales});

  factory TopProductItem.fromJson(Map<String, dynamic> json) {
    return TopProductItem(
      productName: json['product_name'] ?? '',
      totalQty: json['total_qty'] ?? 0,
      totalSales: (json['total_sales'] ?? 0).toDouble(),
    );
  }
}

class DebtSummary {
  final double totalOutstanding;
  final double collectedThisMonth;

  DebtSummary({required this.totalOutstanding, required this.collectedThisMonth});

  factory DebtSummary.fromJson(Map<String, dynamic> json) {
    return DebtSummary(
      totalOutstanding: (json['total_outstanding'] ?? 0).toDouble(),
      collectedThisMonth: (json['collected_this_month'] ?? 0).toDouble(),
    );
  }
}

class AgingReport {
  final double safe;
  final double warning;
  final double danger;

  AgingReport({required this.safe, required this.warning, required this.danger});

  factory AgingReport.fromJson(Map<String, dynamic> json) {
    return AgingReport(
      safe: (json['safe'] ?? 0).toDouble(),
      warning: (json['warning'] ?? 0).toDouble(),
      danger: (json['danger'] ?? 0).toDouble(),
    );
  }
}

class TopDebtorItem {
  final int debtorId;
  final String name;
  final double currentDebt;

  TopDebtorItem({required this.debtorId, required this.name, required this.currentDebt});

  factory TopDebtorItem.fromJson(Map<String, dynamic> json) {
    return TopDebtorItem(
      debtorId: json['debtor_id'] ?? 0,
      name: json['name'] ?? '',
      currentDebt: (json['current_debt'] ?? 0).toDouble(),
    );
  }
}

class AgingBucketDebtorItem {
  final int saleId;
  final int debtorId;
  final String name;
  final String phone;
  final String imgDebtor;
  final String saleDate;
  final double amountOwed;
  final int daysOverdue;

  AgingBucketDebtorItem({
    required this.saleId,
    required this.debtorId,
    required this.name,
    required this.phone,
    required this.imgDebtor,
    required this.saleDate,
    required this.amountOwed,
    required this.daysOverdue,
  });

  factory AgingBucketDebtorItem.fromJson(Map<String, dynamic> json) {
    return AgingBucketDebtorItem(
      saleId: json['sale_id'] ?? 0,
      debtorId: json['debtor_id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      imgDebtor: json['img_debtor'] ?? '',
      saleDate: json['sale_date'] ?? '',
      amountOwed: (json['amount_owed'] ?? 0).toDouble(),
      daysOverdue: json['days_overdue'] ?? 0,
    );
  }
}

class AgingReportDetail {
  final List<AgingBucketDebtorItem> safe;
  final List<AgingBucketDebtorItem> warning;
  final List<AgingBucketDebtorItem> danger;

  AgingReportDetail({
    required this.safe,
    required this.warning,
    required this.danger,
  });

  factory AgingReportDetail.fromJson(Map<String, dynamic> json) {
    List<AgingBucketDebtorItem> parse(String key) =>
        (json[key] as List?)?.map((i) => AgingBucketDebtorItem.fromJson(i)).toList() ?? [];
    return AgingReportDetail(
      safe: parse('safe'),
      warning: parse('warning'),
      danger: parse('danger'),
    );
  }
}

class DebtCollection {
  final double newDebt;
  final double collectedDebt;

  DebtCollection({required this.newDebt, required this.collectedDebt});

  factory DebtCollection.fromJson(Map<String, dynamic> json) {
    return DebtCollection(
      newDebt: (json['new_debt'] ?? 0).toDouble(),
      collectedDebt: (json['collected_debt'] ?? 0).toDouble(),
    );
  }
}
