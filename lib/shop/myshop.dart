import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../api/api_shop.dart';
import '../model/response/shop_response.dart';
import 'create_shop.dart';
import 'edit_shop.dart'; // ตรวจสอบ path ให้ถูกต้องนะครับ
import '../homepage/home_page.dart';

// ----------------------------------------------------------------------
// 1. Controller: จัดการ Logic
// ----------------------------------------------------------------------
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

// ----------------------------------------------------------------------
// 2. The View: หน้าจอ UI
// ----------------------------------------------------------------------
class MyShopPage extends StatelessWidget {
  const MyShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    final MyShopController controller = Get.put(MyShopController());
    final Color primaryGreen = const Color(0xFF00C853);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // --- Top Section (Profile) ---
            Positioned(
              top: 20,
              right: 20,
              child: Row(
                children: [
                  Obx(
                    () => Text(
                      controller.userName.value,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.black,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 100),

                  // --- Title ---
                  const Center(
                    child: Text(
                      "ร้านค้าของฉัน",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      "ปัดซ้ายที่รายการเพื่อ แก้ไข หรือ ลบ",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- List Content (แก้ไขตรงนี้ให้ถูกต้อง) ---
                  Expanded(
                    child: Obx(() {
                      // 1. กำลังโหลด
                      if (controller.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // 2. มีข้อมูล -> แสดง List แบบ Modern
                      if (controller.shops.isNotEmpty) {
                        return ListView.builder(
                          itemCount: controller.shops.length,
                          itemBuilder: (context, index) {
                            final shop = controller.shops[index];

                            // --- 5. แก้ไขตรงนี้: ใส่ Slidable ครอบ Card ---
                            return Slidable(
                              key: ValueKey(shop.shopId),

                              // Action Pane ด้านขวา (ปัดซ้าย)
                              endActionPane: ActionPane(
                                motion: const ScrollMotion(),
                                children: [
                                  // ปุ่มแก้ไข
                                  SlidableAction(
                                    onPressed: (context) {
                                      controller.goToEditShop(shop);
                                    },
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    icon: Icons.edit,
                                    label: 'แก้ไข',
                                    borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(15),
                                    ),
                                  ),
                                  // ปุ่มลบ
                                  SlidableAction(
                                    onPressed: (context) {
                                      // แสดง Dialog ยืนยันก่อนลบ
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text("ยืนยันการลบ"),
                                          content: Text(
                                            "คุณต้องการลบร้าน '${shop.name}' ใช่หรือไม่?",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                              child: const Text("ยกเลิก"),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(
                                                  ctx,
                                                ); // ปิด Dialog
                                                controller.deleteShop(
                                                  shop.shopId,
                                                ); // แจ้ง Controller ให้ลบ
                                              },
                                              child: const Text(
                                                "ลบ",
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    icon: Icons.delete,
                                    label: 'ลบ',
                                    borderRadius: const BorderRadius.horizontal(
                                      right: Radius.circular(15),
                                    ),
                                  ),
                                ],
                              ),

                              // ตัว Card เดิมของคุณ
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 15),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(10),
                                  leading: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(10),
                                      image: shop.imgShop.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(shop.imgShop),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: shop.imgShop.isEmpty
                                        ? const Icon(
                                            Icons.store,
                                            color: Colors.grey,
                                          )
                                        : null,
                                  ),
                                  title: Text(
                                    shop.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(shop.phone),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                  onTap: () => controller.selectShop(shop),
                                ),
                              ),
                            );
                          },
                        );
                      }

                      // 3. ไม่มีข้อมูล -> แสดง Empty State
                      return Center(
                        child: Text(
                          "คุณยังไม่มีร้านค้า",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }),
                  ),

                  // --- Bottom Button ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: controller.goToAddShop,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "เพิ่มร้านค้า",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
