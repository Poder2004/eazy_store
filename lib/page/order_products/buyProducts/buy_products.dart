import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eazy_store/config/app_config.dart';
import 'package:eazy_store/model/response/product_response.dart';
import 'package:eazy_store/widgets/product_filter_sheet.dart';
import 'package:eazy_store/widgets/pagination_controls.dart';
import '../buyProducts/buy_products_controller.dart';
import '../order_List/order_list.dart';

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

              if (controller.allProducts.isEmpty) {
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

          PaginationControls(
            currentPage: controller.currentPage,
            totalPages: controller.totalPages,
            itemsPerPage: controller.itemsPerPage,
            updateLimit: controller.updateLimit,
            changePage: controller.changePage,
            primaryColor: const Color(0xFF6B8E23),
          ),

          // 🛒 ปุ่มยืนยันด้านล่าง (เช็คสถานะการเลือก)
          Obx(() => _buildConfirmButton(controller, context)),
        ],
      ),
    );
  }

  // --- Widgets ย่อย ---

  Widget _buildTopActions(BuyProductsController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Row(
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
              child: TextField(
                controller: controller.searchCtrl,
                onChanged: (v) => controller.searchQuery.value = v,
                decoration: InputDecoration(
                  hintText: 'ค้นหาหรือสแกนบาร์โค้ด',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFFB0B0B0),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.qr_code_scanner_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () => controller.openScanner(),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Obx(
            () => ProductFilterButton(
              categories: controller.categories,
              selectedCategoryId: controller.selectedCategoryId.value,
              sortFields: defaultProductSortFields,
              selectedSortValue: controller.sortType.value,
              defaultSortValue: 'stock_asc',
              onApply: (categoryId, sortValue) => controller.applyFilter(
                categoryId: categoryId,
                sortValue: sortValue,
              ),
              onClear: controller.clearFilter,
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
    final bool isOutOfStock = product.stock == 0;
    final bool isLowStock = product.stock <= 10;
    final Color stockColor = isOutOfStock
        ? const Color(0xFFE53935)
        : isLowStock
        ? const Color(0xFFB8860B)
        : Colors.black54;

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
                        style: TextStyle(
                          color: stockColor,
                          fontSize: 15,
                          fontWeight: isLowStock
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      if (isLowStock) ...[
                        const SizedBox(width: 6),
                        Icon(
                          isOutOfStock
                              ? Icons.remove_circle_rounded
                              : Icons.warning_rounded,
                          color: isOutOfStock
                              ? stockColor
                              : const Color(0xFFFFCC00),
                          size: 16,
                        ),
                      ],
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
