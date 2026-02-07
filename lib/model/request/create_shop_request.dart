// lib/model/request/create_shop_request.dart
import 'dart:convert';

class CreateShopRequest {
  String address;
  String imgQrcode;
  String imgShop;
  String name;
  String phone;
  String pinCode;
  int shopId;
  int userId;

  CreateShopRequest({
    required this.address,
    required this.imgQrcode,
    required this.imgShop,
    required this.name,
    required this.phone,
    required this.pinCode,
    this.shopId = 0, // ค่า Default ตาม Swagger
    required this.userId,
  });

  // แปลงข้อมูลเป็น JSON เพื่อส่งไปหา Server
  Map<String, dynamic> toJson() {
    return {
      "address": address,
      "img_qrcode": imgQrcode,
      "img_shop": imgShop,
      "name": name,
      "phone": phone,
      "pin_code": pinCode,
      "shop_id": shopId,
      "user_id": userId,
    };
  }

  String toRawJson() => json.encode(toJson());
}