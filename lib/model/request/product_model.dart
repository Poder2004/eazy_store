// 1. เพิ่ม Class สำหรับเก็บข้อมูลหมวดหมู่
class Category {
  final int categoryId;
  final String name;

  Category({required this.categoryId, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      categoryId: json['category_id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class Product {
  final int? productId;
  final int shopId;
  final int categoryId;
  final Category? category; // ✨ เพิ่มฟิลด์นี้เพื่อรับ Object หมวดหมู่
  final String? productCode;
  final String name;
  final String? barcode;
  final String imgProduct;
  final double sellPrice;
  final double costPrice;
  final int stock;
  final String unit;
  final bool status;

  Product({
    this.productId,
    required this.shopId,
    required this.categoryId,
    this.category, // ✨ เพิ่มใน constructor
    this.productCode,
    required this.name,
    this.barcode,
    required this.imgProduct,
    required this.sellPrice,
    required this.costPrice,
    required this.stock,
    required this.unit,
    this.status = true,
  });

  // แปลงจาก JSON กลับเป็น Object
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['product_id'],
      shopId: json['shop_id'],
      categoryId: json['category_id'],
      // ✨ จัดการแปลงข้อมูล Category ที่ส่งมาซ้อนใน JSON
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : null,
      productCode: json['product_code'],
      name: json['name'],
      barcode: json['barcode'],
      imgProduct: json['img_product'],
      sellPrice: (json['sell_price'] as num).toDouble(),
      costPrice: (json['cost_price'] as num).toDouble(),
      stock: json['stock'],
      unit: json['unit'],
      status: json['status'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "shop_id": shopId,
      "category_id": categoryId,
      "name": name,
      "barcode": barcode,
      "img_product": imgProduct,
      "sell_price": sellPrice,
      "cost_price": costPrice,
      "stock": stock,
      "unit": unit,
      "status": status,
    };
  }
}
