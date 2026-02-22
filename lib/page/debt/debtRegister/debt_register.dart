import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

// --- Import Controller ที่เราเพิ่งสร้าง ---
import 'debt_register_controller.dart';

const Color _kPrimaryColor = Color(0xFF6B8E23);
const Color _kBackgroundColor = Color(0xFFF7F7F7);
const Color _kFieldFillColor = Color(0xFFFAFFEF);
const Color _kBorderColor = Color(0xFFE0E0E0);

class DebtRegisterScreen extends StatelessWidget {
  DebtRegisterScreen({super.key});

  // ผูก Controller เข้ากับ View
  final DebtRegisterController controller = Get.put(DebtRegisterController());

  void _showImageSourceSheet() {
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
            const Text("เลือกรูปภาพลูกหนี้", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerButton(
                  icon: Icons.camera_alt_rounded,
                  label: "ถ่ายภาพ",
                  color: Colors.blueAccent,
                  onTap: () {
                    Get.back();
                    controller.pickImage(ImageSource.camera);
                  },
                ),
                _buildPickerButton(
                  icon: Icons.photo_library_rounded,
                  label: "คลังรูปภาพ",
                  color: Colors.purpleAccent,
                  onTap: () {
                    Get.back();
                    controller.pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        title: const Text('สมัครบัญชีลูกหนี้', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        centerTitle: true,
        backgroundColor: _kBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileImageUploader(),
            const SizedBox(height: 30),

            _buildInputField(label: 'ชื่อคนค้างชำระ', hint: 'ชื่อคนค้างชำระ', controller: controller.nameController),
            _buildInputField(label: 'เบอร์โทรศัพท์', hint: 'เบอร์โทรศัพท์', controller: controller.phoneController, keyboardType: TextInputType.phone),

            const Padding(
              padding: EdgeInsets.only(top: 15.0),
              child: Text('ที่อยู่', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),

            Obx(() {
              if (controller.fullAddressData.value == null) {
                return const LinearProgressIndicator(color: _kPrimaryColor);
              }
              
              final List<String> provinces = controller.fullAddressData.value!.keys.toList();
              return Column(
                children: [
                  _buildAddressDropdown(
                    hint: 'จังหวัด',
                    selectedValue: controller.selectedProvince.value,
                    items: provinces,
                    onChanged: controller.onProvinceChanged,
                  ),
                  _buildAddressDropdown(
                    hint: 'อำเภอ',
                    selectedValue: controller.selectedDistrict.value,
                    items: controller.districts,
                    onChanged: controller.onDistrictChanged,
                    disabled: controller.selectedProvince.value == null,
                  ),
                  _buildAddressDropdown(
                    hint: 'ตำบล',
                    selectedValue: controller.selectedSubdistrict.value,
                    items: controller.subdistricts,
                    onChanged: (v) => controller.selectedSubdistrict.value = v,
                    disabled: controller.selectedDistrict.value == null,
                  ),
                ],
              );
            }),

            _buildInputField(hint: 'บ้านเลขที่/ซอย/ถนน', label: '', isAddress: true, controller: controller.addressDetailController),

            _buildInputField(label: 'วงเงินค้างชำระ', hint: 'วงเงินค้างชำระ', controller: controller.creditLimitController, keyboardType: TextInputType.number),
            
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: controller.submitDebtorData, // เรียกฟังก์ชันจาก Controller ได้โดยตรง
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
              ),
              child: const Text('เพิ่ม', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- Reusable Widgets ---

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool isAddress = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isAddress)
          Padding(
            padding: const EdgeInsets.only(top: 15.0, bottom: 5.0),
            child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          ),
        Container(
          height: 50,
          margin: EdgeInsets.only(top: isAddress ? 10.0 : 0),
          decoration: BoxDecoration(
            color: _kFieldFillColor,
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: _kBorderColor),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 15),
              hintText: hint,
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressDropdown({
    required String hint,
    required String? selectedValue,
    required List<String> items,
    required void Function(String?) onChanged,
    bool disabled = false,
  }) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 10.0),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: disabled ? Colors.grey.shade200 : _kFieldFillColor,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: _kBorderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint, style: TextStyle(color: disabled ? Colors.grey : Colors.grey.shade600)),
          value: selectedValue,
          onChanged: disabled ? null : onChanged,
          items: items.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
        ),
      ),
    );
  }

  Widget _buildProfileImageUploader() {
    return Center(
      child: GestureDetector(
        onTap: _showImageSourceSheet,
        child: Obx(() => Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            color: _kFieldFillColor,
            border: Border.all(color: _kPrimaryColor.withOpacity(0.5), width: 2),
            borderRadius: BorderRadius.circular(15.0),
            image: controller.imageFile.value != null
                ? DecorationImage(image: FileImage(controller.imageFile.value!), fit: BoxFit.cover)
                : null,
          ),
          child: controller.imageFile.value == null
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined, color: _kPrimaryColor, size: 40),
                    Text('เพิ่มรูปภาพ', style: TextStyle(fontSize: 14, color: _kPrimaryColor)),
                  ],
                )
              : null,
        )),
      ),
    );
  }

  Widget _buildPickerButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}