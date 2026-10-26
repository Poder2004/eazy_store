import 'package:dotted_border/dotted_border.dart';
import 'package:eazy_store/model/request/category_model.dart';
import 'package:eazy_store/page/menu_bar/bottom_navbar.dart';
import 'package:eazy_store/page/sale_producct/scanBarcode/scan_barcode.dart';
import 'package:eazy_store/utils/internal_barcode.dart';
import 'package:eazy_store/widgets/category_bottom_sheet.dart';
import 'package:eazy_store/widgets/category_disable_dialog.dart';
import 'package:eazy_store/widgets/inactive_categories_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
              title: "รูปภาพสินค้า",
              step: 1,
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
              step: 2,
              child: Column(
                children: [
                  _buildModernField(
                    label: "ชื่อสินค้า",
                    textController: controller.nameController,
                    hintText: "เช่น น้ำดื่มตราสิงห์ 600ml",
                    icon: Icons.shopping_bag_outlined,
                  ),
                  const SizedBox(height: 15),
                  _buildCategoryDropdown(context, controller),
                  const SizedBox(height: 15),
                  _buildBarcodeField(controller),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 💰 ส่วนที่ 3: ราคาและสต็อก
            _buildSectionCard(
              title: "ราคาและคลังสินค้า",
              step: 3,
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
                          allowDecimal: true,
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
                          allowDecimal: true,
                          icon: Icons.sell_outlined,
                          isHighlight: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildUnitHybridField(context, controller),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildModernField(
                          label: "จำนวนสต็อก",
                          textController: controller.stockController,
                          hintText: "0",
                          isNumber: true,
                          icon: Icons.inventory_2_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "นับจำนวนเป็นหน่วยเล็กสุดเสมอ (เช่น ขวด) แม้สินค้านี้จะขายได้หลายหน่วยก็ตาม",
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildModernField(
                    label: "แจ้งเตือนเมื่อสต็อกเหลือไม่เกิน",
                    textController: controller.lowStockController,
                    hintText: "10",
                    isNumber: true,
                    icon: Icons.notifications_active_outlined,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "เมื่อคงเหลือ (นับเป็นหน่วยเล็กสุด) เท่ากับหรือน้อยกว่าค่านี้ จะขึ้นว่า \"สินค้าใกล้หมด\"",
                    style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 📦 ส่วนที่ 4: หน่วยขายเพิ่มเติม (ลัง/แพ็ค) — ไม่บังคับ พับเก็บไว้ก่อน
            Container(
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
                  InkWell(
                    onTap: controller.toggleUnitsSection,
                    borderRadius: BorderRadius.circular(10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader("หน่วยขายเพิ่มเติม", 4),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 34),
                                child: Obx(
                                  () => Text(
                                    controller.unitForms.isEmpty
                                        ? "ไม่บังคับ — เช่น ขายทั้งลังและขายแยกขวด (แตะเพื่อเพิ่ม)"
                                        : "ไม่บังคับ · เพิ่มแล้ว ${controller.unitForms.length} หน่วย",
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Obx(
                          () => AnimatedRotation(
                            turns: controller.isUnitsSectionExpanded.value
                                ? 0.5
                                : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Obx(
                    () => AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: !controller.isUnitsSectionExpanded.value
                          ? const SizedBox(width: double.infinity)
                          : Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(height: 1),
                                  const SizedBox(height: 16),
                                  for (
                                    int i = 0;
                                    i < controller.unitForms.length;
                                    i++
                                  ) ...[
                                    if (i > 0) const SizedBox(height: 14),
                                    _buildUnitFormRow(controller, i),
                                  ],
                                  if (controller.unitForms.isNotEmpty)
                                    const SizedBox(height: 14),
                                  OutlinedButton.icon(
                                    onPressed: controller.addUnitForm,
                                    icon: const Icon(
                                      Icons.add,
                                      size: 18,
                                      color: _kPrimaryColor,
                                    ),
                                    label: const Text(
                                      "เพิ่มหน่วยขาย",
                                      style: TextStyle(color: _kPrimaryColor),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: _kPrimaryColor,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
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

  Widget _buildSectionCard({required Widget child, String? title, int? step}) {
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
            _buildSectionHeader(title, step),
            const Divider(height: 25),
          ],
          child,
        ],
      ),
    );
  }

  // หัวข้อ section พร้อมเลขลำดับ ให้เห็นชัดว่าฟอร์มนี้กรอกตามลำดับยังไง
  Widget _buildSectionHeader(String title, int? step) {
    return Row(
      children: [
        if (step != null) ...[
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _kPrimaryColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$step',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
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
    bool allowDecimal = false,
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
            keyboardType: isNumber
                ? TextInputType.numberWithOptions(decimal: allowDecimal)
                : TextInputType.text,
            inputFormatters: isNumber
                ? [
                    FilteringTextInputFormatter.allow(
                      allowDecimal
                          ? RegExp(r'^\d*\.?\d{0,2}')
                          : RegExp(r'^\d*'),
                    ),
                  ]
                : null,
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

  Widget _buildCategoryDropdown(
    BuildContext context,
    AddProductController controller,
  ) {
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
        GestureDetector(
          onTap: () {
            _showCategoryBottomSheet(context, controller);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _kInputFillColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() {
                  final selected = controller.selectedCategoryObject.value;
                  return Text(
                    selected != null ? selected.name : "เลือกหมวดหมู่",
                    style: TextStyle(
                      color: selected != null
                          ? Colors.black87
                          : Colors.grey[400],
                      fontSize: 14,
                    ),
                  );
                }),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCategoryBottomSheet(
    BuildContext context,
    AddProductController controller,
  ) {
    CategoryBottomSheet.show(
      context: context,
      categories: controller.categoryList,
      selectedCategory: controller.selectedCategoryObject,
      onCategorySelected: (cat) {
        controller.selectedCategoryObject.value = cat;
      },
      onAddCategory: () {
        _showAddCategoryDialog(context, controller);
      },
      onEditCategory: (cat) {
        _showEditCategoryDialog(context, controller, cat);
      },
      onDisableCategory: (cat) {
        _showDisableCategoryDialog(context, controller, cat);
      },
      onManageInactiveCategories: () {
        InactiveCategoriesSheet.show(
          context: context,
          onCategoriesChanged: controller.fetchCategories,
        );
      },
    );
  }

  Future<void> _showDisableCategoryDialog(
    BuildContext context,
    AddProductController controller,
    CategoryModel category,
  ) async {
    final productCount = await controller.getCategoryProductCount(
      category.categoryId,
    );
    if (!context.mounted) return;

    await CategoryDisableDialog.show(
      context: context,
      category: category,
      productCount: productCount,
      onDisable: () => controller.disableCategory(category),
      onRefreshCategories: (CategoryModel? movedToCategory) async {
        await controller.fetchCategories();
        // เปลี่ยน/ล้างหมวดหมู่ที่เลือกในฟอร์ม เฉพาะตอนหมวดหมู่ที่กำลังปิดใช้งาน
        // เป็นหมวดหมู่เดียวกับที่เลือกอยู่ในฟอร์มนี้เท่านั้น ไม่งั้นปิดหมวดหมู่อื่น
        // ที่ไม่เกี่ยวข้องก็จะไปรีเซ็ตหมวดหมู่ที่เลือกไว้ในฟอร์มด้วย
        if (controller.selectedCategoryObject.value?.categoryId ==
            category.categoryId) {
          controller.selectedCategoryObject.value = movedToCategory;
        }
      },
      onReopenBottomSheet: () {
        if (context.mounted) {
          _showCategoryBottomSheet(context, controller);
        }
      },
    );
  }

  void _showAddCategoryDialog(
    BuildContext context,
    AddProductController controller,
  ) {
    final nameCtrl = TextEditingController();

    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: _kPrimaryColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 42,
                  color: _kPrimaryColor,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "เพิ่มหมวดหมู่ใหม่",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  hintText: "ชื่อหมวดหมู่",
                  filled: true,
                  fillColor: const Color(0xFFF7F8FA),
                  prefixIcon: const Icon(
                    Icons.category_outlined,
                    color: _kPrimaryColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: _kPrimaryColor,
                      width: 1.4,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.of(context, rootNavigator: true).pop(),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("ยกเลิก"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.isEmpty) {
                          Get.snackbar("แจ้งเตือน", "กรุณากรอกชื่อหมวดหมู่");
                          return;
                        }
                        // เรียก API เพิ่มหมวดหมู่
                        final ok = await controller.addNewCategory(
                          nameCtrl.text,
                        );
                        if (ok) {
                          Navigator.of(context, rootNavigator: true).pop();
                          await Future.delayed(
                            const Duration(milliseconds: 180),
                          );
                          if (context.mounted) {
                            _showCategoryBottomSheet(context, controller);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "เพิ่ม",
                        style: TextStyle(color: Colors.white),
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

  void _showEditCategoryDialog(
    BuildContext context,
    AddProductController controller,
    CategoryModel category,
  ) {
    final nameCtrl = TextEditingController(text: category.name);

    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: _kPrimaryColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  size: 36,
                  color: _kPrimaryColor,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "แก้ไขหมวดหมู่",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  hintText: "ชื่อหมวดหมู่",
                  filled: true,
                  fillColor: const Color(0xFFF7F8FA),
                  prefixIcon: const Icon(
                    Icons.category_outlined,
                    color: _kPrimaryColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: _kPrimaryColor,
                      width: 1.4,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.of(context, rootNavigator: true).pop(),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("ยกเลิก"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.isEmpty) {
                          Get.snackbar("แจ้งเตือน", "กรุณากรอกชื่อหมวดหมู่");
                          return;
                        }
                        // เรียก API แก้ไขหมวดหมู่
                        final ok = await controller.editCategory(
                          category.categoryId,
                          nameCtrl.text,
                        );
                        if (ok) {
                          Navigator.of(context, rootNavigator: true).pop();
                          await Future.delayed(
                            const Duration(milliseconds: 180),
                          );
                          if (context.mounted) {
                            _showCategoryBottomSheet(context, controller);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "บันทึก",
                        style: TextStyle(color: Colors.white),
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

  Widget _buildUnitHybridField(
    BuildContext context,
    AddProductController controller,
  ) {
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
              suffixIcon: GestureDetector(
                onTap: () => _showUnitBottomSheet(
                  context,
                  textCtrl: controller.unitController,
                  options: controller.unitOptions,
                  title: "เลือกหน่วยนับ",
                ),
                child: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Bottom sheet เลือกชื่อหน่วย ใช้ทั้งหน่วยนับหลักและชื่อหน่วยขายเพิ่มเติม
  // (พิมพ์เองในช่องได้เหมือนเดิม เลือกจากรายการเป็นแค่ทางลัด)
  void _showUnitBottomSheet(
    BuildContext context, {
    required TextEditingController textCtrl,
    required List<String> options,
    required String title,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.prompt(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final unit = options[index];
                    final isSelected = textCtrl.text.trim() == unit;

                    return InkWell(
                      onTap: () {
                        textCtrl.text = unit;
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[100]!),
                          ),
                          color: isSelected
                              ? _kPrimaryColor.withOpacity(0.05)
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              unit,
                              style: GoogleFonts.prompt(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? _kPrimaryColor
                                    : Colors.black87,
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: _kPrimaryColor,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // ช่องกรอกของฟอร์มหน่วยขายเพิ่มเติม — สไตล์เดียวกับ _buildModernField (label ด้านบน
  // พื้นเทาอ่อน มุมโค้ง) แต่รองรับ prefix/suffix เช่น ฿ และชื่อหน่วยฐาน
  Widget _buildUnitInput({
    required String label,
    required TextEditingController ctrl,
    String? hint,
    bool isNumber = false,
    bool allowDecimal = false,
    String? prefixText,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: _kInputFillColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: isNumber
                ? TextInputType.numberWithOptions(decimal: allowDecimal)
                : TextInputType.text,
            inputFormatters: isNumber
                ? [
                    FilteringTextInputFormatter.allow(
                      allowDecimal
                          ? RegExp(r'^\d*\.?\d{0,2}')
                          : RegExp(r'^\d*'),
                    ),
                  ]
                : null,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              // prefixText จะโผล่เฉพาะตอนโฟกัส ใช้ prefixIcon เพื่อให้เห็น ฿ ตลอด
              prefixIcon: prefixText == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(left: 14, right: 4),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          prefixText.trim(),
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
              suffixIcon: suffix == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Center(widthFactor: 1, child: suffix),
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitFormRow(AddProductController controller, int index) {
    final f = controller.unitForms[index];
    String baseUnitLabel() {
      final base = controller.unitController.text.trim();
      return base.isEmpty ? "หน่วยฐาน" : base;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
      decoration: BoxDecoration(
        color: _kCardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // หัวการ์ด: ลำดับ + สรุปสั้นๆ ว่า "1 ลัง = 12 ขวด" อัปเดตตามที่พิมพ์
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "หน่วยที่ ${index + 1}",
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _kPrimaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ListenableBuilder(
                  listenable: Listenable.merge([
                    f.nameCtrl,
                    f.conversionCtrl,
                    controller.unitController,
                  ]),
                  builder: (_, __) {
                    final name = f.nameCtrl.text.trim();
                    final conv = f.conversionCtrl.text.trim();
                    final ready = name.isNotEmpty && conv.isNotEmpty;
                    return Text(
                      ready ? "1 $name = $conv ${baseUnitLabel()}" : "",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    );
                  },
                ),
              ),
              IconButton(
                onPressed: () => controller.removeUnitForm(index),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red[300],
                ),
                tooltip: "ลบหน่วยนี้",
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Builder(
                        builder: (ctx) => _buildUnitInput(
                          label: "ชื่อหน่วย",
                          ctrl: f.nameCtrl,
                          hint: "เช่น ลัง, แพ็ค",
                          suffix: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              FocusScope.of(ctx).unfocus();
                              _showUnitBottomSheet(
                                ctx,
                                textCtrl: f.nameCtrl,
                                // ตัดชื่อที่ซ้ำกับหน่วยฐานออก (ระบบไม่ให้ใช้ชื่อซ้ำ)
                                options: controller.packUnitOptions
                                    .where(
                                      (u) =>
                                          u !=
                                          controller.unitController.text.trim(),
                                    )
                                    .toList(),
                                title: "เลือกชื่อหน่วยขาย",
                              );
                            },
                            child: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildUnitInput(
                        label: "แปลงเป็นหน่วยฐาน",
                        ctrl: f.conversionCtrl,
                        hint: "เช่น 12",
                        isNumber: true,
                        suffix: ListenableBuilder(
                          listenable: controller.unitController,
                          builder: (_, __) => ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 56),
                            child: Text(
                              baseUnitLabel(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _buildUnitInput(
                        label: "บาร์โค้ด (ถ้ามี)",
                        ctrl: f.barcodeCtrl,
                        hint: "พิมพ์หรือสแกน",
                        isNumber: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () async {
                        var result = await Get.to(
                          () => const ScanBarcodePage(),
                        );
                        if (result != null && result is String) {
                          f.barcodeCtrl.text = result;
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _kPrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner,
                          color: _kPrimaryColor,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Tooltip(
                      message: 'สร้างบาร์โค้ดให้อัตโนมัติ',
                      child: InkWell(
                        onTap: () =>
                            f.barcodeCtrl.text = generateInternalBarcode(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _kPrimaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildUnitInput(
                        label: "ราคาต้นทุน",
                        ctrl: f.costPriceCtrl,
                        hint: "0.00",
                        isNumber: true,
                        allowDecimal: true,
                        prefixText: "฿ ",
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildUnitInput(
                        label: "ราคาขาย",
                        ctrl: f.sellPriceCtrl,
                        hint: "0.00",
                        isNumber: true,
                        allowDecimal: true,
                        prefixText: "฿ ",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodeField(AddProductController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "บาร์โค้ด (ถ้ามี)",
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
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                  // ✅ กันเผื่อสแกนเจอฟอร์แมตที่มีตัวอักษรปน (เช่น Code128/Code39)
                  // ช่องนี้รับเฉพาะตัวเลขเหมือนตอนพิมพ์เอง (digitsOnly formatter)
                  final digitsOnly = result.replaceAll(RegExp(r'[^0-9]'), '');
                  if (digitsOnly.isEmpty) {
                    Get.snackbar(
                      "ไม่สามารถใช้ได้",
                      "รหัสที่สแกนได้ไม่ใช่บาร์โค้ดสินค้า กรุณาสแกนใหม่หรือพิมพ์เอง",
                      backgroundColor: Colors.orange,
                      colorText: Colors.white,
                      margin: const EdgeInsets.all(16),
                    );
                    return;
                  }
                  controller.idController.text = digitsOnly;
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
            const SizedBox(width: 10),
            Tooltip(
              message:
                  'สร้างบาร์โค้ดให้อัตโนมัติ (สำหรับสินค้าที่ไม่มีบาร์โค้ด)',
              child: InkWell(
                onTap: () =>
                    controller.idController.text = generateInternalBarcode(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kPrimaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'ไม่มีบาร์โค้ด? กดปุ่มสร้างให้ แล้วนำไปพิมพ์ติดได้ที่เมนู "พิมพ์บาร์โค้ดสินค้า"',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
