class ParkedOrder {
  final String id;
  final String label;
  final List<ParkedItem> items;
  final double totalPrice;
  final DateTime parkedAt;

  ParkedOrder({
    required this.id,
    required this.label,
    required this.items,
    required this.totalPrice,
    required this.parkedAt,
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

  ParkedItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.imagePath,
    required this.maxStock,
    required this.quantity,
  });
}
