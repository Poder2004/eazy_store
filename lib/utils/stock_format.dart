import 'package:eazy_store/model/response/product_response.dart';

/// แปลงจำนวนสต็อก (หน่วยฐาน) ให้แสดงเป็นหน่วยใหญ่ + เศษ เช่น "10 ลัง + 10 ขวด"
/// โดยใช้หน่วยขายเพิ่มเติมที่แปลงได้มากที่สุด (largestUnit) ถ้าสินค้านั้นมี
/// ถ้าไม่มีหน่วยขายเพิ่มเติม หรือสต็อกน้อยกว่า 1 หน่วยใหญ่ ก็แสดงเป็นหน่วยฐานตามปกติ
String formatStockBreakdown(
  int stock,
  String baseUnit,
  List<ProductUnitResponse> units,
) {
  final activeUnits = units.where((u) => u.status).toList();
  if (activeUnits.isEmpty) {
    return '$stock $baseUnit';
  }

  final largest = activeUnits.reduce(
    (a, b) => a.conversionQty >= b.conversionQty ? a : b,
  );

  final big = stock ~/ largest.conversionQty;
  final rem = stock % largest.conversionQty;

  if (big <= 0) {
    return '$stock $baseUnit';
  }
  if (rem == 0) {
    return '$big ${largest.unitName}';
  }
  return '$big ${largest.unitName} + $rem $baseUnit';
}
