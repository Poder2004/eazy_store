class Product {
  final int? productId;
  final int shopId;
  final int categoryId;
  final String? productCode;
  final String name;
  final String? barcode; // รองรับค่าว่าง (NULL)
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

  // แปลงจาก Object เป็น JSON เพื่อส่งไป Backend
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

  // แปลงจาก JSON กลับเป็น Object (ใช้ตอนรับข้อมูลสินค้าที่เพิ่งสร้างสำเร็จ)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['product_id'],
      shopId: json['shop_id'],
      categoryId: json['category_id'],
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
}
