class ParkedOrder {
  final String id;
  final String label;
  final List<ParkedItem> items;
  final double totalPrice;
  final DateTime parkedAt;
  final int shopId;

  ParkedOrder({
    required this.id,
    required this.label,
    required this.items,
    required this.totalPrice,
    required this.parkedAt,
    required this.shopId,
  });
}

class ParkedItem {
  final String id;
  final String name;
  final double price;
  final String category;
  final String imagePath;
  final int maxStock;
  final int quantity;
  final String unit;

  ParkedItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.imagePath,
    required this.maxStock,
    required this.quantity,
    required this.unit,
  });
}
