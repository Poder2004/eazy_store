// ไฟล์: lib/sale_producct/edit_product_screen.dart (ปรับ path ตามจริงของคุณ)
import 'package:eazy_store/model/request/category_model.dart';
import 'package:eazy_store/page/sale_producct/scanBarcode/scan_barcode.dart';
import 'package:eazy_store/widgets/category_bottom_sheet.dart';
import 'package:eazy_store/widgets/category_disable_dialog.dart';
import 'package:eazy_store/widgets/inactive_categories_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'edit_product_controller.dart'; // ✅ นำเข้า Controller ที่แยกไว้

class EditProductScreen extends StatelessWidget {
  const EditProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ เรียกใช้ Controller
    final EditProductController controller = Get.put(EditProductController());
    const primaryColor = Color(0xFF6B8E23);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "แก้ไขสินค้า",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(
            () => TextButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () => controller.confirmSave(context),
              child: controller.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryColor,
                      ),
                    )
                  : const Text(
                      "บันทึก",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📸 ส่วนรูปภาพ
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () => controller.showImagePickerOptions(),
                      child: Obx(() {
                        ImageProvider imageProvider;
                        if (controller.selectedImage.value != null) {
                          imageProvider = FileImage(
                            controller.selectedImage.value!,
                          );
                        } else {
                          imageProvider = NetworkImage(
                            controller.originalProduct.imgProduct,
                          );
                        }

                        return Hero(
                          tag:
                              'product-${controller.originalProduct.productId}',
                          child: Container(
                            height: 180,
                            width: 180,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade300),
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.contain,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => controller.showImagePickerOptions(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 📝 ข้อมูลทั่วไป
              _buildSectionTitle("ข้อมูลทั่วไป"),
              _buildCardContainer(
                children: [
                  _buildTextField(
                    label: "ชื่อสินค้า",
                    controller: controller.nameCtrl,
                    icon: Icons.edit_note,
                    validator: (v) => v!.isEmpty ? "กรุณากรอกชื่อสินค้า" : null,
                  ),
                  const Divider(height: 1),

                  // หมวดหมู่สินค้า
                  InkWell(
                    onTap: () {
                      _showCategoryBottomSheet(context, controller);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "หมวดหมู่สินค้า",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Obx(
                                  () => Text(
                                    controller.selectedCategory.value?.name ??
                                        "เลือกหมวดหมู่",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color:
                                          controller.selectedCategory.value ==
                                              null
                                          ? Colors.grey
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 1),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: "บาร์โค้ด",
                          controller: controller.barcodeCtrl,
                          icon: Icons.qr_code_scanner,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: InkWell(
                          onTap: () async {
                            var result = await Get.to(
                              () => const ScanBarcodePage(),
                            );
                            if (result != null && result is String) {
                              controller.barcodeCtrl.text = result;
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: primaryColor),
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner,
                              color: primaryColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                  _buildTextField(
                    label: "หน่วยนับ",
                    controller: controller.unitCtrl,
                    icon: Icons.scale,
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // 📦 คลังสินค้า
              _buildSectionTitle("คลังสินค้า"),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _buildTextField(
                  label: "จำนวนคงเหลือ",
                  controller: controller.stockCtrl,
                  icon: Icons.inventory_2,
                  readOnly: true,
                  suffix: const Text(
                    "แก้ไขไม่ได้",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== Widget Helpers ====================

  void _showCategoryBottomSheet(
    BuildContext context,
    EditProductController controller,
  ) {
    CategoryBottomSheet.show(
      context: context,
      categories: controller.categories,
      selectedCategory: controller.selectedCategory,
      onCategorySelected: (cat) {
        controller.selectedCategory.value = cat;
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
    EditProductController controller,
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
      onRefreshCategories: controller.fetchCategories,
      onReopenBottomSheet: () {
        if (context.mounted) {
          _showCategoryBottomSheet(context, controller);
        }
      },
    );
  }

  void _showAddCategoryDialog(
    BuildContext context,
    EditProductController controller,
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
                  color: const Color(0xFF6B8E23).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 42,
                  color: Color(0xFF6B8E23),
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
                    color: Color(0xFF6B8E23),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF6B8E23),
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
                        backgroundColor: const Color(0xFF6B8E23),
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
    EditProductController controller,
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
                  color: const Color(0xFF6B8E23).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  size: 36,
                  color: Color(0xFF6B8E23),
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
                    color: Color(0xFF6B8E23),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF6B8E23),
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
                        backgroundColor: const Color(0xFF6B8E23),
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

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 4),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black54,
      ),
    ),
  );

  Widget _buildCardContainer({required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(children: children),
  );

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    bool readOnly = false,
    bool isPrice = false,
    Color? textColor,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        fontWeight: isPrice ? FontWeight.bold : FontWeight.normal,
        color: textColor ?? (readOnly ? Colors.grey.shade600 : Colors.black87),
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: icon != null
            ? Icon(icon, color: Colors.grey.shade400)
            : null,
        suffixIcon: suffix,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
