import 'package:eazy_store/page/product/checkStock/check_stock_controller.dart';
import 'package:eazy_store/widgets/pagination_controls.dart';
import 'package:eazy_store/widgets/product_filter_sheet.dart';
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
                  Row(
                    children: [
                      Expanded(child: _buildSearchBar(controller, primaryColor)),
                      const SizedBox(width: 12),
                      Obx(
                        () => ProductFilterButton(
                          categories: controller.categories,
                          selectedCategoryId: controller.selectedCategoryId.value,
                          sortFields: defaultProductSortFields,
                          selectedSortValue: controller.selectedSortOption.value,
                          defaultSortValue: 'stock_asc',
                          onApply: (categoryId, sortValue) =>
                              controller.applyFilter(
                                categoryId: categoryId,
                                sortOption: sortValue,
                              ),
                          onClear: controller.clearFilter,
                        ),
                      ),
                    ],
                  ),
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

            PaginationControls(
              currentPage: controller.currentPage,
              totalPages: controller.totalPages,
              itemsPerPage: controller.itemsPerPage,
              updateLimit: controller.updateLimit,
              changePage: controller.changePage,
              primaryColor: primaryColor,
              isLoading: controller.isLoading,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: -1,
        onTap: (index) {
          print("Tab tapped: $index");
        },
      ),
    );
  }

  Widget _buildSearchBar(CheckStockController controller, Color primaryColor) {
    return Container(
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
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14.0,
            horizontal: 12.0,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductResponse product, Color warningColor) {
    final bool isOutOfStock = product.stock == 0;
    final bool isLowStock = product.stock <= 10;
    final Color stockColor = isLowStock
        ? const Color(0xFFE53935)
        : const Color(0xFF2E7D32);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isLowStock) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isOutOfStock ? 'สินค้าหมด' : 'สินค้าใกล้หมด',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: stockColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isOutOfStock
                              ? Icons.remove_circle_rounded
                              : Icons.warning_rounded,
                          color: isOutOfStock ? stockColor : warningColor,
                          size: 15,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'คงเหลือ',
                  style: TextStyle(fontSize: 11, color: Colors.black45),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${product.stock}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: stockColor,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      product.unit,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: stockColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
