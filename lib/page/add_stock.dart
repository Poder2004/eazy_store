import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/menu_bar/bottom_navbar.dart';
import 'package:eazy_store/model/request/product_model.dart';
import 'package:eazy_store/sale_producct/scan_barcode.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🎨 Theme Colors
const Color _kPrimaryColor = Color(0xFF6B8E23);
const Color _kBackgroundColor = Color(0xFFF7F7F7);
const Color _kInputFillColor = Color(0xFFF0F0E0);
const Color _kReadOnlyColor = Color(0xFFEEEEEE); // สีพื้นหลังช่องที่แก้ไขไม่ได้

class AddStockScreen extends StatefulWidget {
  const AddStockScreen({super.key});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  int _selectedIndex = 1; // สมมติว่าเมนู Stock อยู่ลำดับที่ 1
  Product? _foundProduct;
  bool _isSearching = false;

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _salePriceController = TextEditingController();
  final TextEditingController _currentStockController = TextEditingController();
  final TextEditingController _addAmountController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  // ตัวแปรคำนวณยอดรวม Real-time
  int _calculatedTotal = 0;

  @override
  void initState() {
    super.initState();
    // 🧮 ฟังชั่นคำนวณยอดรวมทันทีที่พิมพ์ตัวเลข
    _addAmountController.addListener(() {
      if (_foundProduct != null) {
        int current = int.tryParse(_currentStockController.text) ?? 0;
        int add = int.tryParse(_addAmountController.text) ?? 0;
        setState(() {
          _calculatedTotal = current + add;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _costController.dispose();
    _salePriceController.dispose();
    _currentStockController.dispose();
    _addAmountController.dispose();
    _unitController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  // 🔍 ฟังก์ชันค้นหาสินค้า (รองรับทั้งชื่อและบาร์โค้ด)
  Future<void> _handleSearch() async {
    String keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;

    setState(() => _isSearching = true);

    try {
      // 1. ดึงสินค้าทั้งหมดในร้าน (หรือจะทำ API Search แยกก็ได้)
      // ในที่นี้สมมติว่าใช้ getProductsByShop แล้ววนหาในเครื่องเพื่อความไว
      // (ถ้าของเยอะแนะนำทำ API /search?q=... ที่ Backend)
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;

      List<Product> allProducts = await ApiProduct.getProductsByShop(shopId);

      // ค้นหาจาก Barcode หรือ Name
      var match = allProducts.firstWhereOrNull(
        (p) => (p.barcode == keyword) || (p.name.contains(keyword)),
      );

      if (match != null) {
        setState(() {
          _foundProduct = match;
          _nameController.text = match.name;
          _costController.text = match.costPrice.toStringAsFixed(2);
          _salePriceController.text = match.sellPrice.toStringAsFixed(2);
          _currentStockController.text = match.stock.toString();
          _unitController.text = match.unit;
          _categoryController.text = match.category?.name ?? 'ทั่วไป';

          _addAmountController.clear();
          _calculatedTotal = match.stock;
        });
        Get.snackbar(
          "สำเร็จ",
          "พบสินค้า: ${match.name}",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      } else {
        _handleClear();
        Get.snackbar(
          "ไม่พบข้อมูล",
          "ไม่มีสินค้ารหัส/ชื่อนี้ในระบบ",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() => _isSearching = false);
    }
  }

  // 🧹 ล้างหน้าจอ
  void _handleClear() {
    setState(() {
      _foundProduct = null;
      _nameController.clear();
      _costController.clear();
      _salePriceController.clear();
      _currentStockController.clear();
      _addAmountController.clear();
      _unitController.clear();
      _categoryController.clear();
      _calculatedTotal = 0;
    });
  }

  // 🛡️ ตรวจสอบก่อนบันทึก (Popup)
  void _handleSaveCheck() {
    if (_foundProduct == null) return;

    int amount = int.tryParse(_addAmountController.text) ?? 0;
    if (amount <= 0) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณาระบุจำนวนที่ต้องการเพิ่ม",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // แสดง Popup สวยๆ
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.playlist_add_check_circle,
                size: 60,
                color: _kPrimaryColor,
              ),
              const SizedBox(height: 15),
              const Text(
                "ยืนยันเพิ่มสต็อก",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 30),

              _buildConfirmRow("สินค้า", _nameController.text),
              _buildConfirmRow(
                "คงเหลือเดิม",
                "${_currentStockController.text} ${_unitController.text}",
              ),
              _buildConfirmRow(
                "เพิ่มจำนวน",
                "+$amount ${_unitController.text}",
                valueColor: Colors.green,
              ),
              const Divider(),
              _buildConfirmRow(
                "รวมสุทธิ",
                "$_calculatedTotal ${_unitController.text}",
                isBold: true,
              ),

              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "แก้ไข",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        _executeSave(amount);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "ยืนยัน",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildConfirmRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.black87,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // 💾 บันทึกจริง (API)
  Future<void> _executeSave(int amount) async {
    // Show Loading
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    bool success = await ApiProduct.updateStock(
      _foundProduct!.productId!,
      amount,
    );

    Get.back(); // Hide Loading

    if (success) {
      Get.snackbar(
        "สำเร็จ",
        "เพิ่มสต็อกเรียบร้อยแล้ว",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      _handleClear(); // ล้างหน้าจอเตรียมทำรายการต่อไป
      _searchController.clear();
    } else {
      Get.snackbar(
        "ผิดพลาด",
        "บันทึกไม่สำเร็จ กรุณาลองใหม่",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        title: Text(
          'รับสินค้าเข้า',
          style: GoogleFonts.prompt(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: _kBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _handleClear,
            icon: const Icon(
              Icons.cleaning_services_outlined,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🔎 ช่องค้นหา + ปุ่มสแกน
            _buildSearchSection(),

            const SizedBox(height: 20),

            // 📦 แสดงรายละเอียดสินค้า (ถ้าเจอ)
            if (_foundProduct != null) ...[
              _buildProductCard(),
              const SizedBox(height: 20),
              _buildStockInputSection(),
              const SizedBox(height: 30),
              _buildActionButtons(),
            ] else if (_isSearching) ...[
              const Padding(
                padding: EdgeInsets.only(top: 50),
                child: CircularProgressIndicator(color: _kPrimaryColor),
              ),
            ] else ...[
              // Placeholder ตอนยังไม่ค้นหา
              Padding(
                padding: const EdgeInsets.only(top: 50),
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "ค้นหาสินค้าเพื่อเพิ่มสต็อก",
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }

  // --- Widgets ---

  Widget _buildSearchSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'ชื่อสินค้า หรือ รหัสบาร์โค้ด',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: _kPrimaryColor),
            onPressed: () async {
              // 📷 เปิดกล้องสแกน
              var result = await Get.to(() => const ScanBarcodePage());
              if (result != null && result is String) {
                _searchController.text = result;
                _handleSearch(); // ค้นหาทันทีเมื่อสแกนเสร็จ
              }
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onSubmitted: (_) => _handleSearch(),
      ),
    );
  }

  Widget _buildProductCard() {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 40), // เว้นที่ให้รูป
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Column(
            children: [
              Text(
                _nameController.text,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                "รหัส: ${_foundProduct?.productCode ?? '-'}",
                style: const TextStyle(color: Colors.grey),
              ),
              const Divider(height: 30),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem("หมวดหมู่", _categoryController.text),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      "ราคาขาย",
                      "฿${_salePriceController.text}",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem("ต้นทุน", "฿${_costController.text}"),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      "คงเหลือ",
                      "${_currentStockController.text} ${_unitController.text}",
                      isHighlight: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // รูปภาพลอยด้านบน
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
            ],
            image: DecorationImage(
              image: NetworkImage(_foundProduct?.imgProduct ?? ''),
              fit: BoxFit.cover,
              onError: (e, s) {},
            ),
          ),
          child:
              _foundProduct?.imgProduct == null ||
                  _foundProduct!.imgProduct.isEmpty
              ? const Icon(Icons.image_not_supported, color: Colors.grey)
              : null,
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isHighlight ? _kPrimaryColor : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStockInputSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kPrimaryColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.add_circle_outline, color: _kPrimaryColor),
              const SizedBox(width: 10),
              const Text(
                "เพิ่มจำนวนสต็อก",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _addAmountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _kPrimaryColor,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: Colors.grey[300]),
              filled: true,
              fillColor: _kInputFillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              "ยอดรวมใหม่: $_calculatedTotal ${_unitController.text}",
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: _handleSaveCheck,
        icon: const Icon(Icons.save, color: Colors.white),
        label: const Text(
          "บันทึกสต็อก",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
        ),
      ),
    );
  }
}
