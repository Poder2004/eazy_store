import 'package:eazy_store/page/menu_bar/bottom_navbar.dart';
import 'package:eazy_store/page/wait_coming/order_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

// --- THEME & CONSTANTS ---
const Color _kPrimaryColor = Color(
  0xFF6B8E23,
); // สีเขียวมะกอก/ทหาร (สำหรับปุ่มหลัก)
const Color _kBackgroundColor = Color(0xFFF7F7F7); // สีพื้นหลังอ่อน
const Color _kCardColor = Colors.white; // สีพื้นหลังของการ์ดสินค้า
const Color _kInputFillColor = Color(0xFFF0F0E0); // สีพื้นหลังของ Input Field
const Color _kWarningColor = Color(0xFFFDD835); // สีเหลืองเตือนภัย

// --- DATA MODEL & MOCKUP ---
class Product {
  final String id;
  final String name;
  final int remaining;
  final String unit;
  final String imageUrl;
  final bool isSelected; // สถานะการสั่งซื้อ/เติมสต็อก

  Product({
    required this.id,
    required this.name,
    required this.remaining,
    required this.unit,
    required this.imageUrl,
    this.isSelected = false,
  });

  Product copyWith({bool? isSelected}) {
    return Product(
      id: id,
      name: name,
      remaining: remaining,
      unit: unit,
      imageUrl: imageUrl,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

// ข้อมูลสินค้าจำลอง
final List<Product> _kMockProducts = [
  Product(
    id: 'P001',
    name: 'ขนมปังปอนด์',
    remaining: 0,
    unit: 'แถว',
    imageUrl: 'https://placehold.co/80x80/E0E0E0/333333?text=Bread',
    isSelected: true,
  ),
  Product(
    id: 'P002',
    name: 'โค้กกระป๋อง',
    remaining: 3,
    unit: 'ป๋อง',
    imageUrl: 'https://placehold.co/80x80/FF0000/FFFFFF?text=Coke',
    isSelected: true,
  ),
  Product(
    id: 'P003',
    name: 'มาม่าหมูสับ',
    remaining: 8,
    unit: 'ซอง',
    imageUrl: 'https://placehold.co/80x80/FFA500/FFFFFF?text=Mama',
    isSelected: false,
  ),
  Product(
    id: 'P004',
    name: 'สบู่นกแก้วสีชมพู',
    remaining: 15,
    unit: 'ก้อน',
    imageUrl: 'https://placehold.co/80x80/FFB6C1/333333?text=Soap',
    isSelected: false,
  ),
];

// ----------------------------

class BuyProductsScreen extends StatefulWidget {
  const BuyProductsScreen({super.key});

  @override
  State<BuyProductsScreen> createState() => _BuyProductsScreenState();
}

class _BuyProductsScreenState extends State<BuyProductsScreen> {
  // จำลอง Index 4 เป็นปุ่ม "สั่งซื้อ" ใน BottomNavBar
  int _selectedIndex = 4;
  List<Product> _products = _kMockProducts;
  final TextEditingController _searchController = TextEditingController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    print('Tab tapped: $index');
  }

  // 🔘 ฟังก์ชันสำหรับจัดการการเลือก/ไม่เลือกสินค้า
  void _toggleProductSelection(String id, bool? isSelected) {
    setState(() {
      _products = _products.map((p) {
        return p.id == id ? p.copyWith(isSelected: isSelected) : p;
      }).toList();
    });
  }

  // 📝 Widget สำหรับ Search Bar (ตามภาพ)
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 15.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ค้นหาหรือสแกนบาร์โค้ด',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 16,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFFB0B0B0),
                  ),
                  suffixIcon: Icon(
                    Icons.qr_code_scanner_outlined,
                    color: Colors.grey.shade500,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
                ),
                onChanged: (value) {
                  // Logic ค้นหาสินค้า (จำลองการกรองรายการ)
                  print('Search: $value');
                  // ในแอปจริงจะทำการกรอง _products list ตาม value
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          // ปุ่มจัดเรียง (Sorting Button)
          GestureDetector(
            onTap: () {
              print('Sorting tapped');
              // แสดงเมนูสำหรับการจัดเรียง
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: const Row(
                children: [
                  Text(
                    'เรียงจาก',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  Icon(Icons.unfold_more, size: 18, color: Colors.black54),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 📦 Widget สำหรับการ์ดสินค้าแต่ละรายการ (ตามภาพ)
  Widget _buildProductCard(Product product) {
    // กำหนดสีขอบเมื่อถูกเลือก (เหมือน โค้กกระป๋อง ในภาพ)
    final bool isSelected = product.isSelected;
    final Color borderColor = isSelected ? _kPrimaryColor : Colors.white;
    final double borderWidth = isSelected ? 3.0 : 0.0;

    // กำหนดสี Radio Button
    final Color radioColor = isSelected ? _kPrimaryColor : Colors.grey.shade400;

    return GestureDetector(
      onTap: () => _toggleProductSelection(product.id, !product.isSelected),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: _kCardColor,
          borderRadius: BorderRadius.circular(15.0),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // รูปภาพสินค้า (ซ้าย)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                image: DecorationImage(
                  image: NetworkImage(product.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 15),

            // ชื่อสินค้าและคงเหลือ (กลาง)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'คงเหลือ ${product.remaining} ${product.unit}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      // Icon Warning ถ้าคงเหลือเป็น 0
                      if (product.remaining == 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: _kWarningColor,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Radio Button (ขวา)
            Theme(
              data: ThemeData(
                unselectedWidgetColor: radioColor, // ใช้สีเทาเมื่อไม่ถูกเลือก
              ),
              child: Radio<bool>(
                value: true,
                groupValue: product.isSelected
                    ? true
                    : null, // ถ้าเป็น true ให้ GroupValue เป็น true เพื่อให้เลือก
                onChanged: (bool? value) {
                  _toggleProductSelection(product.id, value);
                },
                activeColor: radioColor, // ใช้สีเขียวหลักเมื่อถูกเลือก
                // การตั้งค่า visualDensity ให้เป็น compact ช่วยให้ Radio button ไม่ใหญ่จนเกินไป
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🛒 Widget สำหรับปุ่ม "ยืนยัน"
  Widget _buildConfirmButton() {
    // นับจำนวนสินค้าที่ถูกเลือก
    final int selectedCount = _products.where((p) => p.isSelected).length;

    return Container(
      padding: const EdgeInsets.all(15.0),
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
        child: SizedBox(
          height: 55,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: selectedCount > 0
                ? () {
                    Get.to(() => const OrderListScreen());
                    // Logic ยืนยันการสั่งซื้อสินค้า
                    final List<String> selectedNames = _products
                        .where((p) => p.isSelected)
                        .map((p) => p.name)
                        .toList();

                    print('Confirmed Order for: $selectedNames');

                    // แสดง SnackBar แจ้งเตือน
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'ยืนยันการสั่งซื้อ ${selectedCount} รายการสำเร็จ',
                        ),
                        backgroundColor: _kPrimaryColor,
                      ),
                    );
                  }
                : null, // ปิดการใช้งานปุ่มถ้าไม่มีการเลือกสินค้า
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              elevation: 5,
            ),
            child: Text(
              selectedCount > 0 ? 'ยืนยัน (${selectedCount})' : 'ยืนยัน',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- BOTTOM NAV BAR (COMPACT VERSION FOR THIS FILE) ---
  Widget _buildBottomNavBar() {
    return BottomNavBar(currentIndex: _selectedIndex, onTap: _onItemTapped);
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
          'สั่งซื้อสินค้า', // ตรงตามภาพ
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: _buildSearchBar(),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 25.0,
                vertical: 0.0,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                return _buildProductCard(_products[index]);
              },
            ),
          ),

          // ปุ่มยืนยันด้านล่าง
          _buildConfirmButton(),
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
