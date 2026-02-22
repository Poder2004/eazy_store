import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ✅ Import Controller ตัวที่เพิ่งแยกออกไป
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
          _buildSearchAndFilter(controller),
          const SizedBox(height: 10),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.filteredProducts.isEmpty) {
                return const Center(child: Text("ไม่พบรายการสินค้า"));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: controller.filteredProducts.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(
                    controller.filteredProducts[index],
                    activeBlue,
                    controller,
                  );
                },
              );
            }),
          ),
          _buildCheckoutButton(controller),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    ProductItem product,
    Color activeColor,
    ManualListController controller,
  ) {
    return GestureDetector(
      onTap: () => controller.toggleSelection(product),
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
                product.imgProduct,
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
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${product.sellPrice.toStringAsFixed(0)} บาท",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
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
                    onChanged: (val) =>
                        controller.selectedCategory.value = val!,
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
          label: const Text(
            "เพิ่มลงรายการขาย",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}