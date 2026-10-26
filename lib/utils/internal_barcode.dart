import 'dart:math';

/// บาร์โค้ดที่ร้านสร้างเอง สำหรับสินค้าที่ไม่มีบาร์โค้ดจริง (เช่น ไข่ น้ำแข็ง)
///
/// ใช้ EAN-13 ขึ้นต้นด้วย "20" ซึ่งเป็นช่วงที่สากลกันไว้ให้ใช้ภายในร้าน (prefix 20-29)
/// สินค้าที่ขายตามท้องตลาดจะไม่ใช้ช่วงนี้ จึงไม่ชนกับบาร์โค้ดจริง และเป็นตัวเลขล้วน
/// ใช้กับช่องบาร์โค้ดเดิม (digitsOnly) และเครื่องยิงทุกรุ่นอ่านได้
const String kInternalBarcodePrefix = '20';

final Random _rng = Random.secure();

/// เลขตรวจสอบ (check digit) ของ EAN-13 จากเลข 12 หลักแรก
int _ean13CheckDigit(String first12) {
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    final d = int.parse(first12[i]);
    sum += i.isEven ? d : d * 3;
  }
  return (10 - sum % 10) % 10;
}

String generateInternalBarcode() {
  final body = StringBuffer(kInternalBarcodePrefix);
  for (var i = 0; i < 10; i++) {
    body.write(_rng.nextInt(10));
  }
  final first12 = body.toString();
  return '$first12${_ean13CheckDigit(first12)}';
}

bool isInternalBarcode(String? barcode) {
  if (barcode == null || barcode.length != 13) return false;
  if (!barcode.startsWith(kInternalBarcodePrefix)) return false;
  if (int.tryParse(barcode) == null) return false;
  return _ean13CheckDigit(barcode.substring(0, 12)) == int.parse(barcode[12]);
}
