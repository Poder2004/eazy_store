// ไฟล์: lib/sale_producct/edit_product_screen.dart (ปรับ path ตามจริงของคุณ)
import 'package:eazy_store/model/request/category_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
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
                      onTap: () => _showImagePickerOptions(context, controller),
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
                        onTap: () =>
                            _showImagePickerOptions(context, controller),
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
                    onTap: () => _showCategorySelector(context, controller),
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
                  _buildTextField(
                    label: "บาร์โค้ด",
                    controller: controller.barcodeCtrl,
                    icon: Icons.qr_code_scanner,
                    keyboardType: TextInputType.number,
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

              // 💰 ราคา
              _buildSectionTitle("ตั้งราคาสินค้า"),
              _buildCardContainer(
                children: [
                  _buildTextField(
                    label: "ราคาขาย (บาท)",
                    controller: controller.sellPriceCtrl,
                    icon: Icons.sell,
                    isPrice: true,
                    textColor: primaryColor,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const Divider(height: 1),
                  _buildTextField(
                    label: "ราคาต้นทุน (บาท)",
                    controller: controller.costPriceCtrl,
                    icon: Icons.attach_money,
                    isPrice: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
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

  void _showImagePickerOptions(
    BuildContext context,
    EditProductController controller,
  ) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "เปลี่ยนรูปสินค้า",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text("ถ่ายรูปใหม่"),
              onTap: () => controller.pickImage(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text("เลือกจากอัลบั้ม"),
              onTap: () => controller.pickImage(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategorySelector(
    BuildContext context,
    EditProductController controller,
  ) {
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                "เลือกหมวดหมู่สินค้า",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Obx(() {
                if (controller.categories.isEmpty)
                  return const Center(child: Text("ไม่พบหมวดหมู่"));
                return ListView.separated(
                  itemCount: controller.categories.length,
                  separatorBuilder: (c, i) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final cat = controller.categories[index];
                    final isSelected =
                        controller.selectedCategory.value?.categoryId ==
                        cat.categoryId;
                    return ListTile(
                      title: Text(
                        cat.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? const Color(0xFF6B8E23)
                              : Colors.black87,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFF6B8E23),
                            )
                          : null,
                      onTap: () {
                        controller.selectedCategory.value = cat;
                        Get.back();
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
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
