// lib/services/image_upload_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ImageUploadService {
  // 1. ใส่ Cloud Name ของคุณ (ดูได้จาก Dashboard หน้าแรก)
  final String _cloudName = 'ddcuq2vh9'; 
  
  // 2. ใส่ชื่อ Preset ที่เพิ่งสร้างตะกี้ (ที่ตั้งเป็น Unsigned)
  final String _preset = 'eazy_store'; 

  Future<String?> uploadImage(File imageFile) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
    
    var request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = _preset;
    
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        var data = json.decode(responseData.body);
        return data['secure_url']; // คืนค่าเป็น URL รูปภาพ
      } else {
        print('Upload Failed: ${responseData.body}');
        return null;
      }
    } catch (e) {
      print('Error uploading: $e');
      return null;
    }
  }
}