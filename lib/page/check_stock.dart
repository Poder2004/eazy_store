import 'package:eazy_store/menu_bar/bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

// กำหนดสีหลักที่ใช้ในแอปพลิเคชัน
const Color _kPrimaryColor = Color(0xFF6B8E23); // สีเขียวมะกอก/ทหาร
const Color _kBackgroundColor = Color(0xFFF7F7F7); // สีพื้นหลังอ่อน
const Color _kSearchFillColor = Color(0xFFEFEFEF); // สีพื้นหลังของ Search Bar
const Color _kCardColor = Color(0xFFFFFFFF); // สีพื้นหลังของ Card รายการสินค้า
const Color _kWarningColor = Color(0xFFFFCC00); // สีเหลืองสำหรับสัญลักษณ์เตือน

// --- DATA MODEL (จำลอง) ---
class Product {
  final String name;
  final int stock;
  final String unit;
  final String imageUrl; // URL หรือ Asset Path

  Product({
    required this.name,
    required this.stock,
    required this.unit,
    required this.imageUrl,
  });
}

// ข้อมูลจำลองสำหรับแสดงใน ListView
final List<Product> dummyProducts = [
  Product(name: 'ขนมปังปอนด์', stock: 0, unit: 'แถว', imageUrl: 'assets/image/bread.png'),
  Product(name: 'โค้กกระป๋อง', stock: 3, unit: 'ป๋อง', imageUrl: 'assets/image/coke.png'),
  Product(name: 'มาม่าหมูสับ', stock: 8, unit: 'ซอง', imageUrl: 'assets/image/mama.png'),
  Product(name: 'สบู่นกแก้วสีชมพู', stock: 15, unit: 'ก้อน', imageUrl: 'assets/image/soap.png'),
];
// ----------------------------



class CheckStockScreen extends StatefulWidget {
  const CheckStockScreen({super.key});

  @override
  State<CheckStockScreen> createState() => _CheckStockScreenState();
}

class _CheckStockScreenState extends State<CheckStockScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    print('Tab tapped: $index');
  }

  // 🔍 Widget สำหรับ Search Input Field และปุ่ม Sort
  Widget _buildSearchBarAndSort() {
    return Column(
      children: [
        // Search Bar
        Container(
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
              hintText: 'ค้นหาหรือสแกนบาร์โค้ด',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 12.0,
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: IconButton(
                icon: Icon(Icons.qr_code_scanner_outlined, color: Colors.grey[700]),
                onPressed: () {
                  // Logic สำหรับการสแกนบาร์โค้ด
                  print('Scanning barcode...');
                },
              ),
              filled: true,
              fillColor: Colors.transparent, 
              border: InputBorder.none, 
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
        
        const SizedBox(height: 10),

        // ปุ่ม เรียงจาก (Sort)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              // Logic สำหรับการเรียงลำดับ
              print('Sorting options selected...');
            },
            icon: const Icon(Icons.sort, color: Colors.black87, size: 24),
            label: const Text(
              'เรียงจาก',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  // 📦 Widget สำหรับ Card แสดงรายการสินค้าแต่ละชิ้น
  Widget _buildProductCard(Product product) {
    // กำหนดว่าควรแสดงไอคอนเตือนหรือไม่ (เช่น เหลือน้อยกว่า 5 ชิ้น)
    final bool showWarning = product.stock <= 5;
    
    // หากสต็อกเป็น 0 ให้แสดงข้อความว่า "หมด"
    final String stockText = product.stock == 0 
      ? 'คงเหลือ 0'
      : 'คงเหลือ ${product.stock}';

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
            // รูปภาพสินค้า
            Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.only(right: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                image: DecorationImage(
                  image: AssetImage(product.imageUrl),
                  fit: BoxFit.cover,
                  // Fallback: ถ้าไม่มีรูป จะใช้ Placeholder สีเทา
                  onError: (exception, stackTrace) {
                    print('Error loading image for ${product.name}: $exception');
                  },
                ),
              ),
            ),
            
            // ข้อมูลสินค้า
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$stockText ${product.unit}',
                    style: TextStyle(
                      fontSize: 16,
                      color: product.stock == 0 ? Colors.red[700] : Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // สัญลักษณ์เตือน (Warning Icon)
            if (showWarning)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: _kWarningColor,
                  size: 30,
                ),
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
      // AppBar สำหรับหัวข้อ "เช็คสต็อกสินค้า"
      appBar: AppBar(
        title: const Text(
          'เช็คสต็อกสินค้า',
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
      
      // Body ส่วนเนื้อหา: Search Bar และ รายการสินค้า
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            // Search Bar และ ปุ่มเรียงจาก
            _buildSearchBarAndSort(),
            
            const SizedBox(height: 15),

            // รายการสินค้า
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 5, bottom: 20),
                itemCount: dummyProducts.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(dummyProducts[index]);
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