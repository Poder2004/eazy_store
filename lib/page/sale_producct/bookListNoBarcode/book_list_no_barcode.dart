import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eazy_store/model/request/baskets_model.dart';
import 'package:eazy_store/widgets/pagination_controls.dart';
import 'package:eazy_store/widgets/product_filter_sheet.dart';
import 'package:eazy_store/page/sale_producct/sale/checkout_controller.dart'; // ใช้ formatMoney()
import 'book_list_no_barcode_controller.dart';

// ----------------------------------------------------------------------
// สมุดสินค้า — 2 แท็บ: ไม่มีบาร์โค้ด / มีบาร์โค้ด
// (ช่องค้นหา + ตัวกรอง + ปุ่มเพิ่มลงรายการขาย ใช้ร่วมกันทั้ง 2 แท็บ)
// ----------------------------------------------------------------------
class ManualListPage extends StatelessWidget {
  const ManualListPage({super.key});

  static const Color _activeBlue = Color(0xFF2979FF);
  static const Color _primaryColor = Color(0xFF6B8E23);

  @override
  Widget build(BuildContext context) {
    final ManualListController controller = Get.put(ManualListController());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.grey),
            onPressed: () => Get.back(),
          ),
          title: const Text(
            "สมุดสินค้า",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(58),
            child: _buildTabBar(),
          ),
        ),
        body: Column(
          children: [
            _buildSearchAndFilter(controller),
            const SizedBox(height: 10),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTabBody(
                    controller: controller,
                    products: controller.pagedProducts,
                    emptyText: "ยังไม่มีสินค้าที่ไม่มีบาร์โค้ด",
                    currentPage: controller.currentPage,
                    totalPages: controller.totalPages,
                    itemsPerPage: controller.itemsPerPage,
                    updateLimit: controller.updateLimit,
                    changePage: controller.changePage,
                  ),
                  _buildTabBody(
                    controller: controller,
                    products: controller.pagedBarcodeProducts,
                    emptyText: "ยังไม่มีสินค้าที่มีบาร์โค้ด",
                    currentPage: controller.currentPageBarcode,
                    totalPages: controller.totalPagesBarcode,
                    itemsPerPage: controller.itemsPerPageBarcode,
                    updateLimit: controller.updateLimitBarcode,
                    changePage: controller.changePageBarcode,
                  ),
                ],
              ),
            ),
            _buildCheckoutButton(controller),
          ],
        ),
      ),
    );
  }

  // แท็บสไตล์ segmented — active เป็นพื้นขาว, inactive เทาจาง
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: TabBar(
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          labelColor: _activeBlue,
          unselectedLabelColor: Colors.grey.shade500,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: "ไม่มีบาร์โค้ด"),
            Tab(text: "มีบาร์โค้ด"),
          ],
        ),
      ),
    );
  }

  // เนื้อหาของแต่ละแท็บ: list + pagination ของแท็บนั้นๆ
  Widget _buildTabBody({
    required ManualListController controller,
    required RxList<ProductItem> products,
    required String emptyText,
    required RxInt currentPage,
    required RxInt totalPages,
    required RxInt itemsPerPage,
    required void Function(int) updateLimit,
    required void Function(int) changePage,
  }) {
    return Column(
      children: [
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (products.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      emptyText,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return _buildProductCard(
                  products[index],
                  _activeBlue,
                  controller,
                );
              },
            );
          }),
        ),
        PaginationControls(
          currentPage: currentPage,
          totalPages: totalPages,
          itemsPerPage: itemsPerPage,
          updateLimit: updateLimit,
          changePage: changePage,
          primaryColor: _primaryColor,
          isLoading: controller.isLoading,
        ),
      ],
    );
  }

  Widget _buildProductCard(
    ProductItem product,
    Color activeColor,
    ManualListController controller,
  ) {
    return GestureDetector(
      onTap: () => controller.toggleSelection(product.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                product.imagePath,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  width: 70,
                  height: 70,
                  child: const Icon(Icons.image_outlined, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${formatMoney(product.price)} บาท",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            Obx(() {
              final isSelected = controller.selectedIds.contains(product.id);
              return Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? activeColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? activeColor : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }

  // ช่องค้นหา + ปุ่มตัวกรอง (หมวดหมู่+จัดเรียง) วางเรียงกันแบบเดียวกับหน้าเช็คสต็อกสินค้า
  Widget _buildSearchAndFilter(ManualListController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                onChanged: (val) => controller.searchQuery.value = val,
                decoration: const InputDecoration(
                  hintText: "ค้นหาชื่อสินค้า",
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
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
              selectedSortValue: controller.selectedSortOption.value,
              defaultSortValue: 'name_asc',
              onApply: (categoryId, sortValue) => controller.applyFilter(
                categoryId: categoryId,
                sortOption: sortValue,
              ),
              onClear: controller.clearFilter,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton(ManualListController controller) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: controller.goToCheckout,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C853),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
          label: Obx(
            () => Text(
              controller.selectedIds.isEmpty
                  ? "เพิ่มลงรายการขาย"
                  : "เพิ่มลงรายการขาย (${controller.selectedIds.length})",
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
