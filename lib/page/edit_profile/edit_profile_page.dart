import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'edit_profile_controller.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  final Color primaryColor = const Color(0xFF4F46E5);
  final Color bgColor = const Color(0xFFF4F7FA);
  final Color textColor = const Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    final EditProfileController controller = Get.put(EditProfileController());

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () =>
            FocusScope.of(context).unfocus(), // กดพื้นที่ว่างเพื่อซ่อนคีย์บอร์ด
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              // --- กล่องข้อมูลส่วนตัว ---
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("ข้อมูลส่วนตัว"),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: controller.usernameCtrl,
                      label: "ชื่อผู้ใช้งาน (Username)",
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: controller.phoneCtrl,
                      label: "เบอร์โทรศัพท์",
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                    ),

                    _buildSectionTitle("บัญชีและความปลอดภัย"),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: controller.emailCtrl,
                      label: "อีเมล",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      helperText:
                          "* หากเปลี่ยนอีเมล ระบบจะส่งรหัสไปให้ยืนยันใหม่",
                    ),
                    const SizedBox(height: 16),

                    // ✨ ช่องรหัสผ่าน โยน controller หลักเข้าไปเพื่อให้ปุ่มตาทำงานได้
                    _buildTextField(
                      controller: controller.passwordCtrl,
                      label: "รหัสผ่านใหม่",
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      mainController: controller,
                      helperText: "* เว้นว่างไว้หากไม่ต้องการเปลี่ยนรหัสผ่าน",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // --- ปุ่มบันทึกข้อมูล ---
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    // ✨ เรียกฟังก์ชันถามยืนยันก่อนบันทึก
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.confirmSaveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      disabledBackgroundColor: primaryColor.withOpacity(0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? const SizedBox(
                            width: 24,
                            height: 24,
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
                              color: Colors.white,
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

  // ✨ Widget สร้างหัวข้อ
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

  // ✨ Widget สร้าง TextFormField
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? helperText,
    EditProfileController? mainController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey.shade400,
          ),
        ),
        const SizedBox(height: 8),

        // 🔥 แยกเงื่อนไข ถ้าเป็นรหัสผ่านถึงจะใช้ Obx เพื่อให้สลับเปิดปิดตาได้
        if (isPassword && mainController != null)
          Obx(
            () => _buildInputForm(
              controller: controller,
              icon: icon,
              keyboardType: keyboardType,
              isObscure:
                  mainController.isPasswordHidden.value, // ดึงค่าจากตัวแปร
              suffixIcon: IconButton(
                icon: Icon(
                  mainController.isPasswordHidden.value
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.blueGrey.shade400,
                  size: 20,
                ),
                onPressed: mainController.togglePasswordVisibility, // กดสลับตา
              ),
            ),
          )
        else
          // ถ้าไม่ใช่รหัสผ่าน ไม่ต้องมี Obx เพื่อแก้ปัญหา GetX Error
          _buildInputForm(
            controller: controller,
            icon: icon,
            keyboardType: keyboardType,
            isObscure: false,
            suffixIcon: null,
          ),

        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText,
            style: TextStyle(
              fontSize: 11,
              color: isPassword
                  ? Colors.blueGrey.shade300
                  : const Color(0xFFF59E0B),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  // ✨ Widget ย่อยสำหรับโครงสร้าง Input
  Widget _buildInputForm({
    required TextEditingController controller,
    required IconData icon,
    required TextInputType keyboardType,
    required bool isObscure,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1E293B),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        prefixIcon: Icon(icon, color: Colors.blueGrey.shade400, size: 20),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
        ),
      ),
    );
  }
}
