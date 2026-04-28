import 'package:eazy_store/page/homepage/home_page.dart';
import 'package:eazy_store/page/debt/debtLedger/debt_ledger.dart';
import 'package:eazy_store/page/my_blank/sales_account.dart'; // ตรวจสอบ path นี้ให้ตรงด้วยนะครับ
import 'package:eazy_store/page/my_blank/sales_account_controller.dart';
import 'package:eazy_store/page/profile/profile_page.dart';
import 'package:eazy_store/page/sale_producct/sale/checkout_controller.dart';
import 'package:eazy_store/page/sale_producct/sale/checkout_page.dart';
import 'package:eazy_store/page/sale_producct/scanBarcode/scan_barcode.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  Widget _buildNavItem(
    BuildContext context, // เพิ่ม BuildContext
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
        behavior: HitTestBehavior.opaque, // ทำให้พื้นที่ว่างรอบๆ ไอคอนกดติดได้
        onTap: () {
          onTap(index);
          _navigateToPage(index);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end, // จัดให้อยู่ด้านล่างเสมอ
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : inactiveColor,
              size: isActive ? 28 : 24,
            ),
            const SizedBox(height: 4),
            // ✨ ใช้ Flexible + FittedBox เพื่อย่อขนาดตัวหนังสืออัตโนมัติเมื่อเจอฟอนต์ใหญ่
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? activeColor : inactiveColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanButton(BuildContext context, bool isDarkMode) {
    const int index = 2;
    return Expanded(
      child: Transform.translate(
        offset: const Offset(0, -20),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            var barcode = await Get.to(() => const ScanBarcodePage());

            if (barcode != null && barcode is String) {
              CheckoutController ctrl;
              try {
                ctrl = Get.find<CheckoutController>();
              } catch (e) {
                ctrl = Get.put(CheckoutController());
              }

              if (Get.currentRoute != '/CheckoutPage') {
                Get.to(() => const CheckoutPage());
              }

              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await ctrl.checkShopAndLoadData();

                // 🔥 เพิ่มบรรทัดนี้: ล้างความจำเก่าและดึงข้อมูลใหม่จาก Database ก่อนสแกนเสมอ
                await ctrl.fetchFreshProducts();

                ctrl.addProductByBarcode(barcode);
              });

              onTap(index);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end, // จัดให้อยู่ด้านล่าง
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
              // ✨ ใช้ Flexible + FittedBox ป้องกันคำว่า 'สแกนขาย' แตกหรือตกบรรทัด
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'สแกนขาย',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPage(int index) {
    if (index == 0) {
      Get.to(() => const HomePage());
    } else if (index == 1) {
      // 🔥 รีเซ็ตวันที่ให้กลับมาเป็น "ปัจจุบัน" ทุกครั้งที่กดเข้าหน้าบัญชี
      if (Get.isRegistered<SalesAccountController>()) {
        final ctrl = Get.find<SalesAccountController>();
        ctrl.selectedView.value = 'วันนี้'; // กลับมาหน้าวัน
        ctrl.currentDate.value = DateTime.now(); // กลับมาใช้วันนี้
        ctrl.fetchSummaryData(); // ดึงข้อมูลใหม่
      }
      Get.to(() => const SalesAccountScreen());
    } else if (index == 3) {
      Get.to(() => DebtLedgerScreen());
    } else if (index == 4) {
      Get.to(() => const ProfilePage());
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color surfaceColor = isDarkMode ? surfaceDark : surfaceLight;

    // ✨ ครอบ MediaQuery ไว้ชั้นนอกสุดของเมนู เพื่อควบคุมฟอนต์ไม่ให้ใหญ่ทะลุจอ
    // ให้ขยายได้สูงสุดแค่ 1.2 เท่า เพื่อรักษาความสวยงามและไม่กินพื้นที่เนื้อหา
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: MediaQuery.textScalerOf(
          context,
        ).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.2),
      ),
      child: Container(
        // ✨ ใส่ Clip.none เพื่อไม่ให้ปุ่มสแกนขายที่ลอยขึ้นไปโดนตัดขอบทิ้ง
        clipBehavior: Clip.none,
        decoration: BoxDecoration(
          color: surfaceColor, // พื้นหลังของ Navbar จะยาวลงไปสุดขอบจอด้านล่าง
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
        // ✨ ห่อเนื้อหาด้านในด้วย SafeArea(bottom: true)
        // ตัวนี้จะเป็นตัวดันปุ่มเมนูให้หลบขึ้นมาจากแถบ Home/Back บนจอ Android รุ่นเก่า
        // รวมถึงเส้นขีดด้านล่างของ iPhone โดยอัตโนมัติ
        child: SafeArea(
          bottom: true,
          top: false,
          child: Padding(
            // เปลี่ยนจาก (16, 12, 16, 24) เป็น (10, 12, 10, 12) เพราะ SafeArea ดันขอบล่างให้แล้ว
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment:
                  CrossAxisAlignment.end, // ให้ไอคอนทุกตัวเรียงฐานเท่ากัน
              children: [
                _buildNavItem(context, Icons.home, 'หน้าหลัก', 0, isDarkMode),
                _buildNavItem(
                  context,
                  Icons.receipt_long,
                  'บัญชี',
                  1,
                  isDarkMode,
                ),
                _buildScanButton(context, isDarkMode),
                _buildNavItem(
                  context,
                  Icons.person,
                  'คนค้างชำระ',
                  3,
                  isDarkMode,
                ),
                _buildNavItem(
                  context,
                  Icons.account_circle_outlined,
                  'โปรไฟล์',
                  4,
                  isDarkMode,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
