import 'package:dotted_border/dotted_border.dart';
import 'package:eazy_store/page/menu_bar/bottom_navbar.dart';
import 'package:eazy_store/model/request/category_model.dart';
import 'package:eazy_store/page/sale_producct/scanBarcode/scan_barcode.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_product_controller.dart'; // ✅ นำเข้า Controller ที่แยกไว้

// 🎨 Theme Constants
const Color _kPrimaryColor = Color(0xFF6B8E23);
const Color _kBackgroundColor = Color(0xFFF2F4F7);
const Color _kCardColor = Colors.white;
const Color _kInputFillColor = Color(0xFFF9FAFB);

class AddProductScreen extends StatelessWidget {
  const AddProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ เรียกใช้ Controller
    final AddProductController controller = Get.put(AddProductController());

    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        title: Text(
          'เพิ่มสินค้า',
          style: GoogleFonts.prompt(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: _kBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 📸 ส่วนที่ 1: รูปภาพ
            _buildSectionCard(
              child: Center(
                child: Column(
                  children: [
                    _buildImagePicker(controller),
                    const SizedBox(height: 10),
                    Text(
                      "แตะเพื่ออัปโหลดรูปภาพ",
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 📝 ส่วนที่ 2: ข้อมูลพื้นฐาน
            _buildSectionCard(
              title: "ข้อมูลทั่วไป",
              child: Column(
                children: [
                  _buildModernField(
                    label: "ชื่อสินค้า",
                    textController: controller.nameController,
                    hintText: "เช่น น้ำดื่มตราสิงห์ 600ml",
                    icon: Icons.shopping_bag_outlined,
                  ),
                  const SizedBox(height: 15),
                  _buildCategoryDropdown(controller),
                  const SizedBox(height: 15),
                  _buildBarcodeField(controller),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 💰 ส่วนที่ 3: ราคาและสต็อก
            _buildSectionCard(
              title: "ราคาและคลังสินค้า",
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernField(
                          label: "ต้นทุน",
                          textController: controller.costController,
                          hintText: "0.00",
                          isNumber: true,
                          icon: Icons.monetization_on_outlined,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildModernField(
                          label: "ราคาขาย",
                          textController: controller.salePriceController,
                          hintText: "0.00",
                          isNumber: true,
                          icon: Icons.sell_outlined,
                          isHighlight: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernField(
                          label: "จำนวน",
                          textController: controller.stockController,
                          hintText: "0",
                          isNumber: true,
                          icon: Icons.inventory_2_outlined,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(child: _buildUnitHybridField(controller)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // 🔘 ปุ่มกด
            _buildAddProductButton(controller),
            const SizedBox(height: 15),
            _buildResetText(controller),
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: -1, // ใส่ -1 จะไม่มีปุ่มไหนถูกเลือก (ไม่มีสีแดงโชว์)
        onTap: (index) {
          // ใส่ Logic การเปลี่ยนหน้าตามปกติของคุณ
          print("Tab tapped: $index");
        },
      ),
    );
  }

  // ==================== Widget Helpers ====================

  Widget _buildSectionCard({required Widget child, String? title}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Divider(height: 25),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildImagePicker(AddProductController controller) {
    return GestureDetector(
      onTap: controller.showImagePickerOptions,
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(20),
        padding: const EdgeInsets.all(4),
        color: _kPrimaryColor.withOpacity(0.5),
        strokeWidth: 2,
        dashPattern: const [8, 4],
        child: Obx(
          () => Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: _kInputFillColor,
              borderRadius: BorderRadius.circular(16),
              image: controller.imageFile.value != null
                  ? DecorationImage(
                      image: FileImage(controller.imageFile.value!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: controller.imageFile.value == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_rounded,
                        size: 40,
                        color: _kPrimaryColor,
                      ),
                    ],
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildModernField({
    required String label,
    required TextEditingController textController,
    required String hintText,
    bool isNumber = false,
    IconData? icon,
    bool isHighlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _kInputFillColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHighlight
                  ? _kPrimaryColor.withOpacity(0.5)
                  : Colors.transparent,
            ),
          ),
          child: TextField(
            controller: textController,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: icon != null
                  ? Icon(
                      icon,
                      color: isHighlight ? _kPrimaryColor : Colors.grey[400],
                      size: 20,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(AddProductController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "หมวดหมู่",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _kInputFillColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: Obx(
              () => DropdownButton<CategoryModel>(
                isExpanded: true,
                value: controller.selectedCategoryObject.value,
                hint: Text(
                  "เลือกหมวดหมู่",
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                items: controller.categoryList
                    .map(
                      (cat) =>
                          DropdownMenuItem(value: cat, child: Text(cat.name)),
                    )
                    .toList(),
                onChanged: (val) {
                  controller.selectedCategoryObject.value = val;
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitHybridField(AddProductController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "หน่วยนับ",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _kInputFillColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller.unitController,
            decoration: InputDecoration(
              hintText: "เช่น ชิ้น",
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: Icon(Icons.scale, color: Colors.grey[400], size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: PopupMenuButton<String>(
                icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                onSelected: (val) {
                  controller.unitController.text = val;
                },
                itemBuilder: (ctx) => controller.unitOptions
                    .map((e) => PopupMenuItem(value: e, child: Text(e)))
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarcodeField(AddProductController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "บาร์โค้ด",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _kInputFillColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: controller.idController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "พิมพ์หรือสแกน",
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: Icon(
                      Icons.qr_code,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () async {
                var result = await Get.to(() => const ScanBarcodePage());
                if (result != null && result is String) {
                  controller.idController.text = result;
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kPrimaryColor),
                ),
                child: const Icon(Icons.qr_code_scanner, color: _kPrimaryColor),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddProductButton(AddProductController controller) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: Obx(
        () => ElevatedButton(
          onPressed: controller.isSaving.value
              ? null
              : controller.handleSaveProduct,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 5,
            shadowColor: _kPrimaryColor.withOpacity(0.4),
          ),
          child: controller.isSaving.value
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  "บันทึกสินค้า",
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

  Widget _buildResetText(AddProductController controller) => Center(
    child: TextButton.icon(
      onPressed: controller.resetForm,
      icon: const Icon(Icons.refresh, size: 18, color: Colors.grey),
      label: const Text('ล้างข้อมูล', style: TextStyle(color: Colors.grey)),
    ),
  );
}
