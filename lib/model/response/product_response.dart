import 'package:eazy_store/model/request/category_model.dart';

class ProductResponse {
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

  // ✅ ใช้ Type เป็น CategoryModel (จากไฟล์ที่ Import มา)
  final CategoryModel? category;

  // ✅ ตัวแปรนี้สำคัญ เอาไว้โชว์ใน Text Field
  final String? categoryName;

  ProductResponse({
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
    this.category, 
    this.categoryName, 
  });

  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    // ดึงข้อมูล Category ออกมาพักไว้ก่อน
    CategoryModel? catObj;
    if (json['category'] != null) {
      catObj = CategoryModel.fromJson(json['category']);
    }

    return ProductResponse(
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

      // ยัด Object Category เข้าไป (เผื่อใช้ทีหลัง)
      category: catObj,

      // หัวใจสำคัญ! ดึงชื่อจาก Object มาใส่ตัวแปร categoryName
      categoryName: catObj?.name,
    );
  }
}

// --- คลาสสำหรับรับข้อมูลแบบแบ่งหน้า (Pagination) ---
class ProductPagedResponse {
  final List<ProductResponse> items;
  final int totalItems;
  final int totalPages;
  final int currentPage;

  ProductPagedResponse({
    required this.items,
    required this.totalItems,
    required this.totalPages,
    required this.currentPage,
  });

  factory ProductPagedResponse.fromJson(Map<String, dynamic> json) {
    return ProductPagedResponse(
      // นำรายการใน 'items' มาวนลูปสร้างเป็น List ของ ProductResponse
      items: (json['items'] as List?)
              ?.map((i) => ProductResponse.fromJson(i))
              .toList() ?? [],
      totalItems: json['total_items'] ?? 0,
      totalPages: json['total_pages'] ?? 0,
      currentPage: json['current_page'] ?? 1,
    );
  }
}