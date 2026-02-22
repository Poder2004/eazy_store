// ไฟล์: lib/page/product/product_detail_screen.dart
import 'package:eazy_store/model/response/product_response.dart';
import 'package:eazy_store/page/product/edit_product/edit_product_screen.dart'; // ตรวจสอบ Path ด้วยนะครับ
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
      body: CustomScrollView(
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
                        errorBuilder: (context, error, stackTrace) => Container(
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
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
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

                    const SizedBox(height: 100), // เว้นที่ให้ปุ่มด้านล่าง
                  ],
                ),
              ),
            ),
          ),
        ],
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
    return Row(
      children: [
        _infoItem("ราคาขาย", "฿${product.sellPrice.toStringAsFixed(2)}", color),
        _infoItem(
          "ต้นทุน",
          "฿${product.costPrice.toStringAsFixed(2)}",
          Colors.blueGrey,
        ),
        _infoItem("คงเหลือ", "${product.stock} ${product.unit}", Colors.orange),
      ],
    );
  }

  Widget _infoItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
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
      child: Row(
        children: [
          // ปุ่มลบ
          IconButton(
            onPressed: () => _confirmDelete(controller),
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 30),
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
    );
  }

  // 🛡️ ปรับ Popup ยืนยันการลบให้สวยขึ้น
  void _confirmDelete(ProductDetailController controller) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 50,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "ยืนยันการลบ?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "คุณต้องการลบสินค้า\n'${controller.product.value.name}'\nออกจากร้านใช่หรือไม่?",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "ยกเลิก",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          controller.deleteProduct(), // เรียกฟังก์ชันลบ
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "ยืนยันลบ",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
