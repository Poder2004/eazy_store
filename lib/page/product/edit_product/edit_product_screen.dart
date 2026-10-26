// ไฟล์: lib/sale_producct/edit_product_screen.dart (ปรับ path ตามจริงของคุณ)
import 'package:eazy_store/model/request/category_model.dart';
import 'package:eazy_store/model/response/product_response.dart';
import 'package:eazy_store/page/product/add_stock/add_stock.dart';
import 'package:eazy_store/page/sale_producct/scanBarcode/scan_barcode.dart';
import 'package:eazy_store/widgets/category_bottom_sheet.dart';
import 'package:eazy_store/widgets/category_disable_dialog.dart';
import 'package:eazy_store/widgets/inactive_categories_sheet.dart';
import 'package:eazy_store/utils/internal_barcode.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'edit_product_controller.dart'; // ✅ นำเข้า Controller ที่แยกไว้

class EditProductScreen extends StatelessWidget {
  const EditProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _EditProductView();
  }
}

class _EditProductView extends StatefulWidget {
  @override
  State<_EditProductView> createState() => _EditProductViewState();
}

class _EditProductViewState extends State<_EditProductView> {
  late final EditProductController controller;

  @override
  void initState() {
    super.initState();
    // ✅ สร้าง controller ใหม่ทุกครั้งที่เปิดหน้านี้ กันข้อมูลสินค้าตัวก่อนหน้าค้าง
    // (ถ้าใช้ Get.put() เฉยๆ ใน build() ของ StatelessWidget เดิม พอเปิดหน้านี้
    // ซ้ำรอบสอง controller ตัวเก่าที่ยัง put ค้างอยู่จะถูกใช้ต่อ ทำให้ onInit()
    // ที่อ่าน Get.arguments ไม่ทำงานใหม่ เห็นข้อมูลสินค้า/สต็อกเป็นค่าเก่าจากรอบแรก)
    Get.delete<EditProductController>(force: true);
    controller = Get.put(EditProductController());
  }

