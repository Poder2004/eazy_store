import 'dart:convert';

// 1. เพิ่มฟังก์ชันด้านบน (Global scope) เพื่อความสะดวกในการใช้ List
List<ShopResponse> shopResponseFromJson(String str) =>
    List<ShopResponse>.from(json.decode(str).map((x) => ShopResponse.fromJson(x)));

class ShopResponse {
  int shopId;
  int userId;
  String name;
  String phone;
  String address;
  String imgQrcode;
  String imgShop;
  String pinCode;

  ShopResponse({
    required this.shopId,
    required this.userId,
    required this.name,
    required this.phone,
    required this.address,
    required this.imgQrcode,
    required this.imgShop,
    required this.pinCode,
  });

  factory ShopResponse.fromJson(Map<String, dynamic> json) => ShopResponse(
        shopId: json["shop_id"] ?? 0,
        userId: json["user_id"] ?? 0,
        name: json["name"] ?? "",
        phone: json["phone"] ?? "",
        address: json["address"] ?? "",
        imgQrcode: json["img_qrcode"] ?? "",
        imgShop: json["img_shop"] ?? "",
        pinCode: json["pin_code"] ?? "",
      );

  Map<String, dynamic> toJson() => {
        "shop_id": shopId,
        "user_id": userId,
        "name": name,
        "phone": phone,
        "address": address,
        "img_qrcode": imgQrcode,
        "img_shop": imgShop,
        "pin_code": pinCode,
      };

  // ✅ 2. เพิ่ม Method นี้เข้าไปเพื่อให้ ApiShop เรียกใช้ได้
  String toRawJson() => json.encode(toJson());
}