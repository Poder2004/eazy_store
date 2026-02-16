import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Imports ไฟล์ของคุณ ---
import 'package:eazy_store/menu_bar/bottom_navbar.dart';
import 'package:eazy_store/page/debt_payment.dart'; // *หมายเหตุ: ต้องแน่ใจว่าหน้านี้รับค่าได้

// --- Imports API และ Model ---
import '../api/api_debtor.dart';
import '../model/response/debtor_response.dart';
import 'package:eazy_store/page/debt_payment.dart';

// กำหนดสีหลัก
const Color _kPrimaryColor = Color(0xFF6B8E23);
const Color _kBackgroundColor = Color(0xFFF7F7F7);
const Color _kSearchFillColor = Color(0xFFEFEFEF);
const Color _kCardColor = Color(0xFFFFFFFF);
const Color _kPayButtonColor = Color(0xFF8BC34A);

class DebtLedgerScreen extends StatefulWidget {
  const DebtLedgerScreen({super.key});

  @override
  State<DebtLedgerScreen> createState() => _DebtLedgerScreenState();
}

class _DebtLedgerScreenState extends State<DebtLedgerScreen> {
  int _selectedIndex = 3;
  final TextEditingController _searchController = TextEditingController();

  // --- ตัวแปรสำหรับข้อมูล API ---
  List<DebtorResponse> _originalDebtors = []; // ★ เก็บข้อมูลต้นฉบับทั้งหมด (Backup)
  List<DebtorResponse> _allDebtors = []; // รายชื่อที่แสดงผล (อาจถูกกรองจากการค้นหา)
  List<DebtorResponse> _searchResults = []; // ผลลัพธ์ Dropdown
  
  bool _isLoading = true;
  bool _isSearching = false;
  bool _showDropdown = false;
  Timer? _debounce;
  int _currentShopId = 1;

  @override
  void initState() {
    super.initState();
    _initialData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initialData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentShopId = prefs.getInt('shopId') ?? 1;
    });
    _fetchAllDebtors();
  }

  // --- ฟังก์ชันดึงลูกหนี้ทั้งหมด ---
  Future<void> _fetchAllDebtors() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiDebtor.getDebtorsByShop(_currentShopId);
      setState(() {
        _originalDebtors = result; // เก็บไว้เป็นตัวยืน
        _allDebtors = result;      // ตัวนี้เอาไว้แสดงผล (อาจเปลี่ยนไปตามการค้นหา)
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading debtors: $e");
      setState(() => _isLoading = false);
    }
  }

  // --- ฟังก์ชันค้นหา (Search) ---
  void _onSearchChanged(String keyword) {
    if (keyword.isEmpty) {
      setState(() {
        _searchResults = [];
        _showDropdown = false;
        _allDebtors = _originalDebtors; // ★ คืนค่ารายชื่อทั้งหมดเมื่อลบคำค้นหา
      });
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isSearching = true);
      try {
        final results = await ApiDebtor.searchDebtor(keyword);
        setState(() {
          _searchResults = results;
          _showDropdown = true;
        });
      } catch (e) {
        print("Error searching: $e");
        setState(() => _searchResults = []);
      } finally {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  // ★ แก้ไข: เลือกจาก Dropdown แล้วแค่ "กรอง" รายชื่อให้เหลือคนนั้น (ยังไม่ไปหน้าจ่ายเงิน)
  void _selectFromDropdown(DebtorResponse debtor) {
    setState(() {
      _searchController.text = debtor.name; // ใส่ชื่อในช่องค้นหา
      _allDebtors = [debtor]; // ★ โชว์เฉพาะคนนี้ในการ์ดรายการ
      _showDropdown = false;  // ปิด Dropdown
      FocusScope.of(context).unfocus(); // หุบคีย์บอร์ด
    });
  }

  // --- Widgets ---

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
        onChanged: _onSearchChanged,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'ค้นหารายชื่อ หรือเบอร์โทร',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          // ปุ่มกากบาทลบคำค้นหา (Optional)
          suffixIcon: _searchController.text.isNotEmpty 
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged(""); // เรียกให้รีเซ็ตลิสต์
                },
              ) 
            : null,
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSearchResultsDropdown() {
    if (!_showDropdown) return const SizedBox.shrink();

    return Positioned(
      top: 60,
      left: 0,
      right: 0,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 250),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
          ],
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: _searchResults.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(15.0),
                child: Text("ไม่พบข้อมูล", textAlign: TextAlign.center),
              )
            : ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _searchResults.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final item = _searchResults[i];
                  return ListTile(
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item.phone),
                    trailing: const Icon(Icons.search, size: 18, color: Colors.grey), // เปลี่ยนไอคอนเป็นแว่นขยายสื่อว่า "ดูข้อมูล"
                    onTap: () => _selectFromDropdown(item),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildDebtorCard(DebtorResponse debtor) {
    double mockAmount = 0.00;

    return Card(
      color: _kCardColor,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    debtor.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Text(
                    debtor.phone,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('ค้าง ', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                      Text(
                        mockAmount.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.red),
                      ),
                      const Text(' บาท', style: TextStyle(fontSize: 16, color: Colors.red)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                SizedBox(
                  height: 35,
                  child: ElevatedButton(
                    onPressed: () {
                      // ★ ส่งข้อมูลเมื่อกดปุ่มนี้เท่านั้น! ★
                      // ต้องแน่ใจว่า DebtPaymentScreen ของคุณรับพารามิเตอร์ (เช่น constructor)
                      // ตัวอย่าง: DebtPaymentScreen(selectedDebtor: debtor)
                      
                      Get.to(() => DebtPaymentScreen(debtor: debtor)); 
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPayButtonColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                      elevation: 3,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: const Text('ชำระเงิน', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        title: const Text('บัญชีคนค้างชำระ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black87)),
        centerTitle: true,
        backgroundColor: _kBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Stack(
          children: [
            // --- Layer ล่าง: เนื้อหาหลัก ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 70), // เว้นที่ให้ Search Bar

                const Text('รายชื่อทั้งหมด', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 10),

                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _allDebtors.isEmpty
                          ? const Center(child: Text("ยังไม่มีรายการค้างชำระ (หรือค้นหาไม่เจอ)"))
                          : ListView.builder(
                              padding: const EdgeInsets.only(top: 5, bottom: 20),
                              itemCount: _allDebtors.length,
                              itemBuilder: (context, index) {
                                return _buildDebtorCard(_allDebtors[index]);
                              },
                            ),
                ),
              ],
            ),

            // --- Layer บน: Search Bar และ Dropdown ---
            Column(
              children: [
                _buildSearchBar(),
                _buildSearchResultsDropdown(),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}