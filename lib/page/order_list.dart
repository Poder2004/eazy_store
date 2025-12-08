import 'package:eazy_store/menu_bar/bottom_navbar.dart';
import 'package:eazy_store/page/buy_products.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

// --- THEME & CONSTANTS ---
const Color _kPrimaryColor = Color(0xFF6B8E23); // สีเขียวมะกอก/ทหาร (ปุ่มหลัก)
const Color _kSecondaryButtonColor = Color(0xFF5390F2); // สีน้ำเงินสำหรับปุ่ม PDF
const Color _kBackgroundColor = Color(0xFFF7F7F7); // สีพื้นหลังอ่อน
const Color _kCardColor = Colors.white; // สีพื้นหลังของการ์ดสินค้า
const Color _kInputFillColor = Color(0xFFF0F0E0); // สีพื้นหลังของ Input Field

// --- DATA MODEL & CONTROLLERS ---
class OrderItem {
  final String id;
  final String name;
  final String unit;
  final String imageUrl;
  // Controllers สำหรับ Quantity และ Note
  final TextEditingController quantityController;
  final TextEditingController noteController;
  
  OrderItem({
    required this.id, 
    required this.name, 
    required this.unit, 
    required this.imageUrl, 
    required int initialQuantity,
    String initialNote = '',
  }) : quantityController = TextEditingController(text: initialQuantity.toString()),
       noteController = TextEditingController(text: initialNote);

  // เพื่อให้มั่นใจว่า Controllers ถูก Dispose เมื่อรายการถูกลบ
  void dispose() {
    quantityController.dispose();
    noteController.dispose();
  }
}

// ข้อมูลรายการสั่งของจำลอง
final List<OrderItem> _kMockOrderItems = [
  OrderItem(
    id: 'P001',
    name: 'ขนมปังปอนด์',
    initialQuantity: 30, 
    unit: 'แถว',
    imageUrl: 'https://placehold.co/80x80/E0E0E0/333333?text=Bread',
  ),
  OrderItem(
    id: 'P002',
    name: 'โค้กกระป๋อง',
    initialQuantity: 2, 
    unit: 'ถาด',
    imageUrl: 'https://placehold.co/80x80/FF0000/FFFFFF?text=Coke',
    initialNote: 'ต้องการรสซ่าพิเศษ',
  ),
];

