import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eazy_store/model/request/baskets_model.dart';
import 'book_list_no_barcode_controller.dart';

// ----------------------------------------------------------------------
// 3. View (UI คงเดิม)
// ----------------------------------------------------------------------
class ManualListPage extends StatelessWidget {
  const ManualListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ManualListController controller = Get.put(ManualListController());
    final Color activeBlue = const Color(0xFF2979FF);

    return Scaffold(
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
      ),
      body: Column(
        children: [
          _buildTabs(controller, activeBlue),
          const SizedBox(height: 12),
          _buildSearchAndFilter(controller),
          const SizedBox(height: 10),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = controller.currentFilteredList;
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    controller.activeTab.value == 0
                        ? "ไม่พบสินค้าไม่มีบาร์โค้ด"
                        : "ไม่พบสินค้าที่มีบาร์โค้ด",
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(list[index], activeBlue, controller);
                },
              );
            }),
          ),
          _buildCheckoutButton(controller),
        ],
      ),
    );
  }

  // แท็บสลับระหว่างสินค้าไม่มีบาร์โค้ด (ดีฟอลต์) กับสินค้าที่มีบาร์โค้ด
  // เผื่อกรณีสแกนไม่ติด จะได้มาหาจากตรงนี้แทนได้
  Widget _buildTabs(ManualListController controller, Color activeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Obx(
          () => Row(
            children: [
              Expanded(
                child: _buildTabButton(
                  controller,
                  index: 0,
                  label: "ไม่มีบาร์โค้ด",
                  activeColor: activeColor,
                ),
              ),
              Expanded(
                child: _buildTabButton(
                  controller,
                  index: 1,
                  label: "มีบาร์โค้ด",
                  activeColor: activeColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(
    ManualListController controller, {
    required int index,
    required String label,
    required Color activeColor,
  }) {
    final selected = controller.activeTab.value == index;
    return GestureDetector(
      onTap: () => controller.activeTab.value = index,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? activeColor : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
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
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
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
              borderRadius: BorderRadius.circular(9),
              child: Image.network(
                product.imagePath,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  width: 44,
                  height: 44,
                  child: const Icon(Icons.image_outlined, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "${product.price.toStringAsFixed(0)} บาท",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  if (product.barcode != null && product.barcode!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      "บาร์โค้ด: ${product.barcode}",
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Obx(() {
              final isSelected = controller.selectedIds.contains(product.id);
              return Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? activeColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? activeColor : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter(ManualListController controller) {
    return Column(
      children: [
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
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Obx(
              () => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.selectedCategory.value,
                    items: controller.categories
                        .map(
                          (val) =>
                              DropdownMenuItem(value: val, child: Text(val)),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) controller.selectedCategory.value = val;
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
