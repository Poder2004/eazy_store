import 'package:eazy_store/page/product/checkStock/check_stock_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:eazy_store/page/menu_bar/bottom_navbar.dart';
import 'package:eazy_store/model/response/product_response.dart';
import 'package:eazy_store/page/product/product_detail/product_detail.dart';

class CheckStockScreen extends StatelessWidget {
  const CheckStockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // เรียกใช้ Controller ผ่าน Get.put
    final StockController controller = Get.put(StockController());

    const Color primaryColor = Color(0xFF6B8E23);
    const Color warningColor = Color(0xFFFFCC00);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          'เช็คสต็อกสินค้า',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            _buildSearchBar(controller, primaryColor),
            const SizedBox(height: 15),
            _buildFilterAndSortRow(controller),
            const SizedBox(height: 15),

            // 📦 รายการสินค้า
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }
                if (controller.filteredProducts.isEmpty) {
                  return const Center(child: Text("ไม่พบข้อมูลสินค้า"));
                }

                return RefreshIndicator(
                  color: primaryColor,
                  onRefresh: () =>
                      controller.fetchStockData(), // ดึงข้อมูลใหม่เมื่อรูดลง
                  child: ListView.builder(
                    physics:
                        const AlwaysScrollableScrollPhysics(), // ต้องใส่เพื่อให้รูดได้แม้รายการจะน้อย
                    itemCount: controller.filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = controller.filteredProducts[index];
                      return InkWell(
                        onTap: () async {
                          var result = await Get.to(
                            () => const ProductDetailScreen(),
                            arguments: product,
                            transition: Transition.rightToLeft,
                          );
                          if (result == true) {
                            controller.fetchStockData();
                          }
                        },
                        borderRadius: BorderRadius.circular(15),
                        child: _buildProductCard(product, warningColor),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () => BottomNavBar(
          currentIndex: controller.selectedIndex.value,
          onTap: controller.changeTab,
        ),
      ),
    );
  }

  // --- UI Components ที่ดึงค่ามาจาก controller ---

  Widget _buildFilterAndSortRow(StockController controller) {
    // สีเขียวหลักจากหน้าแอปของคุณ
    const Color themeGreen = Color(0xFF6B8E23);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Obx(
              () => Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25), // มนสวยแบบในรูป
                  border: Border.all(
                    color: themeGreen.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: controller.selectedCategoryId.value,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: themeGreen,
                    ),
                    style: const TextStyle(
                      color: themeGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    onChanged: (val) => controller.filterByCategory(val),
                    items: [
                      const DropdownMenuItem(value: 0, child: Text("หมวดหมู่")),
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

          const SizedBox(width: 8),

          const Row(
            children: [
              Icon(Icons.sort, size: 20, color: Colors.grey),
              SizedBox(width: 4),
              Text(
                "เรียงโดย:",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // 3. ปุ่มสลับ น้อย-มาก (สไตล์เดียวกับ Dropdown)
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: controller.toggleSort,
              borderRadius: BorderRadius.circular(25),
              child: Obx(
                () => Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: themeGreen.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        controller.isAscending.value
                            ? "น้อย → มาก"
                            : "มาก → น้อย",
                        style: const TextStyle(
                          color: themeGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.swap_vert, size: 18, color: themeGreen),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(StockController controller, Color primaryColor) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: TextField(
        controller: controller.searchCtrl,
        onChanged: controller.searchProduct,
        decoration: InputDecoration(
          hintText: 'ค้นหาชื่อสินค้า หรือ บาร์โค้ด...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: controller.openScanner,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductResponse product, Color warningColor) {
    final bool isLowStock = product.stock <= 10;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            product.imgProduct,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('คงเหลือ ${product.stock} ${product.unit}'),
        trailing: isLowStock ? Icon(Icons.warning, color: warningColor) : null,
      ),
    );
  }
}
