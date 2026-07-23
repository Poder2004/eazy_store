import 'package:get/get.dart';

class ProductItem {
  final String id;
  final String name;
  final double price;
  final String category;
  final String imagePath;
  final int maxStock;
  RxBool showDelete;

  // หน่วยที่ขายรายการนี้ — unitId เป็น null แปลว่าเป็นหน่วยฐาน (พฤติกรรมเดิม)
  // conversionQty = จำนวนหน่วยฐานต่อ 1 หน่วยนี้ (เช่น ลัง = 12 ขวด)
  final int? unitId;
  final String unitName;
  final int conversionQty;

  // บาร์โค้ดของสินค้านี้ (ถ้ามี) — ใช้แค่แสดงผลในหน้าที่ต้องอ้างอิงบาร์โค้ด
  // เช่น สมุดสินค้าไม่มีบาร์โค้ด/มีบาร์โค้ด ไม่เกี่ยวกับการคำนวณในตะกร้า
  final String? barcode;

  ProductItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.imagePath,
    required this.maxStock,
    this.unitId,
    this.unitName = 'ชิ้น',
    this.conversionQty = 1,
    this.barcode,
  }) : showDelete = false.obs;

  // key ไว้จัดกลุ่ม/นับจำนวนในตะกร้า — สินค้าเดียวกันแต่คนละหน่วยต้องแยกกัน
  // (เช่น ขายทั้งขวดและลังพร้อมกันในบิลเดียว ไม่ให้ปนกันเป็นแถวเดียว)
  String get lineKey => '$id:${unitId ?? 0}';
}
