import 'package:eazy_store/page/menu_bar/bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'profile_controller.dart'; // ✅ Import Controller ที่แยกไว้

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  final Color primaryColor = const Color(0xFF4F46E5);
  final Color dangerColor = const Color(0xFFE11D48);
  final Color bgColor = const Color(0xFFF4F7FA);

  @override
  Widget build(BuildContext context) {
    // ✅ เรียกใช้งาน Controller
    final ProfileController controller = Get.put(ProfileController());

    // 🔥 โหลดข้อมูลใหม่ทุกครั้งที่เปิดหน้า เผื่อมีการสลับร้าน
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadProfileData();
    });

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ActionChip(
              avatar: Icon(Icons.edit_rounded, size: 16, color: primaryColor),
              label: Text(
                'Edit',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: primaryColor.withOpacity(0.1),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: controller.goToEditProfile, // ✅ ผูกฟังก์ชัน
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.loadProfileData, // ดึงจอลงเพื่อโหลดข้อมูลใหม่ได้
        color: primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(controller),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CURRENT STORE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.blueGrey.shade400,
                      letterSpacing: 1.2,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: controller.switchStore,
                    icon: Icon(
                      Icons.swap_vert_rounded,
                      size: 18,
                      color: primaryColor,
                    ),
                    label: Text(
                      'Switch Store',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: primaryColor.withOpacity(
                        0.05,
                      ), // มีพื้นหลังจางๆ
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStoreCard(controller),
              const SizedBox(height: 36),
              Text(
                'PREFERENCES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.blueGrey.shade400,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              _buildActionMenu(controller),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 4, onTap: (index) {}),
    );
  }

  Widget _buildProfileHeader(ProfileController controller) {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [primaryColor, const Color(0xFF38BDF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Obx(
                () => CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFF1E293B),
                  // ✨ ถ้ามี URL รูปภาพให้โชว์รูป
                  backgroundImage: controller.userImage.value.isNotEmpty
                      ? NetworkImage(controller.userImage.value)
                      : null,
                  // ✨ ถ้าไม่มีรูปภาพให้โชว์ตัวย่อชื่อ
                  child: controller.userImage.value.isEmpty
                      ? Text(
                          controller.userInitials.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  shape: BoxShape.circle,
                  border: Border.all(color: bgColor, width: 3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(
                () => Text(
                  controller.userName.value, // ✅ ดึงชื่อจริงมาแสดง
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade100.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Obx(
                  () => Text(
                    controller.userRole.value, // ✅ ดึงตำแหน่ง
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStoreCard(ProfileController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Obx(
                () => Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(14),
                    // ✨ ถ้าร้านมี URL รูปภาพให้โชว์เป็นพื้นหลัง
                    image: controller.shopImage.value.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(controller.shopImage.value),
                            fit: BoxFit.cover,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  // ✨ ถ้าไม่มีรูปร้านให้โชว์ตัวอักษรแทน
                  child: controller.shopImage.value.isEmpty
                      ? Text(
                          controller.shopName.value.length >= 2
                              ? controller.shopName.value
                                    .substring(0, 2)
                                    .toUpperCase()
                              : "SH",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                      () => Text(
                        controller.shopName.value, // ✅ ดึงชื่อร้านค้า
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: Colors.blueGrey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Obx(
                            () => Text(
                              controller
                                  .shopAddress
                                  .value, // ✅ ดึงที่อยู่ร้านค้า
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blueGrey.shade500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 🔥 Stat Card แสดงยอดขายวันนี้ผ่าน API
          Obx(() {
            if (controller.isSalesLoading.value) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return _buildStatCard(
              icon: Icons.auto_graph_rounded,
              title: 'Today Sales',
              value: '฿${controller.todaySales.value}', // ✅ ยอดขายจาก API
              iconColor: const Color(0xFF10B981),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.1), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionMenu(ProfileController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100), // ใส่เส้นขอบบางๆ
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuTile(
            icon: Icons.store_rounded,
            title: 'Manage Stores',
            subtitle: 'แก้ไขข้อมูลหรือเพิ่มสาขาใหม่',
            iconColor: const Color(0xFF6366F1),
            onTap: controller.goToManageStores,
          ),
          _buildDivider(),
          _buildMenuTile(
            icon: Icons.shield_moon_rounded,
            title: 'Security & Password',
            subtitle: 'ความปลอดภัยและสิทธิ์การเข้าถึง',
            iconColor: const Color(0xFFF59E0B),
            onTap: controller.goToSecurity,
          ),
          _buildDivider(),
          _buildMenuTile(
            icon: Icons.headset_mic_rounded,
            title: 'Help & Support',
            subtitle: 'ศูนย์ช่วยเหลือและแจ้งปัญหาการใช้งาน',
            iconColor: const Color(0xFF10B981),
            onTap: controller.goToSupport,
          ),
          _buildDivider(),
          // Logout Menu (เน้นสีแดงเฉพาะจุด)
          _buildMenuTile(
            icon: Icons.logout_rounded,
            title: 'Sign Out',
            subtitle: 'ออกจากบัญชีผู้ใช้ปัจจุบัน',
            iconColor: const Color(0xFFE11D48),
            onTap: controller.logout,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  // ตัวคั่นที่ดู Clean
  Widget _buildDivider() =>
      Divider(height: 1, color: Colors.grey.shade50, indent: 70);

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDestructive
              ? const Color(0xFFE11D48)
              : const Color(0xFF1E293B),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade300),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Colors.grey.shade300,
        size: 20,
      ),
    );
  }
}
