class SaleRequest {
  final int shopId;
  final int? debtorId;
  final double netPrice;
  final double pay;
  final String paymentMethod;
  final String? note;
  final String createdBuy;
  final List<SaleItemRequest> saleItems;

  SaleRequest({
    required this.shopId,
    this.debtorId,
    required this.netPrice,
    required this.pay,
    required this.paymentMethod,
    this.note,
    required this.createdBuy,
    required this.saleItems,
  });

  Map<String, dynamic> toJson() => {
    "shop_id": shopId,
    "debtor_id": debtorId,
    "net_price": netPrice,
    "pay": pay,
    "payment_method": paymentMethod,
    "note": note,
    "created_buy": createdBuy,
    "sale_items": saleItems.map((item) => item.toJson()).toList(),
  };
}

class SaleItemRequest {
  final int productId;
  final int amount;
  final double pricePerUnit;
  final double totalPrice;

  SaleItemRequest({
    required this.productId,
    required this.amount,
    required this.pricePerUnit,
    required this.totalPrice,
  });

  Map<String, dynamic> toJson() => {
    "product_id": productId,
    "amount": amount,
    "price_per_unit": pricePerUnit,
    "total_price": totalPrice,
  };
}
