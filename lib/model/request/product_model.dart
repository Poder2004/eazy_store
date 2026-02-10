// ✅ 1. Import ไฟล์ CategoryModel ที่คุณมีอยู่แล้วเข้ามา
import 'package:eazy_store/model/request/category_model.dart';

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
  int stock;
  final String unit;
  final bool status;

  // ✅ 2. ใช้ Type เป็น CategoryModel (จากไฟล์ที่ Import มา)
  final CategoryModel? category; 
  
  // ✅ 3. ตัวแปรนี้สำคัญ เอาไว้โชว์ใน Text Field
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
    this.category,     // รับ Object
    this.categoryName, // รับ String ชื่อ
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // ✅ 4. ดึงข้อมูล Category ออกมาพักไว้ก่อน
    CategoryModel? catObj;
    if (json['category'] != null) {
      catObj = CategoryModel.fromJson(json['category']);
    }

    return Product(
      productId: json['product_id'],
      shopId: json['shop_id'] ?? 0,
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

      // ✅ 5. ยัด Object Category เข้าไป (เผื่อใช้ทีหลัง)
      category: catObj, 

      // ✅ 6. หัวใจสำคัญ! ดึงชื่อจาก Object มาใส่ตัวแปร categoryName
      // ถ้ามี object category ให้เอา .name มาใส่, ถ้าไม่มีให้เป็น null
      categoryName: catObj?.name, 
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
      // หมายเหตุ: เราไม่ส่ง category object กลับไป เพราะ backend มักใช้แค่ category_id ในการ save
    };
  }
}