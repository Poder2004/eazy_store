import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

// ✅ นำเข้าไฟล์ Controller ที่เพิ่งสร้างใหม่
import 'create_shop_controller.dart'; 

class CreateShopPage extends StatelessWidget {
  const CreateShopPage({super.key});

  // --- ✨ ฟังก์ชันแสดง Popup เลือกรูปภาพแบบใหม่ (สวยงามขึ้น) ---
  void _showImagePickerOptions(
    BuildContext context,
    CreateShopController controller, {
    required bool isProfile,
  }) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: 40,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(30),
          ), // มุมโค้งมนสวยๆ
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ขีดเล็กๆ ด้านบนเพื่อให้รู้ว่ารูดลงได้
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 25),

            const Text(
              "เลือกรูปภาพ",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // ปุ่มเลือก 2 อันเรียงกัน (กล้อง - อัลบั้ม)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 1. ปุ่มถ่ายภาพ
                _buildPickerButton(
                  icon: Icons.camera_alt_rounded,
                  label: "ถ่ายภาพ",
                  color: Colors.blueAccent,
                  onTap: () {
                    Get.back();
                    controller.pickImage(
                      ImageSource.camera,
                      isProfile: isProfile,
                    );
                  },
                ),

                // 2. ปุ่มเลือกจากอัลบั้ม
                _buildPickerButton(
                  icon: Icons.photo_library_rounded,
                  label: "คลังรูปภาพ",
                  color: Colors.purpleAccent,
                  onTap: () {
                    Get.back();
                    controller.pickImage(
                      ImageSource.gallery,
                      isProfile: isProfile,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent, // ให้พื้นหลังใสเพื่อโชว์มุมโค้ง
      isScrollControlled: true,
    );
  }

  // Widget สร้างปุ่มเลือกรูป (วงกลมสีๆ + ไอคอน + ข้อความ)
  Widget _buildPickerButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1), // สีพื้นหลังจางๆ
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 35, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ใช้ Get.put เพื่อสร้าง Controller 
    final CreateShopController controller = Get.put(CreateShopController());
    final Color primaryGreen = const Color(0xFF00C853);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "ข้อมูลร้านค้า",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // --- 1. Profile Image Picker ---
              const Text(
                "โปรไฟล์",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Center(
                child: GestureDetector(
                  onTap: () => _showImagePickerOptions(
                    context,
                    controller,
                    isProfile: true,
                  ),
                  child: Obx(
                    () => Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                        image: controller.profileImage.value != null
                            ? DecorationImage(
                                image: FileImage(
                                  controller.profileImage.value!,
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: controller.profileImage.value == null
                          ? Icon(
                              Icons.camera_alt,
                              color: Colors.grey[600],
                              size: 40,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // --- Inputs ---
              _buildLineInput(
                label: "ชื่อร้านค้า",
                hint: "ชื่อร้านค้า",
                controller: controller.shopNameController,
              ),

              _buildLineInput(
                label: "เบอร์ร้าน",
                hint: "เบอร์ร้าน",
                controller: controller.shopPhoneController,
                inputType: TextInputType.phone,
              ),

              const SizedBox(height: 20),
              
              // ----------------------------------------------------
              // ➡️ 4. ส่วน Dropdown ที่อยู่
              // ----------------------------------------------------
              const Text(
                "ที่อยู่ร้าน",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF333333)),
              ),
              
              // Dropdown จังหวัด
              Obx(() => _buildAddressDropdown<String>(
                hint: 'จังหวัด',
                selectedValue: controller.selectedProvince.value,
                items: controller.provinces.toList(), // แปลง RxList เป็น List
                onChanged: controller.onProvinceChanged,
                disabled: controller.provinces.isEmpty,
              )),

              // Dropdown อำเภอ
              Obx(() => _buildAddressDropdown<String>(
                hint: 'อำเภอ',
                selectedValue: controller.selectedDistrict.value,
                items: controller.districts.toList(), // แปลง RxList เป็น List
                onChanged: controller.onDistrictChanged,
                disabled: controller.selectedProvince.value == null || controller.districts.isEmpty,
              )),

              // Dropdown ตำบล
              Obx(() => _buildAddressDropdown<String>(
                hint: 'ตำบล',
                selectedValue: controller.selectedSubDistrict.value,
                items: controller.subdistricts.toList(), // แปลง RxList เป็น List
                onChanged: controller.onSubDistrictChanged,
                disabled: controller.selectedDistrict.value == null || controller.subdistricts.isEmpty,
              )),

              // บ้านเลขที่
              _buildLineInput(
                label: "",
                hint: "บ้านเลขที่ หมู่ที่",
                controller: controller.addressController,
                noLabel: true,
              ),
              // ----------------------------------------------------
              // ⬅️ สิ้นสุดส่วน Dropdown ที่อยู่
              // ----------------------------------------------------

              const SizedBox(height: 20),

              // --- 2. Upload QR Section ---
              const Text(
                "ลิงก์ภาพ QR สำหรับลูกค้าชำระเงินโอน",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),

              GestureDetector(
                onTap: () => _showImagePickerOptions(
                  context,
                  controller,
                  isProfile: false,
                ),
                child: Container(
                  width: 150,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      "อัพโหลดภาพ QR",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),
              Obx(() {
                if (controller.qrImage.value != null) {
                  return Stack(
                    children: [
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: FileImage(controller.qrImage.value!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 5,
                        top: 5,
                        child: GestureDetector(
                          onTap: () => controller.qrImage.value = null,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),

              const SizedBox(height: 40),

              // ปุ่มดำเนินการต่อ
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: controller.validateAndGoToPin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    "ดำเนินการต่อ",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType inputType = TextInputType.text,
    bool noLabel = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!noLabel) ...[
          const SizedBox(height: 20),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
        TextField(
          controller: controller,
          keyboardType: inputType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: const Color(0xFF00C853).withOpacity(0.3)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF00C853)),
            ),
          ),
        ),
      ],
    );
  }

  // Helper Widget สำหรับ Dropdown ที่อยู่
  Widget _buildAddressDropdown<T>({
    required String hint,
    required T? selectedValue,
    required List<T> items, 
    required void Function(T?) onChanged,
    required bool disabled,
  }) {
    final Color primaryGreen = const Color(0xFF00C853);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: DropdownButtonFormField<T>(
        value: selectedValue,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: primaryGreen.withOpacity(0.3)),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: primaryGreen),
          ),
          disabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        isExpanded: true,
        icon: Icon(Icons.keyboard_arrow_down, color: disabled ? Colors.grey[300] : primaryGreen),
        style: TextStyle(color: disabled ? Colors.grey : Colors.black, fontSize: 16),
        dropdownColor: Colors.white,
        onChanged: disabled ? null : onChanged, 
        items: items.isEmpty
            ? null 
            : items.map((T value) {
                return DropdownMenuItem<T>(
                  value: value,
                  child: Text(value.toString()),
                );
              }).toList(),
      ),
    );
  }
}