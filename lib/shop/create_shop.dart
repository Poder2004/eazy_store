import 'package:eazy_store/homepage/home_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
// ตรวจสอบ path ของ HomePage ให้ตรงกับโปรเจกต์ของคุณพี่นะครับ
// ถ้าอยู่ใน folder เดียวกันใช้ import 'home_page.dart'; ได้เลย

// ----------------------------------------------------------------------
// 1. Controller: จัดการ Logic การสร้างร้านค้า + รูปภาพ
// ----------------------------------------------------------------------
class CreateShopController extends GetxController {
  final shopNameController = TextEditingController();
  final shopPhoneController = TextEditingController();
  final addressController = TextEditingController();

  // --- Image Picker Logic ---
  final ImagePicker _picker = ImagePicker();

  // ตัวแปรเก็บไฟล์รูปภาพ
  Rx<File?> profileImage = Rx<File?>(null);
  Rx<File?> qrImage = Rx<File?>(null);

  // ฟังก์ชันเลือกรูปภาพ
  Future<void> pickImage(ImageSource source, {required bool isProfile}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image != null) {
        if (isProfile) {
          profileImage.value = File(image.path);
        } else {
          qrImage.value = File(image.path);
        }
      }
    } catch (e) {
      print("Error picking image: $e");
      Get.snackbar("เกิดข้อผิดพลาด", "ไม่สามารถเลือกรูปภาพได้");
    }
  }

  // --- Dropdown Logic ---
  var selectedProvince = "".obs;
  var selectedDistrict = "".obs;
  var selectedSubDistrict = "".obs;

  void submitShopInfo() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDD835).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFFFDD835),
                    child: Icon(Icons.check, color: Colors.white, size: 40),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "สมัครร้านค้าสำเร็จ",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8BC34A),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back(); // ปิด Dialog
                    Get.offAll(() => const HomePage()); // ไปหน้าหลัก
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    "ตกลง",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}

// ----------------------------------------------------------------------
// 2. The View: หน้าจอ UI
// ----------------------------------------------------------------------
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

              const SizedBox(height: 10),
              const Text(
                "ที่อยู่ร้าน",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              _buildDropdown(hint: "จังหวัด"),
              _buildDropdown(hint: "อำเภอ"),
              _buildDropdown(hint: "ตำบล"),
              _buildLineInput(
                label: "",
                hint: "บ้านเลขที่ หมู่ที่",
                controller: controller.addressController,
                noLabel: true,
              ),

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
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Center(
                    child: Text(
                      "อัพโหลดภาพ",
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

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: controller.submitShopInfo,
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
              borderSide: BorderSide(color: Colors.green.withOpacity(0.3)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF00C853)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({required String hint}) {
    return Column(
      children: [
        const SizedBox(height: 10),
        TextField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            suffixIcon: const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.green.withOpacity(0.3)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF00C853)),
            ),
          ),
          onTap: () {
            print("เลือก $hint");
          },
        ),
      ],
    );
  }
}
