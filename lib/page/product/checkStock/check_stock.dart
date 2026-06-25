import 'package:eazy_store/page/product/checkStock/check_stock_controller.dart';
import 'package:eazy_store/widgets/pagination_controls.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:eazy_store/page/menu_bar/bottom_navbar.dart';
import 'package:eazy_store/model/response/product_response.dart';
import 'package:eazy_store/page/product/product_detail/product_detail.dart';

class CheckStockScreen extends StatelessWidget {
  const CheckStockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CheckStockController controller = Get.put(CheckStockController());

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
      // ✨ 1. หุ้มด้วย MediaQuery จำกัดการขยายฟอนต์สูงสุด 1.2 เท่า
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: MediaQuery.textScalerOf(
            context,
          ).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.2),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  _buildSearchBar(controller, primaryColor),
                  const SizedBox(height: 15),
                  _buildFilterAndSortRow(controller),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            // 📦 รายการสินค้า
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.products.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }
                if (controller.filteredProducts.isEmpty) {
                  return const Center(child: Text("ไม่พบข้อมูลสินค้า"));
                }

                return RefreshIndicator(
                  color: primaryColor,
                  onRefresh: () => controller.fetchStockData(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    physics: const AlwaysScrollableScrollPhysics(),
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

            // ✨ ส่วนควบคุมการแบ่งหน้า (Pagination Bar)
            PaginationControls(
              controller: controller,
              primaryColor: primaryColor,
            ),
          ],
        ),
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

  Widget _buildFilterAndSortRow(CheckStockController controller) {
    const Color themeGreen = Color(0xFF6B8E23);
    return Row(
      children: [
        // Dropdown หมวดหมู่
        Expanded(
          flex: 5,
          child: Obx(
            () => Container(
              // ✨ ถอด height: 42 ออก ใช้ Padding แทน ให้มันขยายตามฟอนต์
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
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
                        child: Text(cat.name, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // ✨ ห่อปุ่มเรียงลำดับด้วย Expanded ป้องกันมันโดนเบียดตกจอ
        Expanded(
          flex: 4,
          child: InkWell(
            onTap: controller.toggleSort,
            borderRadius: BorderRadius.circular(25),
            child: Obx(
              () => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: themeGreen.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                // ✨ ใส่ FittedBox เพื่อย่อตัวหนังสือถ้ามันยาวไป
                child: FittedBox(
                  fit: BoxFit.scaleDown,
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
                          fontSize: 13,
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
        ),
      ],
    );
  }

  Widget _buildSearchBar(CheckStockController controller, Color primaryColor) {
    return Container(
      // ✨ ปลด height: 50 ออก
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: TextField(
        controller: controller.searchCtrl,
        onSubmitted: (val) => controller.searchProduct(val),
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: 'ค้นหาชื่อสินค้า หรือ บาร์โค้ด...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: controller.openScanner,
          ),
          border: InputBorder.none,
          isDense: true, // ทำให้ช่องไม่สูงเกินไปเวลาถอด height ออก
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14.0,
            horizontal: 12.0,
          ),
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
