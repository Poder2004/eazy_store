import 'package:eazy_store/menu_bar/bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

// --- THEME & CONSTANTS ---
const Color _kPrimaryColor = Color(0xFF6B8E23); // สีเขียวมะกอก/ทหาร (สำหรับกำไรและไฮไลท์)
const Color _kBackgroundColor = Color(0xFFF7F7F7); // สีพื้นหลังอ่อน (ภายนอกการ์ด)
const Color _kCardColor = Colors.white; // สีพื้นหลังของการ์ดสรุป
const Color _kHighlightColor = Color(0xFFE5F5D0); // สีพื้นหลังอ่อน (สำหรับแถบสลับและกำไร)
const Color _kProfitColor = Color(0xFF1E9D42); // สีเขียวสำหรับกำไร
const Color _kIncomeColor = Color(0xFF333333); // สีเข้มสำหรับยอดขาย/ต้นทุน

// ----------------------------

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Eazy Store Account',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const AccountScreen(),
    );
  }
}

// --- DATA MODEL (Mock Data) ---
class AccountSummary {
  final String period;
  final double income; // ยอดขาย
  final double cost;   // ต้นทุน
  
  double get profit => income - cost; // กำไร = ยอดขาย - ต้นทุน

  const AccountSummary({
    required this.period,
    required this.income,
    required this.cost,
  });
}

// Mock Data
final Map<String, AccountSummary> _kMockData = {
  'วัน': const AccountSummary(period: '11 เมษายน 2025', income: 1250, cost: 800),
  'เดือน': const AccountSummary(period: 'เมษายน', income: 15600, cost: 10000),
  'ปี': const AccountSummary(period: '2025', income: 187200, cost: 121000),
};

