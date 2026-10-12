/// ตัวช่วยแปลง Exception ให้เป็นข้อความภาษาไทยที่ผู้ใช้อ่านเข้าใจ
///
/// - ถ้า Exception มีข้อความภาษาไทยอยู่แล้ว (เช่น throw Exception("เพิ่มหมวดหมู่ไม่สำเร็จ"))
///   จะตัดคำว่า "Exception:" ออกแล้วใช้ข้อความนั้น
/// - ถ้าเป็นข้อความภาษาอังกฤษจากระบบ (เช่น SocketException, TimeoutException)
///   จะแทนที่ด้วยข้อความภาษาไทยที่กำหนดใน [fallback] เพื่อไม่ให้ผู้ใช้เห็นภาษาอังกฤษ
String friendlyError(
  Object error, {
  String fallback = "เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง",
}) {
  var message = error.toString().trim();

  // ตัด prefix ที่ Dart ใส่มาให้อัตโนมัติ
  for (final prefix in ["Exception:", "_Exception:", "Error:", "FormatException:"]) {
    if (message.startsWith(prefix)) {
      message = message.substring(prefix.length).trim();
    }
  }

  if (message.isEmpty) return fallback;

  // มีตัวอักษรไทยอย่างน้อย 1 ตัว = เป็นข้อความที่เราเขียนเองแล้ว แสดงได้เลย
  final hasThai = RegExp(r'[฀-๿]').hasMatch(message);
  if (!hasThai) return fallback;

  // ตัดส่วนภาษาอังกฤษท้ายข้อความ (เช่น "ไม่สำเร็จ: SocketException ...") ทิ้ง
  final cutIndex = message.indexOf(RegExp(r':\s*[A-Za-z_]{3,}'));
  if (cutIndex > 0) {
    message = message.substring(0, cutIndex).trim();
  }

  return message.isEmpty ? fallback : message;
}

/// ข้อความมาตรฐานเมื่อเชื่อมต่อเซิร์ฟเวอร์ไม่ได้
const String kNetworkErrorMessage =
    "เชื่อมต่อเซิร์ฟเวอร์ไม่สำเร็จ กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่อีกครั้ง";