  @override
  void dispose() {
    Get.delete<EditProductController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                          // พิมพ์เองเสร็จแล้วเช็คซ้ำให้ทันที
                          onEditingDone: controller.onBarcodeChanged,
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
                              // เตือนทันทีถ้าบาร์โค้ดนี้มีสินค้าตัวอื่นใช้อยู่
                              controller.onBarcodeChanged(result);
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
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Tooltip(
                          message: 'สร้างบาร์โค้ดให้อัตโนมัติ',
                          child: InkWell(
                            onTap: () {
                              final code = generateInternalBarcode();
                              controller.barcodeCtrl.text = code;
                              controller.onBarcodeChanged(code);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 20,
                              ),
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
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: "จำนวนคงเหลือ",
                            controller: controller.stockCtrl,
                            icon: Icons.add_box_rounded,
                            readOnly: true,
                            onIconTap: () => Get.to(
                              () => AddStockScreen(
                                initialProduct: controller.originalProduct,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Get.to(
                            () => AddStockScreen(
                              initialProduct: controller.originalProduct,
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6B8E23).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "เพิ่มสต็อก",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B8E23),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 1),
                    _buildTextField(
                      label: "แจ้งเตือนเมื่อสต็อกเหลือไม่เกิน (หน่วยเล็กสุด)",
                      controller: controller.lowStockCtrl,
                      icon: Icons.notifications_active_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // 📦 หน่วยขาย
              _buildSectionTitle("หน่วยขาย"),
              _buildCardContainer(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.straighten, color: Colors.grey.shade400),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "หน่วยฐาน",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                controller.unitCtrl.text.isEmpty
                                    ? '-'
                                    : controller.unitCtrl.text,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Obx(() {
                    if (controller.units.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          "ยังไม่มีหน่วยขายเพิ่มเติม เช่น ลัง/แพ็ค",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (int i = 0; i < controller.units.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          _buildUnitTile(
                            context,
                            controller,
                            controller.units[i],
                          ),
                        ],
                      ],
                    );
                  }),
                  const Divider(height: 1),
                  InkWell(
                    onTap: () => _showUnitFormSheet(context, controller),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: primaryColor, size: 18),
                          SizedBox(width: 6),
                          Text(
                            "เพิ่มหน่วยขาย",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
      onRefreshCategories: (CategoryModel? movedToCategory) async {
        await controller.fetchCategories();
        // เปลี่ยน/ล้างหมวดหมู่ที่เลือกในฟอร์ม เฉพาะตอนหมวดหมู่ที่กำลังปิดใช้งาน
        // เป็นหมวดหมู่เดียวกับที่เลือกอยู่ในฟอร์มนี้เท่านั้น ไม่งั้นปิดหมวดหมู่อื่น
        // ที่ไม่เกี่ยวข้องก็จะไปรีเซ็ตหมวดหมู่ที่เลือกไว้ในฟอร์มด้วย
        if (controller.selectedCategory.value?.categoryId ==
            category.categoryId) {
          controller.selectedCategory.value = movedToCategory;
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

  Widget _buildUnitTile(
    BuildContext context,
    EditProductController controller,
    ProductUnitResponse unit,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6B8E23).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF6B8E23),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${unit.unitName} = ${unit.conversionQty} ${controller.unitCtrl.text}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "ขาย ฿${unit.sellPrice.toStringAsFixed(0)} · ทุน ฿${unit.costPrice.toStringAsFixed(0)}"
                  "${(unit.barcode != null && unit.barcode!.isNotEmpty) ? ' · บาร์โค้ด ${unit.barcode}' : ''}",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () =>
                _showUnitFormSheet(context, controller, existing: unit),
            icon: Icon(
              Icons.edit_outlined,
              size: 18,
              color: Colors.grey.shade600,
            ),
          ),
          IconButton(
            onPressed: () => _confirmDeleteUnit(controller, unit),
            icon: const Icon(
              Icons.delete_outline,
              size: 18,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUnit(
    EditProductController controller,
    ProductUnitResponse unit,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text("ลบหน่วยขายนี้?"),
        content: Text(
          "ลบหน่วย \"${unit.unitName}\" ออกจากสินค้านี้ ถ้าเคยมีประวัติขายระบบจะซ่อนไว้แทนการลบถาวร",
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("ยกเลิก")),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteUnit(unit);
            },
            child: const Text("ลบ", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // ชื่อหน่วยขายที่พบบ่อย (หน่วยใหญ่) ให้เลือกเป็นทางลัด พิมพ์เองได้เหมือนเดิม
  static const List<String> _packUnitNames = [
    'ลัง',
    'แพ็ค',
    'โหล',
    'กล่อง',
    'ถุง',
    'ห่อ',
    'เซ็ต',
    'แผง',
    'กระสอบ',
    'ถัง',
  ];

  // ช่องกรอกในฟอร์มหน่วยขาย — label ด้านบน พื้นเทาอ่อน มุมโค้ง เหมือนหน้าเพิ่มสินค้า
  Widget _sheetField({
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
            color: const Color(0xFFF9FAFB),
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
              prefixIcon: prefixText == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(left: 14, right: 4),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          prefixText,
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

  // เลือกชื่อหน่วยจากรายการ (ตัดชื่อที่ซ้ำกับหน่วยฐานออก)
  void _pickUnitName(
    BuildContext context,
    TextEditingController target,
    String baseUnit,
  ) {
    final options = _packUnitNames.where((u) => u != baseUnit).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
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
              const Text(
                "เลือกชื่อหน่วยขาย",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final u in options)
                      ListTile(
                        title: Text(u),
                        trailing: target.text.trim() == u
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF6B8E23),
                                size: 20,
                              )
                            : null,
                        onTap: () {
                          target.text = u;
                          Navigator.pop(sheetCtx);
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showUnitFormSheet(
    BuildContext context,
    EditProductController controller, {
    ProductUnitResponse? existing,
  }) {
    const primaryColor = Color(0xFF6B8E23);
    final nameCtrl = TextEditingController(text: existing?.unitName ?? '');
    final convCtrl = TextEditingController(
      text: existing != null ? existing.conversionQty.toString() : '',
    );
    final barcodeCtrl = TextEditingController(text: existing?.barcode ?? '');
    final sellCtrl = TextEditingController(
      text: existing != null ? existing.sellPrice.toStringAsFixed(2) : '',
    );
    final costCtrl = TextEditingController(
      text: existing != null ? existing.costPrice.toStringAsFixed(2) : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Text(
                    existing == null ? "เพิ่มหน่วยขาย" : "แก้ไขหน่วยขาย",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // สรุปสดว่า "1 ลัง = 12 ขวด" อัปเดตตามที่พิมพ์
                  ListenableBuilder(
                    listenable: Listenable.merge([
                      nameCtrl,
                      convCtrl,
                      controller.unitCtrl,
                    ]),
                    builder: (_, __) {
                      final n = nameCtrl.text.trim();
                      final c = convCtrl.text.trim();
                      final base = controller.unitCtrl.text.trim();
                      final ready = n.isNotEmpty && c.isNotEmpty;
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          ready
                              ? "1 $n = $c ${base.isEmpty ? 'หน่วยฐาน' : base}"
                              : "ตัวอย่าง: 1 ลัง = 12 ${base.isEmpty ? 'ขวด' : base}",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ready ? primaryColor : Colors.grey[500],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _sheetField(
                          label: "ชื่อหน่วย",
                          ctrl: nameCtrl,
                          hint: "เช่น ลัง, แพ็ค",
                          suffix: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              FocusScope.of(ctx).unfocus();
                              _pickUnitName(
                                ctx,
                                nameCtrl,
                                controller.unitCtrl.text.trim(),
                              );
                            },
                            child: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _sheetField(
                          label: "แปลงเป็นหน่วยฐาน",
                          ctrl: convCtrl,
                          hint: "เช่น 12",
                          isNumber: true,
                          suffix: ListenableBuilder(
                            listenable: controller.unitCtrl,
                            builder: (_, __) => ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 56),
                              child: Text(
                                controller.unitCtrl.text.trim().isEmpty
                                    ? "หน่วยฐาน"
                                    : controller.unitCtrl.text.trim(),
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
                        child: _sheetField(
                          label: "บาร์โค้ด (ถ้ามี)",
                          ctrl: barcodeCtrl,
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
                            barcodeCtrl.text = result;
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner,
                            color: primaryColor,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Tooltip(
                        message: 'สร้างบาร์โค้ดให้อัตโนมัติ',
                        child: InkWell(
                          onTap: () =>
                              barcodeCtrl.text = generateInternalBarcode(),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: primaryColor,
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
                        child: _sheetField(
                          label: "ราคาต้นทุน",
                          ctrl: costCtrl,
                          hint: "0.00",
                          isNumber: true,
                          allowDecimal: true,
                          prefixText: "฿",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _sheetField(
                          label: "ราคาขาย",
                          ctrl: sellCtrl,
                          hint: "0.00",
                          isNumber: true,
                          allowDecimal: true,
                          prefixText: "฿",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final conv = int.tryParse(convCtrl.text.trim());
                        final sell = double.tryParse(sellCtrl.text.trim());
                        final cost = double.tryParse(costCtrl.text.trim()) ?? 0;
                        final bc = barcodeCtrl.text.trim();

                        if (name.isEmpty) {
                          Get.snackbar(
                            "แจ้งเตือน",
                            "กรุณากรอกชื่อหน่วย",
                            backgroundColor: Colors.orange,
                            colorText: Colors.white,
                          );
                          return;
                        }
                        if (conv == null || conv <= 1) {
                          Get.snackbar(
                            "แจ้งเตือน",
                            "จำนวนแปลงต้องเป็นตัวเลขมากกว่า 1",
                            backgroundColor: Colors.orange,
                            colorText: Colors.white,
                          );
                          return;
                        }
                        if (sell == null || sell <= 0) {
                          Get.snackbar(
                            "แจ้งเตือน",
                            "กรุณากรอกราคาขาย",
                            backgroundColor: Colors.orange,
                            colorText: Colors.white,
                          );
                          return;
                        }

                        bool ok;
                        if (existing == null) {
                          ok = await controller.addUnit(
                            unitName: name,
                            conversionQty: conv,
                            barcode: bc.isEmpty ? null : bc,
                            sellPrice: sell,
                            costPrice: cost,
                          );
                        } else {
                          ok = await controller.editUnit(
                            existing,
                            unitName: name,
                            conversionQty: conv,
                            barcode: bc.isEmpty ? null : bc,
                            sellPrice: sell,
                            costPrice: cost,
                          );
                        }
                        if (ok && ctx.mounted) Navigator.pop(ctx);
                      },
                      child: Text(
                        existing == null ? "เพิ่ม" : "บันทึก",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
    void Function(String)? onEditingDone,
    VoidCallback? onIconTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      onTapOutside: (_) {
        FocusManager.instance.primaryFocus?.unfocus();
        if (onEditingDone != null) onEditingDone(controller.text);
      },
      onFieldSubmitted: onEditingDone,
      inputFormatters: keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      validator: validator,
      style: TextStyle(
        fontWeight: isPrice ? FontWeight.bold : FontWeight.normal,
        color: textColor ?? (readOnly ? Colors.grey.shade600 : Colors.black87),
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: icon == null
            ? null
            : onIconTap == null
            ? Icon(icon, color: Colors.grey.shade400)
            : IconButton(
                icon: Icon(icon, color: const Color(0xFF6B8E23)),
                onPressed: onIconTap,
              ),
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
