class Product {
  final int? productId;
  final int shopId;
  final int categoryId;
  final String? productCode;
  final String name;
  final String? barcode;
  final String imgProduct;
  final double sellPrice;
  final double costPrice;
  // ลบ final ออกจาก stock เพื่อให้เราอัปเดตค่าใน UI ได้ทันทีโดยไม่ต้องสร้าง object ใหม่ (Optional)
  // แต่ถ้าอยาก keep concept Immutable ก็ใช้ final เหมือนเดิมได้ครับ
  int stock; 
  final String unit;
  final bool status;

  // ✅ เพิ่ม field นี้สำหรับรับชื่อหมวดหมู่มาแสดงผล
  final String? categoryName; 

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
    this.categoryName, // ✅ เพิ่มใน Constructor
  });

  // แปลงจาก Object เป็น JSON เพื่อส่งไป Backend (ไม่ส่ง categoryName ไป เพราะ Backend ไม่ได้รับ)
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

  // แปลงจาก JSON กลับเป็น Object
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['product_id'],
      shopId: json['shop_id'] ?? 0, // ใส่ default value กัน crash
      categoryId: json['category_id'] ?? 0,
      productCode: json['product_code'],
      name: json['name'] ?? '',
      barcode: json['barcode'],
      imgProduct: json['img_product'] ?? '',
      
      // แปลงตัวเลขให้ปลอดภัย
      sellPrice: (json['sell_price'] as num?)?.toDouble() ?? 0.0,
      costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0.0,
      
      stock: json['stock'] ?? 0,
      unit: json['unit'] ?? '',
      status: json['status'] ?? true,

      // ✅ ดึงชื่อหมวดหมู่จาก Nested Object ที่ Go ส่งมา
      // ถ้ามี object 'category' ให้เอา field 'name' มาใส่
      categoryName: json['category'] != null ? json['category']['name'] : null,
    );
  }
}