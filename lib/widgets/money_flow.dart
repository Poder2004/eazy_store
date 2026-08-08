import 'package:flutter/material.dart';
import 'package:number_flow_flutter/number_flow_flutter.dart';

const _kMoneyFormat = NumberFlowFormat.decimal(minFraction: 0, maxFraction: 0);

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
  // ไม่ใช้ prefix ของ NumberFlow เพราะมันแทรกช่องว่างระหว่าง ฿ กับตัวเลข
  // ทำให้ระยะห่างไม่เท่ากันในแต่ละขนาดฟอนต์ ใช้ Row แปะกันแน่นแทน
  return Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    children: [
      Text('฿', style: style),
      NumberFlow(value: value, format: _kMoneyFormat, locale: 'en_US', style: style),
    ],
  );
}
