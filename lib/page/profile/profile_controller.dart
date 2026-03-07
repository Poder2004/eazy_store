import 'package:eazy_store/api/api_dashboad.dart';
import 'package:eazy_store/api/api_shop.dart';
import 'package:eazy_store/api/api_user.dart'; // ✨ เพิ่ม Import ApiUser
import 'package:eazy_store/model/response/shop_response.dart';
import 'package:eazy_store/page/auth/login.dart';
import 'package:eazy_store/page/edit_profile/edit_profile_page.dart';

import 'package:eazy_store/page/shop/editShop/edit_shop.dart';
import 'package:eazy_store/page/shop/myShop/myshop.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileController extends GetxController {
  // ---------------- State Variables ----------------
  // ข้อมูลผู้ใช้
  var userName = "กำลังโหลด...".obs;
  var userInitials = "".obs;
  var userRole = "Admin".obs;

  // ✨ เพิ่มตัวแปรเก็บ URL รูปภาพ
  var userImage = "".obs;

  // ข้อมูลร้านค้า
  var shopId = 0.obs;
  var shopName = "กำลังโหลด...".obs;
  var shopAddress = "กำลังโหลดที่อยู่...".obs;

  // ✨ เพิ่มตัวแปรเก็บ URL รูปร้านค้า
  var shopImage = "".obs;

  // ข้อมูลยอดขาย
  var todaySales = "0".obs;
  var isSalesLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfileData();
  }

  // ---------------- ฟังก์ชันดึงข้อมูล ----------------
  Future<void> loadProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // 1. โหลดข้อมูลผู้ใช้ (อ่านจาก SharedPreferences เพื่อให้แสดงผลไวที่สุดตอนเปิดหน้า)
    String name =
        prefs.getString('name') ?? prefs.getString('username') ?? "ผู้ใช้งาน";
    userName.value = name;
    userInitials.value = _getInitials(name);
    userRole.value =
        prefs.getString('role') ?? "เจ้าของร้าน"; // ถ้ามี role เก็บไว้ก็ดึงมา

    // ✨ ดึง URL รูปโปรไฟล์ผู้ใช้ (จากตอน Login)
    userImage.value = prefs.getString('profile_image') ?? "";

    // 2. โหลดข้อมูลร้านค้า
    shopId.value = prefs.getInt('shopId') ?? 0;
    shopName.value = prefs.getString('shopName') ?? "ยังไม่ได้เลือกร้านค้า";
    shopAddress.value = prefs.getString('shopAddress') ?? "ไม่มีข้อมูลที่อยู่";

    // ✨ ดึง URL รูปร้านค้า (จากตอนเลือกร้านค้า MyShopController)
    shopImage.value = prefs.getString('shop_image') ?? "";

    // 3. ดึงยอดขายวันนี้
    if (shopId.value != 0) {
      fetchTodaySales();
    } else {
      isSalesLoading.value = false;
    }

    // ✨ เสริม: ดึงข้อมูลโปรไฟล์ล่าสุดจาก API เผื่อมีการแก้ไขจากเครื่องอื่น
    reloadProfileDataAfterEdit();
  }

  // ดึง API ยอดขายวันนี้
  Future<void> fetchTodaySales() async {
    isSalesLoading.value = true;
    try {
      DateTime now = DateTime.now();
      String todayStr = DateFormat('yyyy-MM-dd').format(now);

      final summary = await ApiDashboad.getSalesSummary(
        shopId.value,
        todayStr,
        todayStr,
      );

      if (summary != null) {
        todaySales.value = NumberFormat('#,##0').format(summary.actualPaid);
      } else {
        todaySales.value = "0";
      }
    } catch (e) {
      print("Profile - Error fetching today sales: $e");
      todaySales.value = "0";
    } finally {
      isSalesLoading.value = false;
    }
  }

  // ฟังก์ชันช่วยสร้างตัวย่อชื่อ (เช่น Sarah Mitchell -> SM)
  String _getInitials(String name) {
    if (name.isEmpty) return "U";
    List<String> nameParts = name.trim().split(" ");
    if (nameParts.length > 1) {
      return (nameParts[0][0] + nameParts[1][0]).toUpperCase();
    } else {
      return nameParts[0][0].toUpperCase();
    }
  }

  // ---------------- ฟังก์ชัน นำทาง (Navigation) ----------------

  // ✨ อัปเดตฟังก์ชัน goToEditProfile ให้รอรับค่า
  void goToEditProfile() async {
    print("ไปยังหน้า Edit Profile");

    // เอาคอมเมนต์ออกแล้วเรียกใช้ EditProfilePage ที่เราสร้างไว้
    var result = await Get.to(() => const EditProfilePage());

    // ถ้าหน้า Edit ส่งค่า true กลับมา แปลว่ามีการบันทึกสำเร็จ ให้ดึงข้อมูลใหม่
    if (result == true) {
      await reloadProfileDataAfterEdit();
    }
  }

  // ✨ ฟังก์ชันสำหรับอัปเดตหน้าจอหลังจากแก้ไขโปรไฟล์เสร็จ โดยดึงจาก API
  Future<void> reloadProfileDataAfterEdit() async {
    try {
      final profileData = await ApiUser.getUserProfile();

      if (profileData != null && profileData['user'] != null) {
        final user = profileData['user'];

        // 1. เซฟทับลงเครื่อง
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', user['username']);
        await prefs.setString('email', user['email']);
        await prefs.setString('phone', user['phone']);

        // 2. อัปเดตตัวแปร UI บนหน้าจอให้เปลี่ยนทันที
        String name = user['username'];
        userName.value = name;
        userInitials.value = _getInitials(name);

        print(
          "🔄 อัปเดตหน้า Profile เป็นข้อมูลผู้ใช้ใหม่ (จาก API) เรียบร้อย!",
        );
      }
    } catch (e) {
      print("Error reloading profile data: $e");
    }
  }

  void switchStore() {
    print("ไปยังหน้า เลือกสาขา");
    Get.off(MyShopPage());
  }

  void goToManageStores() async {
    print("ไปยังหน้า จัดการร้านค้า (Edit Shop)");

    try {
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
        ),
        barrierDismissible: false,
      );

      ShopResponse? currentShop = await ApiShop().getCurrentShop();

      await Future.delayed(const Duration(milliseconds: 300));

      if (Get.isDialogOpen == true) {
        Get.back();
      }

      if (currentShop != null) {
        var result = await Get.to(() => EditShopScreen(shop: currentShop));

        if (result == true) {
          await reloadShopDataAfterEdit();
        }
      } else {
        Get.snackbar(
          "แจ้งเตือน",
          "ไม่พบข้อมูลร้านค้า",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      if (Get.isDialogOpen == true) Get.back();
      Get.snackbar(
        "ข้อผิดพลาด",
        "ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> reloadShopDataAfterEdit() async {
    ShopResponse? freshShop = await ApiShop().getCurrentShop();

    if (freshShop != null) {
      shopName.value = freshShop.name;
      shopAddress.value = freshShop.address ?? "ไม่มีข้อมูลที่อยู่";
      shopImage.value = freshShop.imgShop;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('shopName', freshShop.name);
      await prefs.setString('shopAddress', freshShop.address ?? "");
      await prefs.setString('shop_image', freshShop.imgShop);

      print("🔄 อัปเดตหน้า Profile เป็นข้อมูลร้านค้าใหม่เรียบร้อย!");
    }
  }

  void goToSecurity() {
    print("ไปยังหน้า ความปลอดภัย");
    // Get.to(() => const SecurityScreen());
  }

  void goToSupport() {
    print("ไปยังหน้า ช่วยเหลือ");
    // Get.to(() => const SupportScreen());
  }

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
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      await prefs.clear();
                      Get.offAll(() => const LoginPage());
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
}
