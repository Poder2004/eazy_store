import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_shop.dart';
import '../model/response/shop_response.dart';
import 'create_shop.dart'; 

// ----------------------------------------------------------------------
// 1. Controller: จัดการ Logic ดึงข้อมูลและแสดงผล
// ----------------------------------------------------------------------
class MyShopController extends GetxController {
  final ApiShop _apiShop = ApiShop();
  
  // ตัวแปร Observable
  var isLoading = true.obs;          // เช็คว่าโหลดอยู่ไหม
  var shops = <ShopResponse>[].obs;  // เก็บรายการร้านค้า
  var userName = "ชื่อ นามสกุล".obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData(); // โหลดชื่อ
    fetchShops();   // โหลดร้านค้า
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
    print("กดปุ่มเพิ่มร้านค้า");
    // รอให้ไปหน้า CreateShop แล้วกลับมาค่อย refresh ข้อมูล
    await Get.to(() => CreateShopPage());
    fetchShops(); 
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
                    backgroundColor: Colors.black,
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                    ),
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

                  // --- 2. Title ---
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

                  const SizedBox(height: 20),

                  // --- 3. Dynamic Content (List หรือ Empty) ---
                  // ใช้ Expanded เพื่อให้พื้นที่ส่วนกลางยืดเต็มที่
                  Expanded(
                    child: Obx(() {
                      // 3.1 กำลังโหลดข้อมูล
                      if (controller.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // 3.2 มีข้อมูลร้านค้า (แสดง List)
                      if (controller.shops.isNotEmpty) {
                        return ListView.builder(
                          itemCount: controller.shops.length,
                          itemBuilder: (context, index) {
                            final shop = controller.shops[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 15),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)
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
                                    ? const Icon(Icons.store, color: Colors.grey) 
                                    : null,
                                ),
                                title: Text(
                                  shop.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(shop.phone),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () {
                                   // TODO: ใส่โค้ดกดเข้าร้านค้าตรงนี้
                                },
                              ),
                            );
                          },
                        );
                      }

                      // 3.3 ไม่มีข้อมูล (แสดง Empty State แบบเดิม)
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

                  // --- 4. Bottom Button ---
                  // ปุ่มยังคงอยู่ด้านล่างเสมอ ไม่ว่าจะมีร้านหรือไม่มี
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