// ----------------------------

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String _selectedView = 'วัน'; // สถานะปัจจุบัน: 'วัน', 'เดือน', 'ปี'
  int _selectedIndex = 1; // Index 1 คือ "บัญชี" ใน BottomNavBar

  // 🔄 ฟังก์ชันสำหรับจัดการการแตะที่ Bottom Navigation Bar (ที่หายไป)
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    print('Tab tapped: $index');
  }

  // 🔄 เปลี่ยนมุมมองการแสดงผล (วัน/เดือน/ปี)
  void _selectView(String view) {
    setState(() {
      _selectedView = view;
    });
  }
  
  // 💰 ดึงข้อมูลสรุปตามมุมมองปัจจุบัน
  AccountSummary _getCurrentSummary() {
    return _kMockData[_selectedView] ?? _kMockData['วัน']!;
  }
  
  // ⬅️➡️ จัดการการเปลี่ยนช่วงเวลา (วัน/เดือน/ปี ถัดไป/ก่อนหน้า)
  void _navigatePeriod(int direction) {
    print('Navigate ${_selectedView}: $direction');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('เปลี่ยนช่วงเวลาไป ${_selectedView} ${direction > 0 ? 'ถัดไป' : 'ก่อนหน้า'}')),
    );
  }

  // 📈 Widget สำหรับแสดงยอดขาย ต้นทุน และกำไร (ปรับให้เหมือนภาพ)
  Widget _buildSummaryItem({
    required String label, 
    required double value, 
    Color valueColor = _kIncomeColor,
    bool isProfit = false,
  }) {
    // ใช้ padding น้อยลงเพื่อให้ชิดขอบการ์ดมากขึ้น
    const double verticalPadding = 12.0; 
    
    // จัดรูปแบบตัวเลขเป็น 1,234
    final formattedValue = value.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Label (ยอดขาย/ต้นทุน/กำไร)
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isProfit ? FontWeight.bold : FontWeight.normal,
              color: isProfit ? _kProfitColor : Colors.black87,
            ),
          ),
          
          // Value (ตัวเลข + บาท)
          Row(
            children: [
              Text(
                formattedValue, 
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isProfit ? FontWeight.bold : FontWeight.normal,
                  color: valueColor,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'บาท',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isProfit ? FontWeight.bold : FontWeight.normal,
                  color: isProfit ? _kProfitColor : Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 📅 Widget สำหรับแถบสลับมุมมอง (วัน/เดือน/ปี) - ทำเป็น Segmented Control
  Widget _buildViewSwitcher() {
    final views = ['วัน', 'เดือน', 'ปี'];
    return Container(
      // Container หลักของ Segmented Control
      margin: const EdgeInsets.only(bottom: 20.0), // แยกจากการ์ดด้านล่าง
      padding: const EdgeInsets.all(4.0), // padding ภายในสำหรับให้ดูหนา
      decoration: BoxDecoration(
        color: _kHighlightColor, // สีพื้นหลังของ Segmented Control
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: views.map((view) {
          final isSelected = _selectedView == view;
          return Expanded(
            child: GestureDetector(
              onTap: () => _selectView(view),
              child: Container(
                height: 32, // ความสูงของปุ่ม
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? _kCardColor : Colors.transparent, // ปุ่มที่เลือกเป็นสีขาว
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 0,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  view,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? _kPrimaryColor : Colors.black54,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  // 🧭 Widget สำหรับแถบนำทางช่วงเวลา (วันที่/เดือน/ปี ปัจจุบัน)
  Widget _buildPeriodNavigator(AccountSummary summary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
      // ไม่มีสีพื้นหลังเพราะจะรวมอยู่ใน Card เดียวกับ Summary
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ปุ่มย้อนกลับ
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => _navigatePeriod(-1),
            color: Colors.black87,
          ),
          
          // ช่วงเวลาปัจจุบัน
          Text(
            summary.period,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          // ปุ่มถัดไป
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 20),
            onPressed: () => _navigatePeriod(1),
            color: Colors.black87,
          ),
        ],
      ),
    );
  }
  
  // 🟢 Widget สำหรับปุ่ม "ดูรายงาน" (ทำเป็น Text Label ที่ไฮไลท์)
  Widget _buildReportLink() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('เปิดหน้าดูรายงานโดยละเอียด')),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _kHighlightColor,
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: const Text(
            'ดูรายงาน', 
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold,
              color: _kPrimaryColor,
            )
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _getCurrentSummary();

    return Scaffold(
      backgroundColor: _kBackgroundColor,
      // AppBar
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'บัญชี', 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: _kBackgroundColor,
        elevation: 0,
      ),
      
      // Body ส่วนเนื้อหา
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. แถบสลับ วัน/เดือน/ปี (Segmented Control)
            _buildViewSwitcher(), 
            
            // 2. การ์ดสรุปยอด
            Container(
              decoration: BoxDecoration(
                color: _kCardColor,
                borderRadius: BorderRadius.circular(15.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // นำทางช่วงเวลา
                  _buildPeriodNavigator(summary),
                  
                  const Divider(height: 1, color: Color(0xFFE0E0E0)), // เส้นคั่น
                  
                  // รายละเอียดสรุปยอด
                  Column(
                    children: [
                      _buildSummaryItem(
                        label: 'ยอดขาย',
                        value: summary.income,
                        valueColor: _kProfitColor,
                      ),
                      const Divider(indent: 20, endIndent: 20, height: 1, color: Color(0xFFE0E0E0)),
                      _buildSummaryItem(
                        label: 'ต้นทุน',
                        value: summary.cost,
                        valueColor: _kIncomeColor, // ใช้สีเข้มตามภาพ
                      ),
                      const Divider(indent: 20, endIndent: 20, height: 1, color: Color(0xFFE0E0E0)),
                      // กำไร (ไฮไลท์ด้วยสีเขียวเข้ม)
                      _buildSummaryItem(
                        label: 'กำไร',
                        value: summary.profit,
                        valueColor: _kProfitColor,
                        isProfit: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3. ปุ่ม "ดูรายงาน" (Text Label)
            _buildReportLink(),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
