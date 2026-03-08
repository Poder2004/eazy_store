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

  Future<void> confirmAndDeleteShop(ShopResponse shop) async {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_forever, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              const Text("ยืนยันการลบ", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text("คุณต้องการลบร้าน '${shop.name}' ใช่หรือไม่? ข้อมูลนี้ไม่สามารถกู้คืนได้", 
                style: const TextStyle(fontSize: 16, color: Colors.black54), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      child: const Text("ยกเลิก"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () async {
                        Get.back(); // ปิด Dialog ยืนยัน
                        _processDelete(shop.shopId);
                      },
                      child: const Text("ลบเลย", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _processDelete(int shopId) async {
    isLoading.value = true;
    bool success = await _apiShop.deleteShop(shopId);
    isLoading.value = false;
    
    if (success) {
      shops.removeWhere((item) => item.shopId == shopId);
      _showCustomDialog(title: "สำเร็จ", message: "ลบร้านค้าเรียบร้อยแล้ว", color: Colors.green, icon: Icons.check_circle);
    } else {
      _showCustomDialog(title: "ผิดพลาด", message: "ไม่สามารถลบร้านค้าได้", color: Colors.orange, icon: Icons.warning);
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

    // 1. บันทึกข้อมูลร้านค้าลงเครื่อง
    await prefs.setInt('shopId', shop.shopId);
    await prefs.setString('shopName', shop.name);
    await prefs.setString('pinCode', shop.pinCode ?? '');

    await prefs.setString('shop_image', shop.imgShop);
    await prefs.setString('shopAddress', shop.address);

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

  void _showCustomDialog({required String title, required String message, required Color color, required IconData icon}) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 60),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(message, style: const TextStyle(fontSize: 16, color: Colors.black54), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () => Get.back(),
                  child: const Text("ตกลง", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
