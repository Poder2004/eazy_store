import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ดักการยิงบาร์โค้ดจากเครื่องยิง USB/Bluetooth (ทำงานเหมือนคีย์บอร์ด: พิมพ์ตัวเลขรัวๆ แล้วปิดท้ายด้วย Enter)
/// เรียก [onBarcode] เฉพาะตอนที่หน้านี้เป็นหน้าบนสุด และไม่ได้พิมพ์อยู่ในช่องกรอกข้อความ
class HardwareBarcodeListener extends StatefulWidget {
  const HardwareBarcodeListener({
    super.key,
    required this.onBarcode,
    required this.child,
    this.allowInTextField,
  });

  final void Function(String barcode) onBarcode;

  /// ช่องกรอกข้อความที่ยอมให้ยิงบาร์โค้ดได้ (เช่น ช่องค้นหา) — ถ้าไม่ระบุ จะไม่ดักตอนโฟกัสช่องกรอกใดๆ
  final bool Function(EditableText field)? allowInTextField;
  final Widget child;

  @override
  State<HardwareBarcodeListener> createState() =>
      _HardwareBarcodeListenerState();
}

class _HardwareBarcodeListenerState extends State<HardwareBarcodeListener> {
  static const int _minLength = 4;
  // เครื่องยิงส่งตัวอักษรเร็วมาก ถ้าเว้นนานกว่านี้ถือว่าเป็นการพิมพ์ปกติ
  static const Duration _maxGap = Duration(milliseconds: 150);

  final StringBuffer _buffer = StringBuffer();
  DateTime _lastKeyAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return false;

    final focusContext = FocusManager.instance.primaryFocus?.context;
    final field = focusContext?.findAncestorWidgetOfExactType<EditableText>();
    if (field != null && widget.allowInTextField?.call(field) != true) {
      return false;
    }

    final now = DateTime.now();
    if (now.difference(_lastKeyAt) > _maxGap) _buffer.clear();
    _lastKeyAt = now;

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      final code = _buffer.toString();
      _buffer.clear();
      if (code.length >= _minLength) {
        widget.onBarcode(code);
        return true;
      }
      return false;
    }

    final ch = _charFor(event);
    if (ch != null) _buffer.write(ch);
    return false;
  }

  // เครื่องยิงคือคีย์บอร์ด ถ้าตั้งเลย์เอาต์เป็นไทย event.character จะเป็นตัวอักษร/เลขไทย
  // (เช่น ๑ ๒ ๓) ทำให้อ่านบาร์โค้ดไม่ติด จึงดูจากปุ่มจริง (physicalKey) ก่อน ซึ่งไม่ขึ้นกับภาษา
  static final Map<PhysicalKeyboardKey, String> _digitKeys = {
    PhysicalKeyboardKey.digit0: '0',
    PhysicalKeyboardKey.digit1: '1',
    PhysicalKeyboardKey.digit2: '2',
    PhysicalKeyboardKey.digit3: '3',
    PhysicalKeyboardKey.digit4: '4',
    PhysicalKeyboardKey.digit5: '5',
    PhysicalKeyboardKey.digit6: '6',
    PhysicalKeyboardKey.digit7: '7',
    PhysicalKeyboardKey.digit8: '8',
    PhysicalKeyboardKey.digit9: '9',
    PhysicalKeyboardKey.numpad0: '0',
    PhysicalKeyboardKey.numpad1: '1',
    PhysicalKeyboardKey.numpad2: '2',
    PhysicalKeyboardKey.numpad3: '3',
    PhysicalKeyboardKey.numpad4: '4',
    PhysicalKeyboardKey.numpad5: '5',
    PhysicalKeyboardKey.numpad6: '6',
    PhysicalKeyboardKey.numpad7: '7',
    PhysicalKeyboardKey.numpad8: '8',
    PhysicalKeyboardKey.numpad9: '9',
  };

  static const String _thaiDigits = '๐๑๒๓๔๕๖๗๘๙';

  String? _charFor(KeyEvent event) {
    final digit = _digitKeys[event.physicalKey];
    if (digit != null) return digit;

    final ch = event.character;
    if (ch == null || ch.length != 1) return null;
    final thai = _thaiDigits.indexOf(ch);
    if (thai != -1) return '$thai';
    // รับเฉพาะตัวอักษร/ตัวเลขภาษาอังกฤษ (บาร์โค้ดแบบ Code128 ที่มีตัวอักษร) ทิ้งตัวอักษรไทยที่หลุดมา
    return RegExp(r'^[A-Za-z0-9]$').hasMatch(ch) ? ch : null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
