import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // สำหรับ FilteringTextInputFormatter
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

// Import Model ของคุณ
import '../../../model/response/shop_response.dart';

// Import Controller ที่เพิ่งแยกออกไป
import 'edit_shop_controller.dart';

class EditShopScreen extends StatelessWidget {
  final ShopResponse shop;

  const EditShopScreen({Key? key, required this.shop}) : super(key: key);

  final Color primaryGreen = const Color(0xFF00C853);
  final Color bgColor = const Color(0xFFF4F7FA);
  final Color textColor = const Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EditShopController(shop: shop));

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "แก้ไขร้านค้า",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- ส่วนรูปภาพ ---
                    Center(
                      child: Stack(
                        children: [
                          Obx(() {
                            ImageProvider? imageProvider;
                            if (controller.selectedImage.value != null) {
                              imageProvider = FileImage(
                                controller.selectedImage.value!,
                              );
                            } else if (shop.imgShop.isNotEmpty) {
                              imageProvider = NetworkImage(shop.imgShop);
                            }

                            return Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFF1F5F9),
                                  width: 2,
                                ),
                                image: imageProvider != null
                                    ? DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: imageProvider == null
                                  ? Icon(
                                      Icons.store,
                                      size: 50,
                                      color: Colors.blueGrey.shade200,
                                    )
                                  : null,
                            );
                          }),

                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                controller.showImagePickerOptions();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    _buildSectionTitle("ข้อมูลร้านค้า"),
                    const SizedBox(height: 20),

                    _buildLabel("ชื่อร้านค้า"),
                    _buildTextField(controller.nameController, Icons.store_outlined),
                    const SizedBox(height: 16),

                    _buildLabel("เบอร์โทรศัพท์"),
                    _buildTextField(
                      controller.phoneController,
                      Icons.phone_outlined,
                      inputType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel("ที่อยู่ร้านค้า"),
                    _buildTextField(
                      controller.addressController,
                      Icons.location_on_outlined,
                      maxLines: 3,
                      hint: "กรอกที่อยู่ร้านค้า",
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ),

                    _buildSectionTitle("การชำระเงินและความปลอดภัย"),
                    const SizedBox(height: 20),

                    // --- ส่วนรูปภาพ QR Code ---
                    _buildLabel("รูปภาพ QR Code สำหรับสแกนจ่าย"),
                    const SizedBox(height: 8),
                    Center(
                      child: Stack(
                        children: [
                          Obx(() {
                            ImageProvider? qrImageProvider;
                            if (controller.selectedQrImage.value != null) {
                              qrImageProvider = FileImage(
                                controller.selectedQrImage.value!,
                              );
                            } else if (shop.imgQrcode.isNotEmpty) {
                              qrImageProvider = NetworkImage(shop.imgQrcode);
                            }

                            return Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFF1F5F9),
                                  width: 2,
                                ),
                                image: qrImageProvider != null
                                    ? DecorationImage(
                                        image: qrImageProvider,
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: qrImageProvider == null
                                  ? Icon(
                                      Icons.qr_code_2_rounded,
                                      size: 56,
                                      color: Colors.blueGrey.shade200,
                                    )
                                  : null,
                            );
                          }),

                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                controller.showQrImagePickerOptions();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildLabel("รหัส Pin Code (สำหรับยืนยัน)"),
                    Obx(() => _buildTextField(
                      controller.pinCodeController,
                      Icons.lock_outline_rounded,
                      inputType: TextInputType.number,
                      obscureText: !controller.isPinVisible.value,
                      maxLength: 6,
                      isNumberOnly: true,
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isPinVisible.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.blueGrey.shade400,
                          size: 20,
                        ),
                        onPressed: () {
                          controller.isPinVisible.value = !controller.isPinVisible.value;
                        },
                      ),
                    )),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ปุ่มบันทึก
              SizedBox(
                width: double.infinity,
                height: 55,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () => controller.saveShop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      disabledBackgroundColor: primaryGreen.withValues(alpha: 0.5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            "บันทึกการเปลี่ยนแปลง",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.blueGrey.shade400,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    IconData icon, {
    TextInputType inputType = TextInputType.text,
    bool obscureText = false,
    int maxLines = 1,
    int? maxLength,
    String? hint,
    bool isNumberOnly = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      obscureText: obscureText,
      maxLines: maxLines,
      maxLength: maxLength,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1E293B),
      ),
      inputFormatters: isNumberOnly
          ? [FilteringTextInputFormatter.digitsOnly]
          : [],
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blueGrey.shade400, size: 20),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGreen, width: 1.5),
        ),
        counterText: "",
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 15,
        ),
      ),
    );
  }
}
