import 'package:eazy_store/menu_bar/bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

// กำหนดสีหลักที่ใช้ในแอปพลิเคชัน
const Color _kPrimaryColor = Color(0xFF929292);
const Color _kBackgroundColor = Color(0xFFF7F7F7); // สีพื้นหลังอ่อน
const Color _kSearchFillColor = Color(0xFFF4F5F7); 



class CheckPriceScreen extends StatefulWidget {
  const CheckPriceScreen({super.key});

  @override
  State<CheckPriceScreen> createState() => _CheckPriceScreenState();
}

class _CheckPriceScreenState extends State<CheckPriceScreen> {
  // State สำหรับจัดการ Bottom Navigation Bar
  int _selectedIndex = 2; 

  // Controller สำหรับ Search Field
  final TextEditingController _searchController = TextEditingController();

  // Function สำหรับเปลี่ยน Tab ใน Bottom Navigation Bar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // ในแอปจริง คุณจะเพิ่ม Logic สำหรับเปลี่ยนหน้าจอที่นี่
    print('Tab tapped: $index');
  }

  // 🔍 Widget สำหรับ Search Input Field
  Widget _buildSearchInput() {
    return Container(
      decoration: BoxDecoration(
        color: _kSearchFillColor,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color.fromARGB(255, 196, 196, 195), width: 1.5),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'ค้นหาหรือสแกนบาร์โค้ด',
          hintStyle: const TextStyle(color: Colors.grey),
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
          fillColor: Colors.transparent, // ใช้สีจาก Container แทน
          border: InputBorder.none, // ลบ border ของ TextField ออก
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
             borderRadius: BorderRadius.circular(10.0),
             borderSide: const BorderSide(color: _kPrimaryColor, width: 2.0),
          ),
        ),
      ),
    );
  }

  // 🏷️ Widget สำหรับแสดงผลลัพธ์ราคาสินค้า
  Widget _buildProductResultCard({
    required String name,
    required double price,
    String? imageUrl, // Path to the image asset or network image
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
      margin: const EdgeInsets.only(top: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ชื่อสินค้าและราคา
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${price.toStringAsFixed(0)} บาท', // แสดงราคาเป็นจำนวนเต็ม
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900, // Very Bold
                  color: _kPrimaryColor,
                ),
              ),
            ],
          ),

          // รูปสินค้า (จำลอง)
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F0),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: imageUrl != null
                ? Image.asset(
                    imageUrl,
                    fit: BoxFit.cover,
                  )
                : const Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 30,
                      color: Colors.grey,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      // AppBar
      appBar: AppBar(
        title: const Text(
          'เช็คราคาสินค้า',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 26,
            color: Colors.black87,
          ),
        ),
        centerTitle: true, // ชิดซ้ายตามรูป
        backgroundColor: _kBackgroundColor,
        elevation: 0,
        toolbarHeight: 60.0,
      ),
      // Body ส่วนเนื้อหา
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //  Search Bar
            _buildSearchInput(),
            
            //  ผลลัพธ์ราคาสินค้า (จำลองข้อมูลจากภาพที่คุณให้มา)
            _buildProductResultCard(
              name: 'สบู่นกแก้วสีชมพู',
              price: 15.00,
              imageUrl: 'assets/image/soap_image.png', 
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
