import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eazy_store/config/app_config.dart';
import 'package:eazy_store/model/response/product_response.dart';
import '../buyProducts/buy_products_controller.dart';
import '../order_List/order_list.dart';
import 'package:eazy_store/page/menu_bar/bottom_navbar.dart'; // แก้ path ให้ตรง

class BuyProductsScreen extends StatelessWidget {
  const BuyProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ลงทะเบียน Controller
    final controller = Get.put(BuyProductsController());

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'สั่งซื้อสินค้า',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7F7F7),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 🔍 ส่วนค้นหาและเรียงลำดับ
          _buildTopActions(controller),

          const SizedBox(height: 10),

          // 📦 รายการสินค้า
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6B8E23)),
                );
              }

              if (controller.products.isEmpty) {
                return const Center(child: Text('ไม่พบรายการสินค้า'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 10,
                ),
                itemCount: controller.products.length,
                itemBuilder: (context, index) {
                  final product = controller.products[index];
                  return _buildProductItem(product, index, controller);
                },
              );
            }),
          ),

          // 🛒 ปุ่มยืนยันด้านล่าง (เช็คสถานะการเลือก)
          Obx(() => _buildConfirmButton(controller, context)),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: -1, // ใส่ -1 จะไม่มีปุ่มไหนถูกเลือก (ไม่มีสีแดงโชว์)
        onTap: (index) {
          // ใส่ Logic การเปลี่ยนหน้าตามปกติของคุณ
          print("Tab tapped: $index");
        },
      ),
    );
  }

  // --- Widgets ย่อย ---

  Widget _buildTopActions(BuyProductsController controller) {
    const Color themeGreen = Color(0xFF6B8E23); // กำหนดสีที่ใช้

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Column(
        // เปลี่ยนเป็น Column เพื่อให้ Dropdown อยู่ข้างล่าง Search
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  // แก้ไขเฉพาะส่วน TextField ใน _buildTopActions
                  child: TextField(
                    controller: controller.searchCtrl, // ✅ เชื่อม Controller
                    onChanged: (v) => controller.searchQuery.value = v,
                    decoration: InputDecoration(
                      hintText: 'ค้นหาหรือสแกนบาร์โค้ด',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFFB0B0B0),
                      ),
                      // ✅ แก้ไขส่วนปุ่มสแกน
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.qr_code_scanner_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () =>
                            controller.openScanner(), // ✅ กดแล้วเปิดกล้อง
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14.0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // ปุ่ม Sort (PopupMenu)
              PopupMenuButton<String>(
                icon: const Icon(Icons.swap_vert, color: themeGreen, size: 30),
                onSelected: (v) => controller.sortType.value = v,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'stock_asc',
                    child: Text('สต็อก: น้อยไปมาก'),
                  ),
                  const PopupMenuItem(
                    value: 'stock_desc',
                    child: Text('สต็อก: มากไปน้อย'),
                  ),
                  const PopupMenuItem(
                    value: 'name_asc',
                    child: Text('ชื่อ: ก-ฮ'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12), // เว้นระยะห่างเล็กน้อย

          // ✅ เพิ่ม Dropdown หมวดหมู่ตรงนี้
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 150, // ความกว้างคงที่ตามที่คุณต้องการ
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Obx(
                  () => DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: controller.selectedCategoryId.value,
                      isExpanded:
                          true, // ขยายเนื้อหาให้เต็มความกว้าง 150 ของ SizedBox
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF6B8E23),
                      ),
                      style: const TextStyle(
                        color: Color(0xFF6B8E23),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      onChanged: (val) {
                        if (val != null) {
                          controller.selectedCategoryId.value = val;
                        }
                      },
                      items: [
                        const DropdownMenuItem(
                          value: 0,
                          child: Text("หมวดหมู่"),
                        ),
                        ...controller.categories.map(
                          (cat) => DropdownMenuItem(
                            value: cat.categoryId,
                            child: Text(
                              cat.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(
    ProductResponse product,
    int index,
    BuyProductsController controller,
  ) {
    return GestureDetector(
      onTap: () => controller.toggleProduct(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: product.isSelected
                ? const Color(0xFF6B8E23)
                : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // รูปภาพสินค้า
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.imgProduct,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image_not_supported),
              ),
            ),
            const SizedBox(width: 15),
            // ข้อมูลสินค้า
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "คงเหลือ ${product.stock} ${product.unit}",
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 15,
                        ),
                      ),
                      if (product.stock == 0)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // ไอคอนเลือก
            Icon(
              product.isSelected ? Icons.check_circle : Icons.radio_button_off,
              color: product.isSelected
                  ? const Color(0xFF6B8E23)
                  : Colors.grey.shade300,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton(
    BuyProductsController controller,
    BuildContext context,
  ) {
    final int selectedCount = controller.selectedCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: selectedCount > 0
                ? () {
                    // ไปหน้าสรุปรายการสั่งซื้อ
                    Get.to(() => const OrderListScreen());
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B8E23),
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              selectedCount > 0
                  ? 'ยืนยัน ($selectedCount รายการ)'
                  : 'เลือกสินค้าเพื่อยืนยัน',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
