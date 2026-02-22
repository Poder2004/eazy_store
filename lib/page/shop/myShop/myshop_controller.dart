import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import API และ Model
import '../../../api/api_shop.dart';
import '../../../model/response/shop_response.dart';

// Import หน้าจอสำหรับการนำทาง
import '../createShop/create_shop.dart';
import '../editShop/edit_shop.dart'; 
import '../../homepage/home_page.dart';

class MyShopController extends GetxController {
  final ApiShop _apiShop = ApiShop();

  var isLoading = true.obs;
  var shops = <ShopResponse>[].obs;
  var userName = "ชื่อ นามสกุล".obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
    fetchShops();
  }

  void loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userName.value = prefs.getString('username') ?? "ผู้ใช้งาน";
  }

  void fetchShops() async {
    isLoading.value = true;
    try {
      var result = await _apiShop.getShops();
      shops.assignAll(result);
    } finally {
      isLoading.value = false;
    }
  }

  void goToAddShop() async {
    var result = await Get.to(() => CreateShopPage());
    if (result == true) fetchShops();
  }

  void goToEditShop(ShopResponse shop) async {
    var result = await Get.to(() => EditShopScreen(shop: shop));
    if (result == true) {
      fetchShops();
    }
  }

  Future<void> deleteShop(int shopId) async {
    bool success = await _apiShop.deleteShop(shopId);
    if (success) {
      shops.removeWhere((item) => item.shopId == shopId);
      Get.snackbar(
        "สำเร็จ",
        "ลบร้านค้าเรียบร้อยแล้ว",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        "ผิดพลาด",
        "ไม่สามารถลบร้านค้าได้",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ✨ ฟังก์ชันสำคัญ: บันทึกร้านค้าที่เลือกและนำทางไปหน้าหลัก
  void selectShop(ShopResponse shop) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // 1. บันทึก shopId ลงเครื่อง เพื่อเอาไปใช้ในหน้าเพิ่มสินค้า
    await prefs.setInt('shopId', shop.shopId);
    await prefs.setString('shopName', shop.name);
    await prefs.setString('pinCode', shop.pinCode ?? '');

    // 2. แสดงแจ้งเตือนเล็กน้อย
    Get.snackbar(
      "ยินดีต้อนรับ",
      "กำลังเข้าสู่ร้าน ${shop.name}",
      backgroundColor: const Color(0xFF00C853),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 1),
    );

    // 3. นำทางไปหน้าถัดไป (เช่น หน้าที่มี Bottom Navigation Bar)
    Get.offAll(() => const HomePage());
    print("เลือกใช้งานร้าน: ${shop.name} (ID: ${shop.shopId})");
  }
}