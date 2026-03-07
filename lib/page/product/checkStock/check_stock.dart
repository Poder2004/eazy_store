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
      body: Column(
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
          _buildPaginationControls(controller, primaryColor),
        ],
      ),
      bottomNavigationBar: Obx(
        () => BottomNavBar(
          currentIndex: controller.selectedIndex.value,
          onTap: controller.changeTab,
        ),
      ),
    );
  }

  // --- เพิ่ม Widget สำหรับคุมหน้าหน้าสินค้า ---
  Widget _buildPaginationControls(
    StockController controller,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
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
        // เพิ่มเพื่อป้องกันการทับซ้อนกับแถบนำทางของระบบในบางรุ่น
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // --- ส่วนที่ 1: เลือกจำนวนรายการต่อหน้า (Limit) ---
            Row(
              children: [
                const Text(
                  "แสดง: ",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 5),
                Container(
                  width: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Obx(
                    () => TextField(
                      controller:
                          TextEditingController(
                              text: controller.itemsPerPage.value.toString(),
                            )
                            ..selection = TextSelection.collapsed(
                              offset: controller.itemsPerPage.value
                                  .toString()
                                  .length,
                            ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      onSubmitted: (val) {
                        int? limit = int.tryParse(val);
                        if (limit != null && limit > 0) {
                          controller.updateLimit(limit);
                        }
                      },
                    ),
                  ),
                ),
                PopupMenuButton<int>(
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.grey,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 60),
                  onSelected: (int value) => controller.updateLimit(value),
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
                    const PopupMenuItem<int>(value: 10, child: Text('10')),
                    const PopupMenuItem<int>(value: 20, child: Text('20')),
                    const PopupMenuItem<int>(value: 30, child: Text('30')),
                    const PopupMenuItem<int>(value: 50, child: Text('50')),
                  ],
                ),
                const Text(
                  "รายการ",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),

            // --- ส่วนที่ 2: ปุ่มเลื่อนหน้า (ย้อนกลับ - ถัดไป) ---
            // ย้าย Obx มาคลุมทั้ง Row เพื่อให้ปุ่มอัปเดตสถานะ (onPressed null/not null)
            Obx(
              () => Row(
                children: [
                  IconButton(
                    onPressed: controller.currentPage.value > 1
                        ? () => controller.changePage(
                            controller.currentPage.value - 1,
                          )
                        : null,
                    icon: Icon(
                      Icons.arrow_back_ios,
                      size: 16,
                      color: controller.currentPage.value > 1
                          ? primaryColor
                          : Colors.grey,
                    ),
                  ),
                  Text(
                    "${controller.currentPage.value} / ${controller.totalPages.value}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  IconButton(
                    onPressed:
                        controller.currentPage.value <
                            controller.totalPages.value
                        ? () => controller.changePage(
                            controller.currentPage.value + 1,
                          )
                        : null,
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color:
                          controller.currentPage.value <
                              controller.totalPages.value
                          ? primaryColor
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI Components อื่นๆ เหมือนเดิม ---

  Widget _buildFilterAndSortRow(StockController controller) {
    const Color themeGreen = Color(0xFF6B8E23);
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Obx(
            () => Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
        InkWell(
          onTap: controller.toggleSort,
          borderRadius: BorderRadius.circular(25),
          child: Obx(
            () => Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: themeGreen.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    controller.isAscending.value ? "น้อย → มาก" : "มาก → น้อย",
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
      ],
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
        onSubmitted: (val) => controller.searchProduct(
          val,
        ), // แก้เป็นค้นหาเมื่อกด Enter หรือปุ่มค้นหา
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
