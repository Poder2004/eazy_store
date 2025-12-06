import 'package:eazy_store/shop/create_shop.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ----------------------------------------------------------------------
// 1. Controller: จัดการ Logic ของหน้าร้านค้า
// ----------------------------------------------------------------------
class MyShopController extends GetxController {
  // จำลองชื่อผู้ใช้ที่เพิ่งสมัครมา
  final userName = "ชื่อ นามสกุล".obs;

  void goToAddShop() {
    print("กดปุ่มเพิ่มร้านค้า");
    Get.to(() => CreateShopPage()); // ใส่หน้าที่ต้องการไปต่อตรงนี้
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
            // --- 1. Top Section (Profile) ---
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
                    backgroundColor: Colors.black, // พื้นหลัง icon สีดำตามรูป
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                    ), // ไอคอนคนสีขาว
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // จัดชิดซ้ายตามรูป
                children: [
                  // เว้นระยะลงมาหน่อยให้พ้น Profile
                  const SizedBox(height: 100),

                  // --- 2. Title ---
                  const Center(
                    // แต่หัวข้อจัดกึ่งกลาง
                    child: Text(
                      "ร้านค้าของฉัน",
                      style: TextStyle(
                        fontSize: 32, // ใหญ่สะใจตามรูป
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  // --- 3. Center Empty State ---
                  // ใช้ Expanded ดันให้ข้อความนี้ไปอยู่กลางจอพอดี
                  Expanded(
                    child: Center(
                      child: Text(
                        "คุณยังไม่มีร้านค้า",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[400], // สีเทาจางๆ ตามรูป
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  // --- 4. Bottom Button ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: controller.goToAddShop,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen, // สีเขียว
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25), // ปุ่มมน
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

                  // เว้นระยะจากขอบล่าง
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
