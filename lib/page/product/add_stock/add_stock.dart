import 'package:eazy_store/page/menu_bar/bottom_navbar.dart';
import 'package:eazy_store/page/sale_producct/scanBarcode/scan_barcode.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// ✅ นำเข้า Controller ที่แยกไว้
import 'add_stock_controller.dart';

// 🎨 Theme Colors
const Color _kPrimaryColor = Color(0xFF6B8E23);
const Color _kBackgroundColor = Color(0xFFF7F7F7);
const Color _kInputFillColor = Color(0xFFF0F0E0);
const Color _kReadOnlyColor = Color(0xFFEEEEEE);

class AddStockScreen extends StatelessWidget {
  const AddStockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ เรียกใช้ Controller
    final AddStockController controller = Get.put(AddStockController());

    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        title: Text(
          'รับสินค้าเข้า',
          style: GoogleFonts.prompt(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: _kBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: controller.handleClear,
            icon: const Icon(
              Icons.cleaning_services_outlined,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🔎 ช่องค้นหา + ปุ่มสแกน
            _buildSearchSection(controller),

            const SizedBox(height: 20),

            // 📦 แสดงรายละเอียดสินค้า (ใช้ Obx ครอบเพราะ UI เปลี่ยนตาม State)
            Obx(() {
              if (controller.foundProduct.value != null) {
                return Column(
                  children: [
                    _buildProductCard(controller),
                    const SizedBox(height: 20),
                    _buildStockInputSection(controller),
                    const SizedBox(height: 30),
                    _buildActionButtons(controller),
                  ],
                );
              } else if (controller.isSearching.value) {
                return const Padding(
                  padding: EdgeInsets.only(top: 50),
                  child: CircularProgressIndicator(color: _kPrimaryColor),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "ค้นหาสินค้าเพื่อเพิ่มสต็อก",
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                      ),
                    ],
                  ),
                );
              }
            }),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () => BottomNavBar(
          currentIndex: controller.selectedIndex.value,
          onTap: (i) => controller.selectedIndex.value = i,
        ),
      ),
    );
  }

  // --- Widgets ---

  Widget _buildSearchSection(AddStockController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller.searchController,
        decoration: InputDecoration(
          hintText: 'ชื่อสินค้า หรือ รหัสบาร์โค้ด',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: _kPrimaryColor),
            onPressed: () async {
              var result = await Get.to(() => const ScanBarcodePage());
              if (result != null && result is String) {
                controller.searchController.text = result;
                controller.handleSearch();
              }
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onSubmitted: (_) => controller.handleSearch(),
      ),
    );
  }

  Widget _buildProductCard(AddStockController controller) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 40),
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Column(
            children: [
              Text(
                controller.nameController.text,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                "รหัส: ${controller.foundProduct.value?.productCode ?? '-'}",
                style: const TextStyle(color: Colors.grey),
              ),
              const Divider(height: 30),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      "หมวดหมู่",
                      controller.categoryController.text,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      "ราคาขาย",
                      "฿${controller.salePriceController.text}",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      "ต้นทุน",
                      "฿${controller.costController.text}",
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      "คงเหลือ",
                      "${controller.currentStockController.text} ${controller.unitController.text}",
                      isHighlight: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
            ],
            image: DecorationImage(
              image: NetworkImage(
                controller.foundProduct.value?.imgProduct ?? '',
              ),
              fit: BoxFit.cover,
              onError: (e, s) {},
            ),
          ),
          child:
              controller.foundProduct.value?.imgProduct == null ||
                  controller.foundProduct.value!.imgProduct.isEmpty
              ? const Icon(Icons.image_not_supported, color: Colors.grey)
              : null,
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isHighlight ? _kPrimaryColor : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStockInputSection(AddStockController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kPrimaryColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.add_circle_outline, color: _kPrimaryColor),
              SizedBox(width: 10),
              Text(
                "เพิ่มจำนวนสต็อก",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),
          TextField(
            controller: controller.addAmountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _kPrimaryColor,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: Colors.grey[300]),
              filled: true,
              fillColor: _kInputFillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Obx(
              () => Text(
                "ยอดรวมใหม่: ${controller.calculatedTotal.value} ${controller.unitController.text}",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🛡️ ปรับ Popup มาไว้ใน View
  void _showSaveCheckDialog(AddStockController controller) {
    if (controller.foundProduct.value == null) return;

    int amount = int.tryParse(controller.addAmountController.text) ?? 0;
    if (amount <= 0) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณาระบุจำนวนที่ต้องการเพิ่ม",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.playlist_add_check_circle,
                size: 60,
                color: _kPrimaryColor,
              ),
              const SizedBox(height: 15),
              const Text(
                "ยืนยันเพิ่มสต็อก",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 30),
              _buildConfirmRow("สินค้า", controller.nameController.text),
              _buildConfirmRow(
                "คงเหลือเดิม",
                "${controller.currentStockController.text} ${controller.unitController.text}",
              ),
              _buildConfirmRow(
                "เพิ่มจำนวน",
                "+$amount ${controller.unitController.text}",
                valueColor: Colors.green,
              ),
              const Divider(),
              _buildConfirmRow(
                "รวมสุทธิ",
                "${controller.calculatedTotal.value} ${controller.unitController.text}",
                isBold: true,
              ),
              const SizedBox(height: 30),
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
                        "แก้ไข",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back(); // ปิด Popup
                        controller.executeSave(amount); // ยิง API
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "ยืนยัน",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
      barrierDismissible: false,
    );
  }

  Widget _buildConfirmRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.black87,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AddStockController controller) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: () => _showSaveCheckDialog(controller),
        icon: const Icon(Icons.save, color: Colors.white),
        label: const Text(
          "บันทึกสต็อก",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
        ),
      ),
    );
  }
}
