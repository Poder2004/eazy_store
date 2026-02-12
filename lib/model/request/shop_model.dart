class ShopModel {
  final int shopId;
  final int userId;
  final String name;
  final String phone;
  final String address;
  final String imgQrcode; // สำคัญ! เราจะเอาตัวนี้
  final String imgShop;
  final String pincode;

  ShopModel({
    required this.shopId,
    required this.userId,
    required this.name,
    required this.phone,
    required this.address,
    required this.imgQrcode,
    required this.imgShop,
    required this.pincode,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      shopId: json['shop_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      imgQrcode: json['img_qrcode'] ?? '',
      imgShop: json['img_shop'] ?? '',
      pincode: json['pin_code'] ?? '', // เช็คดีๆ Backend ส่งมา key "pin_code"
    );
  }
}
