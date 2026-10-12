import 'dart:io' show Platform;
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// สร้าง/เก็บ id เฉพาะเครื่องนี้ไว้ใน SharedPreferences ครั้งแรกที่เรียกใช้
/// ใช้แยกว่า refresh token แต่ละแถวเป็นของเครื่องไหน เพื่อให้ logout เฉพาะเครื่องได้
class DeviceIdHelper {
  static const _key = 'device_id';

  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_key);
    if (id == null || id.isEmpty) {
      id = _generate();
      await prefs.setString(_key, id);
    }
    return id;
  }

  static String _generate() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// ชื่อรุ่นเครื่องแบบอ่านง่าย (เช่น "iPhone 15", "Samsung SM-G991B")
  /// ใช้เป็นแค่ label ให้ user เห็นว่า session ไหนอยู่บนเครื่องไหน ไม่ได้ใช้แยก session จริง (ใช้ device_id แทน)
  static Future<String> getDeviceName() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        return '${info.manufacturer} ${info.model}';
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        return info.name.isNotEmpty ? info.name : info.model;
      } else if (Platform.isWindows) {
        final info = await deviceInfo.windowsInfo;
        return info.computerName;
      } else if (Platform.isMacOS) {
        final info = await deviceInfo.macOsInfo;
        return info.computerName;
      } else if (Platform.isLinux) {
        final info = await deviceInfo.linuxInfo;
        return info.prettyName;
      }
    } catch (e) {
      print('getDeviceName error: $e');
    }
    return 'อุปกรณ์ไม่ทราบชนิด';
  }
}
