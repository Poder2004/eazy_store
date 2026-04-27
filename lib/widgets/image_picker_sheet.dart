import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerSheet extends StatelessWidget {
  final Function(ImageSource source) onImagePicked;
  final String title;

  const ImagePickerSheet({
    super.key,
    required this.onImagePicked,
    this.title = "เลือกรูปภาพ",
  });

  // ฟังก์ชันช่วยเปิด BottomSheet แบบ Static เพื่อให้เรียกใช้ง่ายๆ
  static void show({
    required Function(ImageSource source) onImagePicked,
    String? title,
  }) {
    Get.bottomSheet(
      ImagePickerSheet(onImagePicked: onImagePicked, title: title ?? "เลือกรูปภาพ"),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle สำหรับรูดลง
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 25),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPickerButton(
                icon: Icons.camera_alt_rounded,
                label: "ถ่ายภาพ",
                color: Colors.blueAccent,
                onTap: () {
                  Get.back(); // ปิด sheet
                  onImagePicked(ImageSource.camera);
                },
              ),
              _buildPickerButton(
                icon: Icons.photo_library_rounded,
                label: "คลังรูปภาพ",
                color: Colors.purpleAccent,
                onTap: () {
                  Get.back(); // ปิด sheet
                  onImagePicked(ImageSource.gallery);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

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
              color: color.withOpacity(0.1),
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
}