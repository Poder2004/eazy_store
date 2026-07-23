class ProductRequest {
  final int shopId;
  final int categoryId;
  final String name;
  final String? barcode;
  final String imgProduct;
  final double sellPrice;
  final double costPrice;
  final int stock;
  final String unit;
  final bool status;

  // หน่วยขายเพิ่มเติม (ลัง/แพ็ค) ที่จะสร้างพร้อมกับสินค้านี้เลย — แต่ละรายการเป็น
  // map ตาม ProductUnitResponse.toJson() (unit_name, conversion_qty, barcode, sell_price, cost_price)
  final List<Map<String, dynamic>> units;

  ProductRequest({
    required this.shopId,
    required this.categoryId,
    required this.name,
    this.barcode,
    required this.imgProduct,
    required this.sellPrice,
    required this.costPrice,
    required this.stock,
    required this.unit,
    this.status = true,
    this.units = const [],
  });

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
      "units": units,
      // หมายเหตุ: เราไม่ส่ง category object กลับไป เพราะ backend มักใช้แค่ category_id ในการ save
    };
  }
}