// File: lib/widgets/bottom_nav_bar.dart

import 'package:flutter/material.dart';

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
        selectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold, 
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold, 
        ),
        showUnselectedLabels: true,
        currentIndex: currentIndex,
        onTap: onTap,
        items: <BottomNavigationBarItem>[
          // 1. หน้าหลัก (icon_home.png)
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/image/icon_home.png',
              height: 24,
              width: 24,
              color: currentIndex == 0 ? _kActiveColor : _kInactiveColor,
            ),
            label: 'หน้าหลัก',
          ),

          // 2. บัญชี (icon_check_book.png) - สันนิษฐานว่าใช้แทน Icons.description_outlined
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/image/icon_check_book.png',
              height: 24,
              width: 24,
              color: currentIndex == 1 ? _kActiveColor : _kInactiveColor,
            ),
            label: 'บัญชี',
          ),

          // 3. สแกนชำระ (icon_barcode.png) - ใช้แทน 'assets/qr_scanner_icon.png' เดิม
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/image/icon_barcode.png',
              height: 24,
              width: 24,
              color: currentIndex == 2 ? _kActiveColor : _kInactiveColor,
            ),
            label: 'สแกนชำระ',
          ),

          // 4. คนค้างชำระ (icon_debt.png) - สันนิษฐานว่าใช้แทน Icons.people_alt_outlined
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/image/icon_debt.png',
              height: 24,
              width: 24,
              color: currentIndex == 3 ? _kActiveColor : _kInactiveColor,
            ),
            label: 'คนค้างชำระ',
          ),

          // 5. ตั้งค่า (icon_settings.png)
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
