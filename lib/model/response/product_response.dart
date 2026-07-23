import 'package:eazy_store/model/request/category_model.dart';

// หน่วยขายเพิ่มเติมของสินค้า (เช่น ลัง/แพ็ค) ที่แปลงเข้าหน่วยฐาน (ProductResponse.unit)
// ได้ตรงๆ ด้วย conversionQty เช่น เบียร์ 1 ลัง = 12 ขวด
class ProductUnitResponse {
  final int productUnitId;
  final int productId;
  final String unitName;
  final int conversionQty;
  final String? barcode;
  final double sellPrice;
  final double costPrice;
  final bool status;

  ProductUnitResponse({
    required this.productUnitId,
    required this.productId,
    required this.unitName,
    required this.conversionQty,
    this.barcode,
    required this.sellPrice,
    required this.costPrice,
    this.status = true,
  });

  factory ProductUnitResponse.fromJson(Map<String, dynamic> json) {
    return ProductUnitResponse(
      productUnitId: json['product_unit_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      unitName: json['unit_name'] ?? '',
      conversionQty: json['conversion_qty'] ?? 1,
      barcode: json['barcode'],
      sellPrice: (json['sell_price'] as num?)?.toDouble() ?? 0.0,
      costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unit_name': unitName,
      'conversion_qty': conversionQty,
      'barcode': barcode,
      'sell_price': sellPrice,
      'cost_price': costPrice,
    };
  }
}

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
  bool isSelected;

  // หน่วยขายเพิ่มเติม (ลัง/แพ็ค) ของสินค้านี้ — ว่างได้ถ้าสินค้าไม่มีหน่วยเพิ่ม
  final List<ProductUnitResponse> units;

  // ใช้ตอนค้นหาด้วยบาร์โค้ดของหน่วยขาย (ไม่ใช่บาร์โค้ดหลักของสินค้า) — backend ส่งมา
  // ให้รู้ว่าคำค้นหาตรงกับหน่วยไหน
  final ProductUnitResponse? matchedUnit;

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
    this.isSelected = false,
    this.units = const [],
    this.matchedUnit,
  });

  List<ProductUnitResponse> get activeUnits =>
      units.where((u) => u.status).toList();

  // หน่วยที่แปลงเป็นหน่วยฐานได้มากที่สุด (เช่น ลัง) — ใช้เป็นค่าเริ่มต้นตอนลงของ/สั่งของ
  ProductUnitResponse? get largestUnit {
    final active = activeUnits;
    if (active.isEmpty) return null;
    return active.reduce((a, b) => a.conversionQty >= b.conversionQty ? a : b);
  }

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

      units: (json['units'] as List?)
              ?.map((u) => ProductUnitResponse.fromJson(u))
              .toList() ??
          [],
      matchedUnit: json['matched_unit'] != null
          ? ProductUnitResponse.fromJson(json['matched_unit'])
          : null,
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