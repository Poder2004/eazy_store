import 'package:eazy_store/page/add_product.dart';
import 'package:eazy_store/page/add_stock.dart';
import 'package:eazy_store/page/check_price.dart';
import 'package:eazy_store/page/check_stock.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../menu_bar/bottom_navbar.dart';

class HomeController extends GetxController {
  var currentIndex = 0.obs;

  void changeTab(int index) {
    currentIndex.value = index;
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.put(HomeController());
    // สีดำเข้มสำหรับหัวข้อ
    final Color textDark = const Color(0xFF2D2D2D);
    // สีเขียวสดใสสำหรับไอคอน (เผื่อรูปเป็นสีขาว หรือใช้ tint)
    // *หมายเหตุ: ถ้ารูป png มีสีเขียวอยู่แล้ว ให้เอา color: ... ออกใน Image.asset ด้านล่าง
    final Color iconTint = const Color(0xFF64DD17);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FB),
      body: SafeArea(
        // ใช้ LayoutBuilder เพื่อเช็คขนาดหน้าจอ (Responsive Tablet/Mobile)
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Center(
                child: Container(
                  // จำกัดความกว้างสูงสุด 600px เพื่อให้ดูดีบน Tablet ไม่ยืดเกินไป
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // --- 1. หัวข้อชื่อร้าน ---
                      const Text(
                        "ร้าน",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "จันทร์เพ็ญ",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),

                      const SizedBox(height: 50),

                      // --- 2. Grid Menu (4 ปุ่มหลัก) ---
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2, // 2 คอลัมน์
                        crossAxisSpacing: 20, // ระยะห่างแนวนอน
                        mainAxisSpacing: 20, // ระยะห่างแนวตั้ง
                        childAspectRatio:
                            1.0, // สัดส่วน 1:1 (สี่เหลี่ยมจัตุรัส) ตามรูปที่ 2
                        children: [
                          // 2.1 เพิ่มสินค้า -> plus.png
                          _buildMenuCard(
                            imagePath: 'assets/image/Plus.png',
                            title: "เพิ่มสินค้า",
                            onTap: () {
                              Get.to(() => const AddProductScreen());
                            },
                          ),
                          // 2.2 เช็คราคาสินค้า -> checkprice.png
                          _buildMenuCard(
                            imagePath: 'assets/image/checkprice.png',
                            title: "เช็คราคาสินค้า",
                            onTap: () {
                              Get.to(() => const CheckPriceScreen());
                            },
                          ),
                          // 2.3 เพิ่มสต็อกสินค้า -> Box.png
                          _buildMenuCard(
                            imagePath: 'assets/image/Box.png',
                            title: "เพิ่มสต็อก\nสินค้า",
                            onTap: () {
                              Get.to(() => const AddStockScreen());
                            },
                          ),
                          // 2.4 เช็คสต็อกสินค้า -> stock.png
                          _buildMenuCard(
                            imagePath: 'assets/image/stock.png',
                            title: "เช็คสต็อก\nสินค้า",
                            onTap: () {
                              Get.to(() => const StockCheckScreen());
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // --- 3. ปุ่มยาวด้านล่าง (สั่งซื้อสินค้า) -> Bill.png ---
                      GestureDetector(
                        onTap: () {
                          print("กดปุ่มสั่งซื้อสินค้า");
                        },
                        child: Container(
                          height: 90, // ปรับความสูงให้สมดุล
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              20,
                            ), // มุมโค้งมนขึ้น
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // ไอคอน Bill.png
                              Image.asset(
                                'assets/image/Bill.png',
                                width: 50,
                                height: 50,
                                // color: iconTint, // เปิดบรรทัดนี้ถ้าต้องการย้อมสีไอคอน
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.receipt_long,
                                      size: 50,
                                      color: Colors.green,
                                    ),
                              ),
                              const SizedBox(width: 20),
                              Text(
                                "สั่งซื้อสินค้า",
                                style: TextStyle(
                                  fontSize: 26, // ตัวใหญ่ชัดเจน
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 50,
                      ), // เผื่อพื้นที่ให้ปุ่ม Floating ด้านล่าง
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),

      // --- ปุ่มตะกร้าลอย (Floating Action Button) ---
      floatingActionButton: SizedBox(
        width: 70,
        height: 70,
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: Colors.white,
          shape: const CircleBorder(),
          elevation: 5,
          child: const Icon(
            Icons.shopping_basket,
            size: 35,
            color: Color(0xFF64DD17),
          ),
        ),
      ),
      // ขยับปุ่มตะกร้าขึ้นมาจากขอบล่างหน่อย ไม่ให้ทับ Navbar เกินไป
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: Obx(
        () => BottomNavBar(
          currentIndex: controller.currentIndex.value,
          onTap: controller.changeTab,
        ),
      ),
    );
  }

  // Widget สร้างการ์ดเมนู (ใช้รูปภาพ png)
  Widget _buildMenuCard({
    required String imagePath,
    required String title,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            20,
          ), // ความมนของมุม (ตามรูปดูมนเยอะหน่อย)
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // แสดงรูปภาพไอคอน
            Image.asset(
              imagePath,
              width: 60, // ขนาดไอคอน
              height: 60,
              // color: const Color(0xFF64DD17), // <--- ถ้าต้องการย้อมสีเขียวให้เปิดบรรทัดนี้
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.image_not_supported,
                size: 50,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20, // ปรับขนาดตัวอักษรให้ใหญ่อ่านง่าย
                fontWeight: FontWeight.bold,
                color: Color(0xFF3E2723), // สีน้ำตาลเข้ม
                height: 1.1, // ระยะห่างบรรทัด
              ),
            ),
          ],
        ),
      ),
    );
  }
}
