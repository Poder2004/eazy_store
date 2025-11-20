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
        selectedLabelStyle: const TextStyle(fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        showUnselectedLabels: true,
        currentIndex: currentIndex,
        onTap: onTap,
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'หน้าหลัก',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            label: 'บัญชี',
          ),
          BottomNavigationBarItem(
            // ใช้ Image.asset ในกรณีที่ต้องการ icon พิเศษ
            icon: Image.asset(
              'assets/qr_scanner_icon.png', // เปลี่ยนเป็น path ไอคอนที่ถูกต้อง
              height: 24,
              width: 24,
              color: currentIndex == 2 ? _kActiveColor : _kInactiveColor,
            ),
            label: 'สแกนชำระ',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            label: 'คนค้างชำระ',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'ตั้งค่า',
          ),
        ],
      ),
    );
  }
}