// lib/api/api_service_image.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ImageUploadService {
  // 1. ใส่ Cloud Name ของคุณ (ดูได้จาก Dashboard หน้าแรก)
  final String _cloudName = 'ddcuq2vh9';

  // 2. ใส่ชื่อ Preset ที่เพิ่งสร้างตะกี้ (ที่ตั้งเป็น Unsigned)
  final String _preset = 'eazy_store';

  /// อัปโหลดรูปภาพ รองรับทั้ง File (มือถือ/เดสก์ท็อป) และ XFile (เว็บ)
  ///
  /// หมายเหตุ: ห้ามใช้ MultipartFile.fromPath เพราะบนเว็บจะพังด้วยข้อความ
  /// "Unsupported operation: MultipartFile is only supported where dart:io is available"
  /// จึงอ่านเป็น bytes แล้วส่งด้วย fromBytes ซึ่งใช้ได้ทุกแพลตฟอร์ม
  Future<String?> uploadImage(dynamic imageFile) async {
    try {
      final Uint8List bytes = await imageFile.readAsBytes();
      final String fileName = _resolveFileName(imageFile);
      return await uploadBytes(bytes, fileName: fileName);
    } catch (e) {
      debugPrint('อ่านไฟล์รูปภาพไม่สำเร็จ: $e');
      return null;
    }
  }

  /// อัปโหลดจาก bytes โดยตรง (ใช้ได้ทั้งเว็บและมือถือ)
  Future<String?> uploadBytes(
    Uint8List bytes, {
    String fileName = 'upload.jpg',
  }) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    try {
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = _preset;
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final data = json.decode(responseData.body);
        return data['secure_url']; // คืนค่าเป็น URL รูปภาพ
      }

      debugPrint('อัปโหลดรูปไม่สำเร็จ (${response.statusCode}): ${responseData.body}');
      return null;
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดขณะอัปโหลดรูป: $e');
      return null;
    }
  }

  /// ดึงชื่อไฟล์จาก path ถ้าไม่มีนามสกุลรูปภาพ ให้ใช้ .jpg เป็นค่าเริ่มต้น
  String _resolveFileName(dynamic imageFile) {
    try {
      final String path = imageFile.path as String;
      final String base = path.split('/').last.split('\\').last;
      final String lower = base.toLowerCase();
      const allowed = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic'];
      if (base.isNotEmpty && allowed.any(lower.endsWith)) {
        return base;
      }
    } catch (_) {
      // บนเว็บ path เป็น blob URL อาจไม่มีชื่อไฟล์จริง
    }
    return 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
  }
}
