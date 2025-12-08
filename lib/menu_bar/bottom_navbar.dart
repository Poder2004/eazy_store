// File: lib/widgets/bottom_nav_bar.dart

import 'package:eazy_store/homepage/home_page.dart';
import 'package:eazy_store/page/debt_ledger.dart';
import 'package:eazy_store/page/sales_account.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';

// กำหนดสีหลักที่ใช้ในแอปพลิเคชัน
const Color _kInactiveColor = Color(0xFF999999);
const Color _kActiveColor = Colors.black;

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1.0)),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: _kActiveColor,
        unselectedItemColor: _kInactiveColor,
        currentIndex: currentIndex,

        onTap: (index) {
          onTap(index);

          if (index == 0) {
            Get.to(() => const HomePage());
          } else if (index == 1) {
            Get.to(() => const SalesAccountScreen());
          } else if (index == 2) {
            // Get.to(() => const ScanPage());
          } else if (index == 3) {
            Get.to(() => const DebtLedgerScreen());
          } else if (index == 4) {
            // Get.to(() => const SettingsPage());
          }
        },

        items: [
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/image/icon_home.png',
              height: 24,
              width: 24,
              color: currentIndex == 0 ? _kActiveColor : _kInactiveColor,
            ),
            label: 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/image/icon_check_book.png',
              height: 24,
              width: 24,
              color: currentIndex == 1 ? _kActiveColor : _kInactiveColor,
            ),
            label: 'บัญชี',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/image/icon_barcode.png',
              height: 24,
              width: 24,
              color: currentIndex == 2 ? _kActiveColor : _kInactiveColor,
            ),
            label: 'สแกนชำระ',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/image/icon_debt.png',
              height: 24,
              width: 24,
              color: currentIndex == 3 ? _kActiveColor : _kInactiveColor,
            ),
            label: 'คนค้างชำระ',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/image/icon_settings.png',
              height: 24,
              width: 24,
              color: currentIndex == 4 ? _kActiveColor : _kInactiveColor,
            ),
            label: 'ตั้งค่า',
          ),
        ],
      ),
    );
  }
}
