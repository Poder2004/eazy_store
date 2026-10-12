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
import '../../../widgets/confirm_dialog.dart';
import '../../../utils/auth_guard.dart';

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
    } catch (e) {
      Get.snackbar(
        "เกิดข้อผิดพลาด",
        "โหลดรายชื่อร้านค้าไม่สำเร็จ กรุณาลองใหม่อีกครั้ง",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
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
    ConfirmDialog.show(
      title: "ยืนยันการลบ",
      message:
          "คุณต้องการลบร้าน '${shop.name}' ใช่หรือไม่? ข้อมูลนี้ไม่สามารถกู้คืนได้",
      icon: Icons.delete_forever,
      confirmLabel: "ลบเลย",
      onConfirm: () => _processDelete(shop.shopId),
    );
  }

  Future<void> _processDelete(int shopId) async {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    bool success = await _apiShop.deleteShop(shopId);
    Get.back(); // ปิด loading dialog

    if (success) {
      shops.removeWhere((item) => item.shopId == shopId);
      _showCustomDialog(
        title: "สำเร็จ",
        message: "ลบร้านค้าเรียบร้อยแล้ว",
        color: Colors.green,
        icon: Icons.check_circle,
      );
    } else {
      _showCustomDialog(
        title: "ผิดพลาด",
        message: "ไม่สามารถลบร้านค้าได้",
        color: Colors.orange,
        icon: Icons.warning,
      );
    }
  }

  void selectShop(ShopResponse shop) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    //  บันทึกข้อมูลร้านค้าลงเครื่อง
    await prefs.setInt('shopId', shop.shopId);
    await prefs.setString('shopName', shop.name);
    await prefs.setString('pinCode', shop.pinCode ?? '');

    await prefs.setString('shop_image', shop.imgShop);
    await prefs.setString('shopAddress', shop.address);

    Get.snackbar(
      "ยินดีต้อนรับ",
      "กำลังเข้าสู่ร้าน ${shop.name}",
      backgroundColor: const Color(0xFF00C853),
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 1),
    );

    Get.offAll(() => const HomePage());
    print("เลือกใช้งานร้าน: ${shop.name} (ID: ${shop.shopId})");
  }

  // ✨ ออกจากระบบ — เหมือนหน้าโปรไฟล์ (แจ้ง backend revoke refresh token พร้อมบันทึก revoked_reason)
  void logout() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFE11D48),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "ออกจากระบบ",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "คุณต้องการออกจากระบบใช่หรือไม่?",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade400),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "ยกเลิก",
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Get.back(); // ปิด bottom sheet ก่อนเรียก logout
                      await AuthGuard.logout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE11D48),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "ออกจากระบบ",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showCustomDialog({
    required String title,
    required String message,
    required Color color,
    required IconData icon,
  }) {
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Get.back(),
                  child: const Text(
                    "ตกลง",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
