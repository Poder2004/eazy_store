import 'package:eazy_store/page/homepage/home_page.dart';
import 'package:eazy_store/page/debt/debtLedger/debt_ledger.dart';
import 'package:eazy_store/page/my_blank/sales_account.dart'; // ตรวจสอบ path นี้ให้ตรงด้วยนะครับ
import 'package:eazy_store/page/my_blank/sales_account_controller.dart';
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
              size: isActive ? 28 : 24,
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

  Widget _buildScanButton(bool isDarkMode) {
    const int index = 2;
    return Expanded(
      child: Transform.translate(
        offset: const Offset(0, -20),
        child: GestureDetector(
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color surfaceColor = isDarkMode ? surfaceDark : surfaceLight;
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'หน้าหลัก', 0, isDarkMode),
          _buildNavItem(Icons.receipt_long, 'บัญชี', 1, isDarkMode),
          _buildScanButton(isDarkMode),
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
