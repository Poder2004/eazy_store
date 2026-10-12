import 'package:flutter/material.dart';
import 'package:number_flow_flutter/number_flow_flutter.dart';

const _kWholeFormat = NumberFlowFormat.decimal(minFraction: 0, maxFraction: 0);
const _kCentsFormat = NumberFlowFormat.decimal(minFraction: 2, maxFraction: 2);

/// ตัวเลขเงิน (฿) แบบ animate rolling number ตอนค่าเปลี่ยน (ใช้แทนตัวเลขนิ่งๆ / loading spinner)
Widget moneyFlow(
  double value, {
  required double fontSize,
  required FontWeight fontWeight,
  required Color color,
  double letterSpacing = 0,
}) {
  final style = TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
  );
  // จำนวนเต็ม -> ไม่โชว์ทศนิยม (13,699), มีเศษสตางค์ -> โชว์เต็ม 2 ตำแหน่งเสมอ (13,699.50) ไม่ปัดทิ้ง
  final hasCents = (value * 100).round() % 100 != 0;
  final format = hasCents ? _kCentsFormat : _kWholeFormat;
  // ไม่ใช้ prefix ของ NumberFlow เพราะมันแทรกช่องว่างระหว่าง ฿ กับตัวเลข
  // ทำให้ระยะห่างไม่เท่ากันในแต่ละขนาดฟอนต์ ใช้ Row แปะกันแน่นแทน
  return Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      Text('฿', style: style),
      NumberFlow(value: value, format: format, locale: 'en_US', style: style),
    ],
  );
}
