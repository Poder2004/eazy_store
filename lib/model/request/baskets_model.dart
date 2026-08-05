import 'package:get/get.dart';

class ProductItem {
  final String id;
  final String name;
  final double price;
  final String category;
  final String imagePath;
  final int maxStock;
  final String unit;
  RxBool showDelete;

  ProductItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.imagePath,
    required this.maxStock,
    required this.unit,
  }) : showDelete = false.obs;
}
