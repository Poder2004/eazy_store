import 'package:eazy_store/homepage/home_page.dart';
import 'package:eazy_store/page/debt_ledger.dart';
import 'package:eazy_store/page/sales_account.dart';
import 'package:eazy_store/sale_producct/checkout_page.dart'; // ✅ เพิ่ม Import CheckoutPage
import 'package:eazy_store/sale_producct/scan_barcode.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// กำหนดสีหลักที่ใช้ในแอปพลิเคชัน
const Color primaryColor = Color(0xFFC0392B);
const Color surfaceLight = Color(0xFFFFFFFF);
const Color surfaceDark = Color(0xFF1F2937);

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final Function(int) onTap;

  // --- Utility Widgets สำหรับสร้างแต่ละปุ่ม ---

  // Widget สำหรับปุ่มเมนูทั่วไป
  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    bool isDarkMode,
  ) {
    final bool isActive = currentIndex == index;
    final Color activeColor = isDarkMode ? primaryColor : primaryColor;
    final Color inactiveColor = Colors.grey.shade400;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          onTap(index);
          _navigateToPage(index);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : inactiveColor,
              size: isActive ? 28 : 24, // ปรับขนาดเมื่อ Active
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget สำหรับปุ่มสแกนตรงกลาง (ยกขึ้น)
  Widget _buildScanButton(bool isDarkMode) {
    const int index = 2; // Index สำหรับปุ่มสแกน

    return Expanded(
      child: Transform.translate(
        offset: const Offset(0, -20), // ยกปุ่มขึ้น
        child: GestureDetector(
          onTap: () async {
            // ✅ เปลี่ยนเป็น async เพื่อรอรับค่า
            // 1. เรียกหน้าสแกน และ "รอ" (await) ผลลัพธ์
            var barcode = await Get.to(() => const ScanBarcodePage());

            // 2. ถ้าสแกนเจอ (barcode ไม่เป็น null)
            if (barcode != null && barcode is String) {
              // 3. ไปหน้า CheckoutPage และส่ง barcode ไปด้วยผ่าน arguments
              Get.to(
                () => const CheckoutPage(),
                arguments: {'barcode': barcode}, // 📦 ฝากบาร์โค้ดไป
              );
              // อัปเดต index ของ Navbar ให้เป็นหน้า Checkout (ถ้า CheckoutPage เป็น index 2)
              onTap(index);
            } else {
              // กรณีไม่ได้สแกน หรือกดกลับเฉยๆ อาจจะเลือกให้ไปหน้า Checkout เปล่าๆ หรืออยู่ที่เดิม
              // ในที่นี้ถ้ากดปุ่มสแกนตรงกลางแต่ไม่ได้สแกนอะไร อาจจะอยากให้ไปหน้า Checkout เปล่าๆ ก็ได้
              // Get.to(() => const CheckoutPage());
              // onTap(index);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.grey.shade600
                      : Colors.grey.shade800,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDarkMode ? surfaceDark : surfaceLight,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'สแกนชำระ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Logic สำหรับการนำทาง
  void _navigateToPage(int index) {
    if (index == 0) {
      Get.to(() => const HomePage());
    } else if (index == 1) {
      Get.to(() => const SalesAccountScreen());
    }
    // index == 2 จัดการใน onTap ของ _buildScanButton แล้ว
    else if (index == 3) {
      Get.to(() => const DebtLedgerScreen());
    } else if (index == 4) {
      // Get.to(() => const SettingsPage());
    }
  }

  // --- Widget build หลัก ---

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color surfaceColor = isDarkMode ? surfaceDark : surfaceLight;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        // เพิ่มมุมโค้งด้านบน
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -5),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
          ),
        ),
      ),
      padding: const EdgeInsets.only(
        top: 12.0,
        bottom: 24.0,
        left: 16.0,
        right: 16.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'หน้าหลัก', 0, isDarkMode),
          _buildNavItem(Icons.receipt_long, 'บัญชี', 1, isDarkMode),
          _buildScanButton(isDarkMode), // ปุ่มสแกนตรงกลาง
          _buildNavItem(Icons.person, 'คนค้างชำระ', 3, isDarkMode),
          _buildNavItem(
            Icons.account_circle_outlined,
            'โปรไฟล์',
            4,
            isDarkMode,
          ),
        ],
      ),
    );
  }
}
