import 'package:eazy_store/model/response/product_response.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eazy_store/utils/stock_format.dart';
import 'product_summary_controller.dart';

class ProductSummaryPage extends StatefulWidget {
  const ProductSummaryPage({super.key});

  @override
  State<ProductSummaryPage> createState() => _ProductSummaryPageState();
}

class _ProductSummaryPageState extends State<ProductSummaryPage> {
  late final ProductSummaryController controller;

  @override
  void initState() {
    super.initState();
    Get.delete<ProductSummaryController>(force: true);
    controller = Get.put(ProductSummaryController());
  }

  @override
  void dispose() {
    Get.delete<ProductSummaryController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'สรุปสินค้า',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.products.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6B8E23)),
          );
        }

        if (controller.errorMessage.value != null &&
            controller.products.isEmpty) {
          return _buildErrorState(controller.errorMessage.value!);
        }

        return RefreshIndicator(
          onRefresh: controller.loadSummary,
          color: const Color(0xFF6B8E23),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildCountCard(
                      label: 'สินค้าทั้งหมด',
                      count: controller.totalProducts,
                      icon: Icons.inventory_2_outlined,
                      color: const Color(0xFF2563EB),
                      onTap: () => _showProducts(
                        'สินค้าทั้งหมด',
                        controller.products.toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCountCard(
                      label: 'สินค้าใกล้หมด',
                      count: controller.lowStockCount,
                      icon: Icons.warning_amber_rounded,
                      color: const Color(0xFFF59E0B),
                      onTap: () => _showProducts(
                        'สินค้าใกล้หมด',
                        controller.lowStockProducts,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCountCard(
                      label: 'สินค้าหมด',
                      count: controller.outOfStockCount,
                      icon: Icons.remove_shopping_cart_outlined,
                      color: const Color(0xFFEF4444),
                      onTap: () => _showProducts(
                        'สินค้าหมด',
                        controller.outOfStockProducts,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionCard(
                title: 'จำนวนสินค้าแต่ละหมวดหมู่',
                icon: Icons.category_outlined,
                child: controller.categoryCounts.isEmpty
                    ? _buildEmptyText('ยังไม่มีข้อมูลหมวดหมู่')
                    : Column(
                        children: [
                          for (
                            var index = 0;
                            index < controller.categoryCounts.length;
                            index++
                          ) ...[
                            if (index > 0) const Divider(height: 20),
                            _buildCategoryRow(
                              controller.categoryCounts[index],
                              controller.totalProducts,
                              onTap: () {
                                final category =
                                    controller.categoryCounts[index].key;
                                _showProducts(
                                  'หมวดหมู่$category',
                                  controller.productsInCategory(category),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'สินค้าที่มีสต็อกมาก',
                subtitle: 'แสดง 5 รายการที่มีจำนวนคงเหลือสูงสุด',
                icon: Icons.trending_up_rounded,
                child: controller.highestStockProducts.isEmpty
                    ? _buildEmptyText('ไม่มีสินค้าในสต็อก')
                    : Column(
                        children: [
                          for (
                            var index = 0;
                            index < controller.highestStockProducts.length;
                            index++
                          ) ...[
                            if (index > 0) const Divider(height: 20),
                            _buildStockRow(
                              controller.highestStockProducts[index],
                              index + 1,
                              onTap: () => _showProducts(
                                'สินค้าที่มีสต็อกมาก',
                                controller.highestStockProducts,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
              if (controller.isLoading.value) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(color: Color(0xFF6B8E23)),
              ],
              if (controller.errorMessage.value != null) ...[
                const SizedBox(height: 12),
                Text(
                  controller.errorMessage.value!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: controller.loadSummary,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองอีกครั้ง'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountCard({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 116),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 8),
              Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF6B8E23), size: 21),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
    MapEntry<String, int> category,
    int total, {
    required VoidCallback onTap,
  }) {
    final progress = total == 0 ? 0.0 : category.value / total;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      category.key,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${category.value} รายการ',
                    style: const TextStyle(
                      color: Color(0xFF6B8E23),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: const Color(0xFFF1F5F9),
                  color: const Color(0xFF84A83B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockRow(
    ProductResponse product,
    int rank, {
    required VoidCallback onTap,
  }) {
    final stockBreakdown = formatStockBreakdown(
      product.stock,
      product.unit,
      product.units,
    );
    final category = product.categoryName?.trim();
    final categoryLabel = category == null || category.isEmpty
        ? 'ไม่ระบุหมวดหมู่'
        : category;
    final baseUnit = product.unit.isEmpty ? '' : ' ${product.unit}';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B8E23).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: Color(0xFF6B8E23),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: _buildProductImage(product, width: 54, height: 54),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$categoryLabel · รวม ${product.stock}$baseUnit',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                stockBreakdown,
                style: const TextStyle(
                  color: Color(0xFF6B8E23),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.end,
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProducts(String title, List<ProductResponse> products) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.4,
        maxChildSize: 0.97,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${products.length} รายการ',
                        style: const TextStyle(
                          color: Color(0xFF6B8E23),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: products.isEmpty
                      ? Center(
                          child: Text(
                            'ไม่มีสินค้าในรายการนี้',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: products.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) =>
                              _buildProductListTile(products[index]),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductListTile(ProductResponse product) {
    final stockBreakdown = formatStockBreakdown(
      product.stock,
      product.unit,
      product.units,
    );
    final stockColor = product.stock <= 0
        ? const Color(0xFFEF4444)
        : product.stock <= product.lowStockThreshold
        ? const Color(0xFFF59E0B)
        : const Color(0xFF6B8E23);
    final category = product.categoryName?.trim();

    return Container(
      constraints: const BoxConstraints(minHeight: 104),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildProductImage(product, width: 76, height: 76),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category == null || category.isEmpty
                      ? 'ไม่ระบุหมวดหมู่'
                      : category,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  'คงเหลือรวม ${product.stock} ${product.unit}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                stockBreakdown,
                style: TextStyle(
                  color: stockColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.end,
              ),
              Text(
                product.stock <= 0
                    ? 'หมด'
                    : product.stock <= product.lowStockThreshold
                    ? 'ใกล้หมด'
                    : 'คงเหลือ',
                style: TextStyle(fontSize: 11, color: stockColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(
    ProductResponse product, {
    required double width,
    required double height,
  }) {
    final imageUrl = product.imgProduct.trim();
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF1F5F9),
      child: imageUrl.isEmpty
          ? const Icon(Icons.inventory_2_outlined, color: Colors.grey)
          : Image.network(
              imageUrl,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.image_not_supported_outlined,
                color: Colors.grey,
              ),
            ),
    );
  }

  Widget _buildEmptyText(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(message, style: TextStyle(color: Colors.grey.shade600)),
      ),
    );
  }
}
