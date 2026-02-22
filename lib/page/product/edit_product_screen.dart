import 'dart:io';
import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/api/api_service_image.dart'; // ตรวจสอบ path ให้ถูกต้อง
import 'package:eazy_store/model/request/product_model.dart';
import 'package:eazy_store/model/request/category_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

// ----------------------------------------------------------------------
// 1. Controller: จัดการ Logic ทุกอย่าง
// ----------------------------------------------------------------------
class EditProductController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Text Controllers
  late TextEditingController nameCtrl;
  late TextEditingController barcodeCtrl;
  late TextEditingController sellPriceCtrl;
  late TextEditingController costPriceCtrl;
  late TextEditingController stockCtrl;
  late TextEditingController unitCtrl;

  // Data Variables
  late Product originalProduct;
  var isLoading = false.obs;

  // 📷 ส่วนจัดการรูปภาพ
  var selectedImage = Rxn<File>();
  final ImagePicker _picker = ImagePicker();
  final ImageUploadService _imageService = ImageUploadService();

  // 📂 ส่วนจัดการหมวดหมู่
  var categories = <CategoryModel>[].obs;
  var selectedCategory = Rxn<CategoryModel>();

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is Product) {
      originalProduct = Get.arguments as Product;

      // Setup ค่าเริ่มต้น
      nameCtrl = TextEditingController(text: originalProduct.name);
      barcodeCtrl = TextEditingController(text: originalProduct.barcode ?? "");
      sellPriceCtrl = TextEditingController(
        text: originalProduct.sellPrice.toString(),
      );
      costPriceCtrl = TextEditingController(
        text: originalProduct.costPrice.toString(),
      );
      stockCtrl = TextEditingController(text: originalProduct.stock.toString());
      unitCtrl = TextEditingController(text: originalProduct.unit);

      // โหลดหมวดหมู่
      fetchCategories();
    } else {
      Get.back();
    }
  }

  // ดึงหมวดหมู่
  Future<void> fetchCategories() async {
    try {
      var list = await ApiProduct.getCategories();
      categories.assignAll(list);

      if (originalProduct.categoryId != 0) {
        selectedCategory.value = categories.firstWhere(
          (cat) => cat.categoryId == originalProduct.categoryId,
          orElse: () => CategoryModel(categoryId: 0, name: "ไม่ระบุ"),
        );
      }
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  // เลือกรูปภาพ
  Future<void> pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (image != null) {
      selectedImage.value = File(image.path);
    }
    Get.back();
  }

  // ✨ ฟังก์ชันใหม่: แสดง Dialog ยืนยันก่อนบันทึก
  void confirmSave(BuildContext context) {
    // ตรวจสอบฟอร์มเบื้องต้นก่อน (ถ้าไม่ผ่าน ไม่ต้องโชว์ Dialog)
    if (!formKey.currentState!.validate()) return;
    if (selectedCategory.value == null) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณาเลือกหมวดหมู่สินค้า",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // แสดง Dialog สวยๆ
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon ส่วนหัว
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B8E23).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.save_as_rounded,
                  size: 40,
                  color: Color(0xFF6B8E23),
                ),
              ),
              const SizedBox(height: 20),

              // ข้อความ
              const Text(
                "ยืนยันการแก้ไข?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "ข้อมูลสินค้าจะถูกอัปเดตเข้าสู่ระบบ\nคุณตรวจสอบความถูกต้องเรียบร้อยแล้วใช่ไหม?",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 25),

              // ปุ่มกด
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(), // ปิด Dialog
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        "ตรวจสอบก่อน",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back(); // ปิด Dialog
                        saveProduct(); // เรียกฟังก์ชันบันทึกจริง
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B8E23),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "ยืนยันบันทึก",
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
      barrierDismissible: false, // บังคับให้กดปุ่มเท่านั้นถึงจะปิดได้
    );
  }

  // 💾 บันทึกข้อมูล (Logic เดิม ย้ายมาอยู่หลัง Dialog)
  Future<void> saveProduct() async {
    isLoading.value = true;

    try {
      String? newImageUrl;

      // 3. ☁️ อัปรูป (ถ้ามี)
      if (selectedImage.value != null) {
        Get.snackbar(
          "กำลังประมวลผล",
          "กำลังอัปโหลดรูปภาพ...",
          showProgressIndicator: true,
        );
        newImageUrl = await _imageService.uploadImage(selectedImage.value!);

        if (newImageUrl == null) {
          isLoading.value = false;
          Get.snackbar(
            "ผิดพลาด",
            "อัปโหลดรูปไม่ผ่าน กรุณาลองใหม่",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
      }

      // 4. เตรียมข้อมูล JSON
      Map<String, dynamic> updateData = {
        "name": nameCtrl.text.trim(),
        "barcode": barcodeCtrl.text.trim().isEmpty
            ? null
            : barcodeCtrl.text.trim(),
        "sell_price": double.tryParse(sellPriceCtrl.text) ?? 0.0,
        "cost_price": double.tryParse(costPriceCtrl.text) ?? 0.0,
        "unit": unitCtrl.text.trim(),
        "category_id": selectedCategory.value!.categoryId,
      };

      if (newImageUrl != null) {
        updateData["img_product"] = newImageUrl;
      }

      // 5. 🚀 ยิง API
      Product? updatedProduct = await ApiProduct.updateProduct(
        originalProduct.productId!,
        updateData,
      );

      isLoading.value = false;

      if (updatedProduct != null) {
        Get.back(result: updatedProduct); // กลับหน้า Detail
        Get.snackbar(
          "สำเร็จ",
          "แก้ไขข้อมูลเรียบร้อย",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          "ผิดพลาด",
          "บันทึกข้อมูลไม่สำเร็จ",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", "เกิดข้อผิดพลาด: $e", backgroundColor: Colors.red);
    }
  }
}

// ----------------------------------------------------------------------
// 2. View: หน้าจอ UI
// ----------------------------------------------------------------------
class EditProductScreen extends StatelessWidget {
  const EditProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EditProductController());
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
              // ✨ เปลี่ยนตรงนี้: เรียก confirmSave แทน saveProduct โดยตรง
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

  // --- Widgets Helpers ---
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
