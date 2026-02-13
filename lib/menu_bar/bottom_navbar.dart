import 'package:eazy_store/homepage/home_page.dart';
import 'package:eazy_store/page/debt_ledger.dart';
import 'package:eazy_store/page/sales_account.dart';
import 'package:eazy_store/sale_producct/checkout_page.dart'; // ✅ Import
import 'package:eazy_store/sale_producct/scan_barcode.dart';
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
            // 1. ไปหน้าสแกน รอรับค่าบาร์โค้ด
            var barcode = await Get.to(() => const ScanBarcodePage());

            if (barcode != null && barcode is String) {
              // ✅ 2. หา Controller (หรือสร้างใหม่ถ้ายังไม่มี)
              CheckoutController ctrl;
              try {
                ctrl = Get.find<CheckoutController>();
              } catch (e) {
                ctrl = Get.put(CheckoutController());
              }

              // ✅ 3. ไปหน้า Checkout (ถ้ายังไม่อยู่)
              if (Get.currentRoute != '/CheckoutPage') {
                // ใช้ Get.to หรือ Get.off ตามความเหมาะสม
                Get.to(() => const CheckoutPage());
              }

              // ✅ 4. สั่ง Controller ทำงานโดยตรง (แก้ปัญหาสแกนซ้ำไม่ติด)
              // รอให้หน้าจอพร้อมก่อนค่อยสั่ง
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await ctrl.checkShopAndLoadData(); // เช็คก่อนว่าร้านเปลี่ยนไหม
                ctrl.addProductByBarcode(barcode); // เพิ่มสินค้า
              });

              onTap(index); // อัปเดต tab เป็นหน้า Checkout
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
    if (index == 0)
      Get.to(() => const HomePage());
    else if (index == 1)
      Get.to(() => const SalesAccountScreen());
    else if (index == 3)
      Get.to(() => const DebtLedgerScreen());
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
