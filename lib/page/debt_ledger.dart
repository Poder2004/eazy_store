import 'package:eazy_store/menu_bar/bottom_navbar.dart';
import 'package:eazy_store/page/debt_payment.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

// กำหนดสีหลักที่ใช้ในแอปพลิเคชัน
const Color _kPrimaryColor = Color(0xFF6B8E23); // สีเขียวมะกอก/ทหาร
const Color _kBackgroundColor = Color(0xFFF7F7F7); // สีพื้นหลังอ่อน
const Color _kSearchFillColor = Color(0xFFEFEFEF); // สีพื้นหลังของ Search Bar
const Color _kCardColor = Color(0xFFFFFFFF); // สีพื้นหลังของ Card รายการสินค้า
const Color _kPayButtonColor = Color(0xFF8BC34A); // สีเขียวสว่างสำหรับปุ่มชำระเงิน

// --- DATA MODEL (จำลอง) ---
class DebtEntry {
  final String name;
  final double amount;
  final String lastTransactionDate;

  DebtEntry({
    required this.name,
    required this.amount,
    required this.lastTransactionDate,
  });
}

// ข้อมูลจำลองสำหรับแสดงใน ListView
final List<DebtEntry> dummyDebts = [
  DebtEntry(name: 'ป้าดา', amount: 45.00, lastTransactionDate: '9 เมษายน 2568'),
  DebtEntry(name: 'กานต์', amount: 205.50, lastTransactionDate: '9 เมษายน 2568'),
  DebtEntry(name: 'พิมพ์', amount: 90.00, lastTransactionDate: '8 เมษายน 2568'),
  DebtEntry(name: 'ธนาคาร', amount: 520.75, lastTransactionDate: '7 เมษายน 2568'),
  DebtEntry(name: 'ศิริพร', amount: 10.00, lastTransactionDate: '6 เมษายน 2568'),
  DebtEntry(name: 'ปริม', amount: 15.25, lastTransactionDate: '5 เมษายน 2568'),
];
// ----------------------------


class DebtLedgerScreen extends StatefulWidget {
  const DebtLedgerScreen({super.key});

  @override
  State<DebtLedgerScreen> createState() => _DebtLedgerScreenState();
}

class _DebtLedgerScreenState extends State<DebtLedgerScreen> {
  int _selectedIndex = 3; // Index 3: คนค้างชำระ
  final TextEditingController _searchController = TextEditingController();
  String _currentDate = '9 เมษายน 2568'; // วันที่ปัจจุบัน (จำลอง)

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    print('Tab tapped: $index');
    // Logic for navigation goes here (e.g., Get.to(Screen()));
  }

  // 🔍 Widget สำหรับ Search Input Field และ Calendar Icon
  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: _kSearchFillColor,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.grey.shade300, width: 1.0),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'ค้นหารายชื่อ',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10.0,
            horizontal: 12.0,
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: IconButton(
            icon: Icon(Icons.calendar_month_outlined, color: Colors.grey[700], size: 28),
            onPressed: () {
              // Logic สำหรับเปิด Calendar Picker
              print('Calendar Picker opened...');
            },
          ),
          filled: true,
          fillColor: Colors.transparent, 
          border: InputBorder.none, 
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  // 📝 Widget สำหรับ Card แสดงรายละเอียดการค้างชำระของลูกค้า
  Widget _buildDebtCard(DebtEntry debt) {
    // ฟังก์ชันสำหรับฟอร์แมตจำนวนเงินให้มีทศนิยม 2 ตำแหน่ง
    String formatAmount(double amount) {
      return amount.toStringAsFixed(2);
    }
    
    return Card(
      color: _kCardColor,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ข้อมูลลูกค้า (ชื่อ, ยอดค้าง)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    debt.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'ค้าง ',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '${formatAmount(debt.amount)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.red, // ใช้สีแดงสำหรับยอดค้าง
                        ),
                      ),
                      const Text(
                        ' บาท',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // รายละเอียดเพิ่มเติม (Last Transaction Date)
                  InkWell(
                    onTap: () {
                      print('Viewing details for ${debt.name}');
                      // Logic for viewing debt details
                    },
                    child: Text(
                      'รายละเอียดเพิ่มเติม',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.grey[500],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // ปุ่ม Actions
            Column(
              children: [
                
              
                const SizedBox(height: 8),
                // ปุ่ม ชำระเงิน
                SizedBox(
                  height: 35,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.to(() => const DebtPaymentScreen());
                      print('Processing payment for ${debt.name}');
                      // Logic for processing payment
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPayButtonColor, // สีเขียวสว่าง
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      elevation: 3,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: const Text(
                      'ชำระเงิน',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      // AppBar สำหรับหัวข้อ "บัญชีคนค้างชำระ"
      appBar: AppBar(
        title: const Text(
          'บัญชีคนค้างชำระ',
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            _buildSearchBar(),
            
            const SizedBox(height: 15),

            // วันที่แสดงปัจจุบัน (ตามภาพ)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: Text(
                  _currentDate,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),
            
            // หัวข้อ "รายชื่อ"
            const Text(
              'รายชื่อ',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),

            // รายการลูกค้าที่ค้างชำระ
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 5, bottom: 20),
                itemCount: dummyDebts.length,
                itemBuilder: (context, index) {
                  return _buildDebtCard(dummyDebts[index]);
                },
              ),
            ),
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