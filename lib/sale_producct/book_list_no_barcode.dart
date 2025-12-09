import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ----------------------------------------------------------------------
// 1. Model: โครงสร้างข้อมูลสินค้า
// ----------------------------------------------------------------------
class ProductItem {
  final String id;
  final String name;
  final double price;
  final String category;
  final IconData icon; // ใช้ Icon แทนรูปภาพจริงไปก่อนเพื่อให้รันได้เลย
  RxBool isSelected; // ใช้ RxBool เพื่อให้ปุ่ม Radio อัปเดตตัวเองได้

  ProductItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.icon,
    bool selected = false,
  }) : isSelected = selected.obs;
}

// ----------------------------------------------------------------------
// 2. Controller: จัดการ Logic รายการสินค้า
// ----------------------------------------------------------------------
class ManualListController extends GetxController {
  // Mock Data: จำลองข้อมูลสินค้าตามรูป
  final List<ProductItem> allProducts = [
    ProductItem(
      id: '1',
      name: 'น้ำแข็ง',
      price: 10,
      category: 'อื่นๆ',
      icon: Icons.ac_unit,
    ),
    ProductItem(
      id: '2',
      name: 'ไม้กวาด',
      price: 40,
      category: 'ของใช้',
      icon: Icons.cleaning_services,
    ),
    ProductItem(
      id: '3',
      name: 'ขนมถุง',
      price: 20,
      category: 'ขนมขบเคี้ยว',
      icon: Icons.cookie,
      selected: true,
    ), // ตัวอย่างเลือกไว้
    ProductItem(
      id: '4',
      name: 'ปุ๋ยยูเรีย 1 กิโล',
      price: 33,
      category: 'การเกษตร',
      icon: Icons.grass,
      selected: true,
    ),
    ProductItem(
      id: '5',
      name: 'ถ่านจุดไฟ',
      price: 20,
      category: 'เชื้อเพลิง',
      icon: Icons.whatshot,
      selected: true,
    ),
  ];

  // ตัวแปรสำหรับค้นหาและกรอง
  var searchQuery = "".obs;
  var selectedCategory = "หมวดหมู่".obs;

  // รายการหมวดหมู่
  final List<String> categories = [
    "หมวดหมู่",
    "เครื่องดื่ม",
    "ขนมขบเคี้ยว",
    "อาหารสด",
    "อื่นๆ",
  ];

  // ฟังก์ชันสลับการเลือก (Toggle Radio)
  void toggleSelection(ProductItem product) {
    product.isSelected.value = !product.isSelected.value;
    update(); // อัปเดต UI (เผื่อใช้ GetBuilder)
  }

  // ฟังก์ชันกดปุ่ม "ไปคิดเงิน"
  void goToCheckout() {
    // กรองเอาเฉพาะตัวที่เลือก
    final selectedItems = allProducts.where((p) => p.isSelected.value).toList();
    if (selectedItems.isEmpty) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณาเลือกสินค้าอย่างน้อย 1 ชิ้น",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } else {
      print("ไปคิดเงิน: ${selectedItems.length} รายการ");
      // Get.to(() => CheckoutPage(items: selectedItems)); // ใส่หน้าคิดเงินตรงนี้
    }
  }
}

// ----------------------------------------------------------------------
// 3. The View: หน้าจอ UI
// ----------------------------------------------------------------------
class ManualListPage extends StatelessWidget {
  const ManualListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ManualListController controller = Get.put(ManualListController());
    final Color primaryGreen = const Color(0xFF00C853); // สีเขียวปุ่ม
    final Color activeBlue = const Color(0xFF2979FF); // สีฟ้าปุ่ม Radio

    return Scaffold(
      backgroundColor: Colors.white,
      // --- AppBar ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "สมุดสินค้าไม่มีบาร์โค้ด",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),

      body: Column(
        children: [
          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                onChanged: (val) => controller.searchQuery.value = val,
                decoration: const InputDecoration(
                  hintText: "ค้นหาชื่อสินค้า",
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 15,
                  ),
                ),
              ),
            ),
          ),

          // --- Category Dropdown ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Obx(
                  () => DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: controller.selectedCategory.value,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.black,
                      ),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          controller.selectedCategory.value = newValue;
                        }
                      },
                      items: controller.categories
                          .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          })
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // --- Product List ---
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: controller.allProducts.length,
              itemBuilder: (context, index) {
                final product = controller.allProducts[index];
                return _buildProductCard(product, activeBlue, controller);
              },
            ),
          ),

          // --- Checkout Button ---
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: controller.goToCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853), // สีเขียวสว่าง
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.white,
                ),
                label: const Text(
                  "ไปคิดเงิน",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget การ์ดสินค้าแต่ละรายการ
  Widget _buildProductCard(
    ProductItem product,
    Color activeColor,
    ManualListController controller,
  ) {
    return GestureDetector(
      onTap: () => controller.toggleSelection(product),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // 1. รูปสินค้า (ใช้ Icon แทนไปก่อน)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(product.icon, size: 30, color: Colors.grey[600]),
            ),

            const SizedBox(width: 15),

            // 2. ชื่อและราคา
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${product.price.toInt()} บาท", // ตัดทศนิยมออกตามรูป
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

            // 3. ปุ่ม Radio (วงกลม)
            Obx(
              () => Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: product.isSelected.value
                      ? activeColor
                      : Colors.transparent,
                  border: Border.all(
                    color: product.isSelected.value
                        ? activeColor
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: product.isSelected.value
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
