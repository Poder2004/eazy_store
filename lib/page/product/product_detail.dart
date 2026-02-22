import 'package:eazy_store/model/request/product_model.dart';
import 'package:eazy_store/page/product/edit_product_screen.dart';
// ⚠️ อย่าลืม Import หน้าแก้ไขสินค้าที่คุณสร้างไว้
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ----------------------------------------------------------------------
// 1. Controller: สำหรับจัดการสถานะในหน้ารายละเอียด
// ----------------------------------------------------------------------
class ProductDetailController extends GetxController {
  late Rx<Product> product;
  var isStatusLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // รับค่า Product มาจาก arguments
    if (Get.arguments != null && Get.arguments is Product) {
      product = (Get.arguments as Product).obs;
    } else {
      // กรณีไม่มีข้อมูลส่งมา ให้เด้งกลับเพื่อป้องกัน Error
      Get.back();
      Get.snackbar("Error", "ไม่พบข้อมูลสินค้า");
    }
  }

  // ฟังก์ชันลบสินค้า (จำลอง)
  Future<void> deleteProduct() async {
    // TODO: เรียก API ลบสินค้าจริงๆ
    Get.back(); // ปิด Dialog ยืนยัน
    Get.back(); // กลับไปหน้ารายการสินค้า
    Get.snackbar(
      "สำเร็จ",
      "ลบสินค้าเรียบร้อยแล้ว",
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  // ฟังก์ชันเปิด-ปิดสถานะสินค้า
  // void toggleStatus(bool value) {
  //   // ในอนาคตต้องยิง API อัปเดต status ตรงนี้
  //   product.update((val) {
  //     val?.status = value; // ตัวอย่างการอัปเดตค่าใน Rx
  //     // หมายเหตุ: ในฐานข้อมูลจริงต้องยิง API อัปเดตด้วย
  //   });
  // }
}

// ----------------------------------------------------------------------
// 2. View: หน้าจอแสดงรายละเอียด
// ----------------------------------------------------------------------
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
          // --- ส่วนหัว: รูปภาพสินค้าแบบขยายได้ (SliverAppBar) ---
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: primaryColor,
            leading: CircleAvatar(
              backgroundColor: Colors.black26,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Get.back(),
              ),
            ),
            // ... ภายใน SliverAppBar ...
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors
                    .white, // ✨ ใส่พื้นหลังสีขาว เพื่อให้ดูเหมือนถ่ายในสตูดิโอ
                child: Hero(
                  tag: 'product-${controller.product.value.productId}',
                  child: Padding(
                    padding: const EdgeInsets.all(
                      20.0,
                    ), // ✨ เว้นช่องไฟรอบรูป ไม่ให้ชิดขอบเกินไป
                    child: Obx(
                      () => Image.network(
                        // ✨ ใช้ Obx เผื่อรูปเปลี่ยน
                        controller.product.value.imgProduct,
                        // ✨ เปลี่ยนจาก cover เป็น contain เพื่อให้เห็น "ครบทุกส่วน" ของสินค้า
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
                  // ✨ ครอบ Obx เพื่อให้อัปเดตข้อมูลอัตโนมัติเมื่อกลับจากหน้าแก้ไข
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ชื่อสินค้าและรหัส
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

                    // ข้อมูลราคาและสต็อก (แสดงเป็น Grid ย่อยๆ)
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
                      // ✨ เรียกใช้ชื่อหมวดหมู่ ถ้าไม่มีให้แสดง 'ทั่วไป'
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
        status ? "กำลังขาย" : "ปิดใช้งาน",
        style: TextStyle(
          color: status ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Widget แสดงราคาและสต็อกแบบช่องตาราง
  Widget _buildInfoGrid(Product product, Color color) {
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
                // 1. นำทางไปหน้าแก้ไข และ "รอ" (await) ผลลัพธ์ที่ส่งกลับมา
                var result = await Get.to(
                  () => const EditProductScreen(),
                  arguments: controller.product.value,
                  transition: Transition.rightToLeft, // Animation สไลด์มา
                );

                // 2. ถ้ามีข้อมูลส่งกลับมา (แปลว่าแก้ไขสำเร็จ)
                if (result != null && result is Product) {
                  // ✅ อัปเดตค่า product ใน Controller ทันที
                  // หน้าจอจะเปลี่ยนเลขราคา/ชื่อสินค้า อัตโนมัติ เพราะเราใช้ Obx อยู่
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

  void _confirmDelete(ProductDetailController controller) {
    Get.defaultDialog(
      title: "ยืนยันการลบ",
      middleText:
          "คุณต้องการลบสินค้า '${controller.product.value.name}' ออกจากร้านใช่หรือไม่?",
      textCancel: "ยกเลิก",
      textConfirm: "ยืนยันลบ",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () => controller.deleteProduct(),
    );
  }
}
