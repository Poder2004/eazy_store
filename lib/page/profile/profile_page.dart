import 'package:eazy_store/page/menu_bar/bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'profile_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.put(ProfileController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadProfileData();
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: MediaQuery.textScalerOf(
            context,
          ).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.2),
        ),
        child: RefreshIndicator(
          onRefresh: controller.loadProfileData,
          color: const Color.fromARGB(255, 167, 163, 248),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(controller)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 16),
                    _buildStoreCard(controller),
                    const SizedBox(height: 24),

                    // ── หมวด: บัญชีของฉัน ──────────────────────────────
                    _buildSectionHeader('บัญชีของฉัน', Icons.person_outline_rounded),
                    const SizedBox(height: 10),
                    _buildMenuGroup([
                      _MenuItem(
                        icon: Icons.edit_rounded,
                        iconColor: const Color(0xFF4F46E5),
                        title: 'แก้ไขข้อมูลส่วนตัว',
                        subtitle: 'เปลี่ยนชื่อ อีเมล และเบอร์โทรศัพท์',
                        onTap: controller.goToEditProfile,
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // ── หมวด: ร้านค้า ───────────────────────────────────
                    _buildSectionHeader('ร้านค้า', Icons.store_outlined),
                    const SizedBox(height: 10),
                    _buildMenuGroup([
                      _MenuItem(
                        icon: Icons.store_rounded,
                        iconColor: const Color(0xFF6366F1),
                        title: 'จัดการร้านค้า',
                        subtitle: 'แก้ไขข้อมูลร้าน ที่อยู่ และรูปภาพ',
                        onTap: controller.goToManageStores,
                      ),
                      _MenuItem(
                        icon: Icons.swap_horiz_rounded,
                        iconColor: const Color(0xFF0EA5E9),
                        title: 'สลับสาขา / ร้านค้า',
                        subtitle: 'เปลี่ยนไปใช้งานร้านค้าหรือสาขาอื่น',
                        onTap: controller.switchStore,
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // ── หมวด: ความช่วยเหลือ ─────────────────────────────
                    _buildSectionHeader('ความช่วยเหลือ', Icons.support_agent_outlined),
                    const SizedBox(height: 10),
                    _buildMenuGroup([
                      _MenuItem(
                        icon: Icons.contact_support_rounded,
                        iconColor: const Color(0xFF059669),
                        title: 'ติดต่อทีมงาน',
                        subtitle: 'LINE, Facebook, อีเมล และโทรศัพท์',
                        onTap: controller.goToContact,
                      ),
                      _MenuItem(
                        icon: Icons.headset_mic_rounded,
                        iconColor: const Color(0xFF10B981),
                        title: 'ศูนย์ช่วยเหลือ',
                        subtitle: 'คำถามที่พบบ่อย และแจ้งปัญหาการใช้งาน',
                        onTap: controller.goToSupport,
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // ── หมวด: ข้อมูลและกฎหมาย ──────────────────────────
                    _buildSectionHeader('ข้อมูลและกฎหมาย', Icons.gavel_outlined),
                    const SizedBox(height: 10),
                    _buildMenuGroup([
                      _MenuItem(
                        icon: Icons.policy_rounded,
                        iconColor: const Color(0xFF8B5CF6),
                        title: 'นโยบายความเป็นส่วนตัว',
                        subtitle: 'ข้อมูลที่เราเก็บและวิธีการใช้งาน',
                        onTap: controller.goToPrivacyPolicy,
                      ),
                      _MenuItem(
                        icon: Icons.description_rounded,
                        iconColor: const Color(0xFF64748B),
                        title: 'เงื่อนไขการใช้งาน',
                        subtitle: 'ข้อตกลงและเงื่อนไขการใช้แอพ',
                        onTap: controller.goToTerms,
                      ),
                    ]),

                    const SizedBox(height: 28),

                    // ── ปุ่มออกจากระบบ ──────────────────────────────────
                    _buildLogoutButton(controller),

                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'EazyStore v1.0.0',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey.shade300,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 4, onTap: (index) {}),
    );
  }

  // ══════════════════════════════════════════════════════
  // Header — gradient banner + รูปโปรไฟล์ + ชื่อ + ปุ่มแก้ไข
  // ══════════════════════════════════════════════════════
  Widget _buildHeader(ProfileController controller) {
    return Stack(
      children: [
        Container(
          height: 210,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6B9FFF), Color(0xFF8B52FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 44),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // รูปโปรไฟล์
                Obx(
                  () => Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: const Color(0xFF7C3AED),
                      backgroundImage: controller.userImage.value.isNotEmpty
                          ? NetworkImage(controller.userImage.value)
                          : null,
                      child: controller.userImage.value.isEmpty
                          ? Text(
                              controller.userInitials.value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // ชื่อ + ตำแหน่ง
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(
                        () => Text(
                          controller.userName.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Obx(
                        () => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            controller.userRole.value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════
  // Card ข้อมูลร้านค้าปัจจุบัน + ยอดขายวันนี้
  // ══════════════════════════════════════════════════════
  Widget _buildStoreCard(ProfileController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B9FFF), Color(0xFF8B52FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    image: controller.shopImage.value.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(controller.shopImage.value),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ร้านค้าปัจจุบัน',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Obx(
                      () => Text(
                        controller.shopName.value,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Obx(
                      () => Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: Colors.blueGrey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              controller.shopAddress.value,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey.shade400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.isSalesLoading.value) {
              return const Center(
                child: SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            return InkWell(
              onTap: controller.goToSalesReport,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_graph_rounded,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ยอดขายวันนี้',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '฿${controller.todaySales.value}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade300,
                    size: 22,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // หัวข้อหมวดเมนู
  // ══════════════════════════════════════════════════════
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.blueGrey.shade400),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.blueGrey.shade400,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════
  // กล่องรวมเมนูในหมวดเดียวกัน
  // ══════════════════════════════════════════════════════
  Widget _buildMenuGroup(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _buildMenuTile(items[i]),
            if (i < items.length - 1)
              Divider(
                height: 1,
                color: Colors.grey.shade50,
                indent: 64,
                endIndent: 16,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuTile(_MenuItem item) {
    return ListTile(
      onTap: item.onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: item.iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(item.icon, color: item.iconColor, size: 22),
      ),
      title: Text(
        item.title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          item.subtitle,
          style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade400),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Colors.grey.shade300,
        size: 22,
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // ปุ่มออกจากระบบ — แยกออกมาให้เห็นชัด
  // ══════════════════════════════════════════════════════
  Widget _buildLogoutButton(ProfileController controller) {
    return InkWell(
      onTap: controller.logout,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFCDD5), width: 1.5),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFE11D48), size: 20),
            SizedBox(width: 10),
            Text(
              'ออกจากระบบ',
              style: TextStyle(
                color: Color(0xFFE11D48),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