// ----------------------------

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  // Index 4: สั่งค่า (ตามที่เห็นใน BottomNavBar ของภาพ)
  int _selectedIndex = 4; 
  List<OrderItem> _orderItems = _kMockOrderItems;
  
  @override
  void dispose() {
    // ต้อง Dispose Controllers ทั้งหมดเมื่อ State ถูกทำลาย
    for (var item in _orderItems) {
      item.dispose();
    }
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    print('Tab tapped: $index');
  }
  
  // ➕ ฟังก์ชันสำหรับเพิ่ม/ลดจำนวนสินค้าที่สั่ง (รองรับทั้งปุ่มและช่องกรอก)
  void _updateQuantity(OrderItem item, int change) {
    int currentQuantity = int.tryParse(item.quantityController.text) ?? 0;
    int newQuantity = currentQuantity + change;

    if (newQuantity <= 0) {
      // ถ้าจำนวนเป็น 0 หรือน้อยกว่า ให้เรียกหน้าต่างยืนยันการลบ
      _showDeleteConfirmation(item, isFromButton: true);
    } else {
      // อัพเดทค่าใน Controller
      item.quantityController.text = newQuantity.toString();
    }
  }
  
  // 🎯 Widget สำหรับปุ่มเพิ่ม/ลดจำนวน
  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isPlus,
  }) {
    // ใช้ขนาดที่เหมาะสมสำหรับปุ่มควบคุม
    const double size = 30; 
    
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.symmetric(horizontal: 5), // ระยะห่าง
      child: Material(
        color: _kPrimaryColor,
        borderRadius: BorderRadius.circular(8.0),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8.0),
          child: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }


  // 📦 Widget สำหรับการ์ดสินค้าในรายการสั่งซื้อ (มีช่องกรอกและปุ่ม +/-)
  Widget _buildOrderItemCard(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15.0),
      padding: const EdgeInsets.all(15.0),
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
          // 1. แถวบน: รูปภาพ, ชื่อสินค้า, ปุ่มลบ
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // รูปภาพสินค้า (ซ้าย)
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  image: DecorationImage(
                    image: NetworkImage(item.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 15),

              // ชื่อสินค้า (กลาง)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'ใส่จำนวนและหมายเหตุ:', // เพิ่ม Label นำ
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              
              // ปุ่มลบรายการ (ไอคอน X)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => _showDeleteConfirmation(item),
              ),
            ],
          ),
          
          // 2. แถว Quantity Control (ปุ่ม +/- และช่องกรอก)
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.end, // ชิดขวา
            children: [
              const Text(
                'จำนวน:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              
              // ปุ่ม -
              _buildQuantityButton(
                icon: Icons.remove,
                onPressed: () => _updateQuantity(item, -1),
                isPlus: false,
              ),
              
              // ช่องกรอกจำนวน
              SizedBox(
                width: 70, // กำหนดความกว้างของช่องกรอก
                height: 35,
                child: TextField(
                  controller: item.quantityController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '0',
                    isDense: true,
                    filled: true,
                    fillColor: _kInputFillColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.0),
                    ),
                  ),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  // ตรวจสอบเมื่อมีการเปลี่ยนแปลง
                  onChanged: (value) {
                    if (value.isEmpty || int.tryParse(value) == 0) {
                      _showDeleteConfirmation(item);
                    }
                  },
                ),
              ),
              
              // ปุ่ม +
              _buildQuantityButton(
                icon: Icons.add,
                onPressed: () => _updateQuantity(item, 1),
                isPlus: true,
              ),
              
              const SizedBox(width: 10),
              // หน่วยนับ
              Text(
                item.unit,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              
              const SizedBox(width: 15), // ขอบขวา
            ],
          ),
          
          // 3. ช่องหมายเหตุ (New Position: Below Quantity Control)
          const SizedBox(height: 15), // แยกจากแถวจำนวน
          TextField(
            controller: item.noteController,
            decoration: InputDecoration(
              hintText: 'เพิ่มหมายเหตุ (ถ้ามี)',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: const Icon(Icons.note_alt_outlined, size: 20, color: Colors.black54),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
  
  // 🗑️ Modal สำหรับยืนยันการลบรายการสินค้า
  void _showDeleteConfirmation(OrderItem item, {bool isFromButton = false}) {
    // เก็บค่าปัจจุบันไว้ เผื่อกดยกเลิก
    String originalQuantity = item.quantityController.text;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: const Text('ลบรายการสินค้า', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('คุณต้องการลบ "${item.name}" ออกจากรายการสั่งซื้อหรือไม่?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // ถ้ามากจากการกดปุ่ม - หรือกรอก 0 ให้คืนค่าเป็น 1
                if (isFromButton || int.tryParse(item.quantityController.text) == 0 || item.quantityController.text.isEmpty) {
                  // ถ้ามีการเคลียร์ช่องกรอก/ลดเหลือ 0 ให้คืนค่าเป็น 1 (ถ้าค่าเดิมไม่ว่าง)
                  if (int.tryParse(originalQuantity) == 0 || originalQuantity.isEmpty) {
                     item.quantityController.text = '1';
                  } else {
                     item.quantityController.text = originalQuantity;
                  }
                }
              },
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                // ถ้ากดยืนยันการลบ
                setState(() {
                  _orderItems.removeWhere((i) => i.id == item.id);
                  item.dispose(); // ทิ้ง Controller
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('นำ ${item.name} ออกจากรายการสั่งซื้อแล้ว'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
              child: const Text('ลบ', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // 📝 Widget สำหรับปุ่ม "เพิ่มรายการสินค้า" (สีเขียวหลัก)
  Widget _buildAddItemButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: SizedBox(
        height: 55,
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
             Get.to(() => const BuyProductsScreen());
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('เปิดหน้าเพิ่มรายการสินค้า')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 5,
          ),
          icon: const Icon(Icons.add, color: Colors.white, size: 24),
          label: const Text(
            'เพิ่มรายการสินค้า',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // 📄 Widget สำหรับปุ่ม "ส่งออกเป็น PDF" (สีน้ำเงิน)
  Widget _buildExportPdfButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: SizedBox(
        height: 55,
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            // ดึงข้อมูลทั้งหมดจาก Controller ก่อนส่งออก
            final orderData = _orderItems.map((item) => {
              'name': item.name,
              'quantity': item.quantityController.text,
              'unit': item.unit,
              'note': item.noteController.text,
            }).toList();
            
            print('Exporting PDF with data: $orderData');

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('กำลังสร้างไฟล์ PDF...')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _kSecondaryButtonColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 5,
          ),
          icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 24),
          label: const Text(
            'ส่งออกเป็น PDF',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
  
  // --- BOTTOM NAV BAR (COMPACT VERSION FOR THIS FILE) ---
  Widget _buildBottomNavBar() {
    return BottomNavBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      // AppBar
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'รายการสั่งของ', // ตรงตามภาพ
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
      body: Column(
        children: [
          // รายการสินค้า
          Expanded(
            child: _orderItems.isEmpty 
              ? const Center(
                  child: Text(
                    'ไม่มีรายการสินค้าที่ต้องสั่งซื้อ',
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                )
              : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
                itemCount: _orderItems.length,
                itemBuilder: (context, index) {
                  return _buildOrderItemCard(_orderItems[index]);
                },
              ),
          ),
          
          // ปุ่มหลักด้านล่าง
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, -3), // เงาด้านบน
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildAddItemButton(),
                  _buildExportPdfButton(),
                ],
              ),
            ),
          ),
        ],
      ),

     // Bottom Navigation Bar
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
