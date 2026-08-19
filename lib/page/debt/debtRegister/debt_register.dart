import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

// --- Import Controller ที่เราเพิ่งสร้าง ---
import 'debt_register_controller.dart';

// สีชุดเดียวกับหน้า "บันทึกค้างชำระ" (debt_sale.dart) เพราะเป็นหน้าที่เปิดต่อ
// กันในโฟลว์เดียวกัน (กด "สร้างลูกหนี้ใหม่" จากหน้านั้นมาหน้านี้) เดิมหน้านี้
// ใช้สีเขียวมะกอกของโมดูลสั่งซื้อสินค้า เลยดูหลุดธีมไปคนละทาง
const Color _kPrimaryColor = Color(0xFF2563EB); // ฟ้าพรีเมียม
const Color _kSuccessColor = Color(
  0xFF10B981,
); // เขียว ใช้กับปุ่มยืนยัน/บันทึกจริง
const Color _kBackgroundColor = Color(0xFFF4F7FA);
const Color _kFieldFillColor = Color(0xFFECEFF1); // blueGrey.shade50
const Color _kBorderColor = Color(0xFFE2E8F0);
const Color _kErrorColor = Color(0xFFDC2626);
const Color _kTextColor = Color(0xFF2A2A2A);
const Color _kLabelColor = Colors.blueGrey;

class DebtRegisterScreen extends StatelessWidget {
  DebtRegisterScreen({super.key});

  // ผูก Controller เข้ากับ View
  final DebtRegisterController controller = Get.put(DebtRegisterController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'สมัครบัญชีลูกหนี้',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileImageUploader(),
            const SizedBox(height: 28),

            _buildSectionCard(
              icon: Icons.badge_outlined,
              title: 'ข้อมูลลูกหนี้',
              children: [
                _buildTextField(
                  label: 'ชื่อคนค้างชำระ',
                  hint: 'เช่น นายสมชาย',
                  icon: Icons.person_outline,
                  controller: controller.nameController,
                ),
                const SizedBox(height: 16),
                Obx(
                  () => _buildTextField(
                    label: 'เบอร์โทรศัพท์',
                    hint: '08XXXXXXXX',
                    icon: Icons.call_outlined,
                    controller: controller.phoneController,
                    keyboardType: TextInputType.phone,
                    errorText: controller.phoneError.value,
                    onChanged: controller.onPhoneChanged,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildSectionCard(
              icon: Icons.location_on_outlined,
              title: 'ที่อยู่',
              children: [
                Obx(() {
                  if (controller.fullAddressData.value == null) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: LinearProgressIndicator(
                        color: _kPrimaryColor,
                        backgroundColor: _kFieldFillColor,
                      ),
                    );
                  }

                  final List<String> provinces = controller
                      .fullAddressData
                      .value!
                      .keys
                      .toList();
                  return Column(
                    children: [
                      _buildAddressDropdown(
                        hint: 'จังหวัด',
                        selectedValue: controller.selectedProvince.value,
                        items: provinces,
                        onChanged: controller.onProvinceChanged,
                      ),
                      const SizedBox(height: 12),
                      _buildAddressDropdown(
                        hint: 'อำเภอ/เขต',
                        selectedValue: controller.selectedDistrict.value,
                        items: controller.districts,
                        onChanged: controller.onDistrictChanged,
                        disabled: controller.selectedProvince.value == null,
                      ),
                      const SizedBox(height: 12),
                      _buildAddressDropdown(
                        hint: 'ตำบล/แขวง',
                        selectedValue: controller.selectedSubdistrict.value,
                        items: controller.subdistricts,
                        onChanged: (v) =>
                            controller.selectedSubdistrict.value = v,
                        disabled: controller.selectedDistrict.value == null,
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'บ้านเลขที่ / ซอย / ถนน',
                  hint: 'เช่น 99/1 ถ.สุขุมวิท',
                  icon: Icons.home_outlined,
                  controller: controller.addressDetailController,
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildSectionCard(
              icon: Icons.account_balance_wallet_outlined,
              title: 'วงเงินค้างชำระ',
              children: [
                _buildTextField(
                  label: 'วงเงินค้างชำระ',
                  hint: '0.00',
                  icon: Icons.payments_outlined,
                  suffixText: 'บาท',
                  controller: controller.creditLimitController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            _buildSubmitButton(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // --- Reusable Widgets ---

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _kPrimaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _kPrimaryColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text.rich(
                TextSpan(
                  text: title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _kLabelColor,
                  ),
                  children: const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? errorText,
    String? suffixText,
    ValueChanged<String>? onChanged,
  }) {
    final bool hasError = errorText != null && errorText.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kLabelColor,
            ),
            children: const [
              TextSpan(
                text: ' *',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 15, color: _kTextColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(
              icon,
              size: 20,
              color: hasError ? _kErrorColor : Colors.grey.shade500,
            ),
            suffixText: suffixText,
            suffixStyle: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
            errorText: errorText,
            errorStyle: const TextStyle(fontSize: 12, color: _kErrorColor),
            filled: true,
            fillColor: _kFieldFillColor,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? _kErrorColor : _kBorderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? _kErrorColor : _kPrimaryColor,
                width: 1.6,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kErrorColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kErrorColor, width: 1.6),
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
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: disabled ? Colors.grey.shade100 : _kFieldFillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorderColor),
      ),
      child: Row(
        children: [
          Icon(
            Icons.map_outlined,
            size: 18,
            color: disabled ? Colors.grey.shade400 : Colors.grey.shade500,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: disabled ? Colors.grey.shade400 : _kPrimaryColor,
                ),
                hint: Text(
                  hint,
                  style: TextStyle(
                    color: disabled ? Colors.grey : Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                value: selectedValue,
                onChanged: disabled ? null : onChanged,
                items: items
                    .map(
                      (val) => DropdownMenuItem(
                        value: val,
                        child: Text(val, style: const TextStyle(fontSize: 14)),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageUploader() {
    return Center(
      child: GestureDetector(
        onTap: controller.showImagePickerOptions,
        child: Column(
          children: [
            Obx(() {
              final bytes = controller.imageBytes.value;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 124,
                    height: 124,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kFieldFillColor,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      image: bytes != null
                          ? DecorationImage(
                              image: MemoryImage(bytes),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: bytes == null
                        ? Icon(
                            Icons.person_outline_rounded,
                            size: 52,
                            color: _kPrimaryColor.withValues(alpha: 0.4),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 2,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _kPrimaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                text: 'แตะเพื่อเพิ่มรูปภาพลูกหนี้',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                children: const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _kSuccessColor.withValues(alpha: 0.32),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        height: 56,
        child: ElevatedButton.icon(
          onPressed: controller
              .submitDebtorData, // เรียกฟังก์ชันจาก Controller ได้โดยตรง
          icon: const Icon(Icons.check_circle_outline, color: Colors.white),
          label: const Text(
            'บันทึกข้อมูลลูกหนี้',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kSuccessColor,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
