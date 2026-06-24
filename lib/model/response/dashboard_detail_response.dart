class TransactionDetailModel {
  final int saleId;
  final double netPrice;
  final double pay;
  final String paymentMethod;
  final String createdAt;
  final String? createdTime;

  TransactionDetailModel({
    required this.saleId,
    required this.netPrice,
    required this.pay,
    required this.paymentMethod,
    required this.createdAt,
    this.createdTime,
  });

  factory TransactionDetailModel.fromJson(Map<String, dynamic> json) {
    return TransactionDetailModel(
      saleId: json['sale_id'] ?? 0,
      netPrice: (json['net_price'] ?? 0).toDouble(),
      pay: (json['pay'] ?? 0).toDouble(),
      paymentMethod: json['payment_method'] ?? '',
      createdAt: json['created_at'] ?? '',
      createdTime: json['created_time'],
    );
  }
}

class SaleItemModel {
  final int productId;
  final String productName;
  final String imgProduct;
  final int qty;
  final double unitPrice;
  final double costPrice;
  final double subtotal;

  SaleItemModel({
    required this.productId,
    required this.productName,
    required this.imgProduct,
    required this.qty,
    required this.unitPrice,
    required this.costPrice,
    required this.subtotal,
  });

  factory SaleItemModel.fromJson(Map<String, dynamic> json) {
    return SaleItemModel(
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? 'ไม่มีชื่อ',
      imgProduct: json['img_product'] ?? '',
      qty: (json['qty'] ?? 0).toInt(),
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      costPrice: (json['cost_price'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }
}

class SaleDetailModel {
  final int saleId;
  final String createdAt;
  final String? createdTime;
  final String paymentMethod;
  final double netPrice;
  final double pay;
  final double change;
  final List<SaleItemModel> items;

  SaleDetailModel({
    required this.saleId,
    required this.createdAt,
    this.createdTime,
    required this.paymentMethod,
    required this.netPrice,
    required this.pay,
    required this.change,
    required this.items,
  });

  factory SaleDetailModel.fromJson(Map<String, dynamic> json) {
    return SaleDetailModel(
      saleId: json['sale_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      createdTime: json['created_time'],
      paymentMethod: json['payment_method'] ?? '',
      netPrice: (json['net_price'] ?? 0).toDouble(),
      pay: (json['pay'] ?? 0).toDouble(),
      change: (json['change'] ?? 0).toDouble(),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => SaleItemModel.fromJson(e))
          .toList(),
    );
  }
}

class ProductSalesDetailModel {
  final int productId;
  final String productName;
  final String imgProduct;
  final int totalQty;
  final double totalSales;
  final double totalCost;
  final double profit;

  ProductSalesDetailModel({
    required this.productId,
    required this.productName,
    required this.imgProduct,
    required this.totalQty,
    required this.totalSales,
    required this.totalCost,
    required this.profit,
  });

  factory ProductSalesDetailModel.fromJson(Map<String, dynamic> json) {
    return ProductSalesDetailModel(
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? 'ไม่มีชื่อ',
      imgProduct: json['img_product'] ?? '',
      totalQty: (json['total_qty'] ?? 0).toInt(),
      totalSales: (json['total_sales'] ?? 0).toDouble(),
      totalCost: (json['total_cost'] ?? 0).toDouble(),
      profit: (json['profit'] ?? 0).toDouble(),
    );
  }
}
