// ไฟล์: lib/page/product/product_detail_screen.dart
import 'package:eazy_store/model/response/product_response.dart';
import 'package:eazy_store/page/product/edit_product/edit_product_screen.dart'; // ตรวจสอบ Path ด้วยนะครับ
import 'package:eazy_store/utils/stock_format.dart';
import 'package:eazy_store/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'product_detail_controller.dart'; // ✅ Import Controller

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProductDetailController controller = Get.put(
      ProductDetailController(),
    );
    const Color primaryColor = Color(0xFF6B8E23);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: RefreshIndicator(
        onRefresh: controller.refreshProduct,
        color: primaryColor,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: primaryColor,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black26,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: Colors.white,
                  child: Hero(
                    tag: 'product-${controller.product.value.productId}',
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Obx(
                        () => Image.network(
                          controller.product.value.imgProduct,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 100,
                                  color: Colors.grey,
                                ),
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // --- ส่วนเนื้อหารายละเอียด ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              controller.product.value.name,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _statusBadge(controller.product.value.status),
                        ],
                      ),
                      Text(
                        "รหัสสินค้า: ${controller.product.value.productCode ?? '-'}",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const Divider(height: 40),

                      // ข้อมูลราคาและสต็อก
                      _buildInfoGrid(controller.product.value, primaryColor),

                      const SizedBox(height: 30),

                      // ข้อมูลเชิงลึกอื่นๆ
                      _buildDetailRow(
                        Icons.barcode_reader,
                        "บาร์โค้ด",
                        controller.product.value.barcode ?? "ไม่มีข้อมูล",
                      ),
                      _buildDetailRow(
                        Icons.category_outlined,
                        "หมวดหมู่",
                        controller.product.value.category?.name ?? "ทั่วไป",
                      ),
                      _buildDetailRow(
                        Icons.scale_outlined,
                        "หน่วยนับ",
                        controller.product.value.unit,
                      ),

                      if (controller.product.value.activeUnits.isNotEmpty) ...[
                        const Divider(height: 30),
                        const Text(
                          "หน่วยขายเพิ่มเติม",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final u in controller.product.value.activeUnits)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  color: Colors.grey[400],
                                  size: 20,
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Text(
                                    "${u.unitName} = ${u.conversionQty} ${controller.product.value.unit}",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "ขาย ฿${u.sellPrice.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      "ทุน ฿${u.costPrice.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],

                      const SizedBox(height: 100), // เว้นที่ให้ปุ่มด้านล่าง
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // --- ปุ่มจัดการ (แก้ไข/ลบ) ---
      bottomSheet: _buildActionButtons(controller),
    );
  }

  // Widget แสดงสถานะ เปิด-ปิด
  Widget _statusBadge(bool status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: status
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status ? Colors.green : Colors.red),
      ),
      child: Text(
        status ? "กำลังขาย" : "ถูกซ่อน", // เปลี่ยนข้อความให้สื่อความหมายมากขึ้น
        style: TextStyle(
          color: status ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Widget แสดงราคาและสต็อกแบบช่องตาราง
  Widget _buildInfoGrid(ProductResponse product, Color color) {
    final hasUnits = product.activeUnits.isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoItem(
          "ราคาขาย/${product.unit}",
          "฿${product.sellPrice.toStringAsFixed(2)}",
          color,
        ),
        _infoItem(
          "ต้นทุน/${product.unit}",
          "฿${product.costPrice.toStringAsFixed(2)}",
          Colors.blueGrey,
        ),
        _infoItem(
          "คงเหลือ",
          formatStockBreakdown(product.stock, product.unit, product.units),
          Colors.orange,
          // สต็อกถูกย่อเป็นหน่วยใหญ่ (เช่น ซอง) บอกยอดรวมเป็นหน่วยฐานด้วย กันสับสนกับราคาที่เป็นต่อหน่วยฐาน
          subtitle: hasUnits ? "รวม ${product.stock} ${product.unit}" : null,
        ),
      ],
    );
  }

  Widget _infoItem(
    String label,
    String value,
    Color color, {
    String? subtitle,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 5),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 24),
          const SizedBox(width: 15),
          Text(
            title,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ส่วนของปุ่ม แก้ไข และ ลบ ด้านล่าง
  Widget _buildActionButtons(ProductDetailController controller) {
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
      // เว้นระยะจากแถบนำทางของระบบ กันปุ่มโดนปุ่ม ☰ ○ ◁ ทับ
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // ปุ่มลบ
            // ✨ ใส่กรอบ+พื้นหลังให้ดูเป็นปุ่มชัดเจน ไม่ใช่แค่ไอคอนลอยๆ (เข้าใจง่ายขึ้นว่ากดได้)
            Material(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _confirmDelete(controller),
                child: Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.4)),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 26,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // ปุ่มแก้ไข
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  var result = await Get.to(
                    () => const EditProductScreen(),
                    arguments: controller.product.value,
                    transition: Transition.rightToLeft,
                  );

                  if (result != null && result is ProductResponse) {
                    controller.product.value = result;
                  }
                  // ดึงข้อมูลล่าสุดซ้ำเสมอตอนกลับมาหน้านี้ ไม่ใช่แค่ตอนมี result
                  // ส่งกลับมาตรงๆ เพราะถ้าเข้าไปเพิ่มสต็อกต่อจากหน้าแก้ไข (Edit ->
                  // Add Stock) แล้วกดย้อนกลับโดยไม่ได้กด "บันทึก" ในหน้าแก้ไขอีกที
                  // result ตรงนี้จะเป็น null แต่สต็อกจริงถูกอัปเดตในเซิร์ฟเวอร์ไปแล้ว
                  await controller.refreshProduct();
                },
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text(
                  "แก้ไขข้อมูลสินค้า",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B8E23),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(ProductDetailController controller) {
    ConfirmDialog.show(
      title: "ยืนยันการลบ?",
      message:
          "คุณต้องการลบสินค้า\n'${controller.product.value.name}'\nออกจากร้านใช่หรือไม่?",
      confirmLabel: "ยืนยันลบ",
      closeOnConfirm: false, // deleteProduct() ปิด dialog เองแล้ว
      onConfirm: () => controller.deleteProduct(),
    );
  }
}
