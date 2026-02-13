import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ★ 1. import shared_preferences

// --- Imports ไฟล์ของคุณ ---
import 'package:eazy_store/menu_bar/bottom_navbar.dart';
import 'package:eazy_store/page/debt_payment.dart';

// --- Imports API และ Model ---
import '../api/api_debtor.dart';
import '../model/response/debtor_response.dart';

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
  List<DebtorResponse> _allDebtors = []; // รายชื่อทั้งหมด
  List<DebtorResponse> _searchResults = []; // ผลลัพธ์การค้นหา
  bool _isLoading = true; // สถานะโหลด
  bool _isSearching = false; // สถานะกำลังค้นหา
  bool _showDropdown = false; // โชว์ Dropdown ไหม
  Timer? _debounce; // ตัวหน่วงเวลาค้นหา

  // ★ 2. ตัวแปรเก็บ ShopID (ค่าเริ่มต้นเป็น 0 หรือ 1 ไปก่อน)
  int _currentShopId = 1; 

  @override
  void initState() {
    super.initState();
    // ★ 3. เรียกฟังก์ชันเตรียมข้อมูล (ดึง ShopID -> ดึงลูกหนี้)
    _initialData(); 
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ★ 4. ฟังก์ชันใหม่: ดึง ShopID จากเครื่อง แล้วค่อยดึงข้อมูล API
  Future<void> _initialData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // ถ้าไม่มีให้ใช้ค่า Default เป็น 1
      _currentShopId = prefs.getInt('shopId') ?? 1; 
    });
    
    print("Shop ID loaded: $_currentShopId"); // เช็คค่าใน Console
    _fetchAllDebtors(); // พอได้ ID แล้วค่อยไปดึง API
  }

  // --- ฟังก์ชันดึงลูกหนี้ทั้งหมด ---
  Future<void> _fetchAllDebtors() async {
    setState(() => _isLoading = true);
    try {
      // ส่ง _currentShopId ที่ดึงมาจาก prefs ไปใช้
      final result = await ApiDebtor.getDebtorsByShop(_currentShopId);
      setState(() {
        _allDebtors = result;
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

  // เลือกรายการจาก Dropdown
  void _selectFromDropdown(DebtorResponse debtor) {
    setState(() {
      _showDropdown = false;
      _searchController.text = ""; 
      FocusScope.of(context).unfocus(); 
    });
    Get.to(() => const DebtPaymentScreen()); 
  }

  // --- Widgets (ส่วนแสดงผลเหมือนเดิม) ---

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
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
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
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    onTap: () => _selectFromDropdown(item),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildDebtorCard(DebtorResponse debtor) {
    // Mock ยอดเงิน (รอ Backend ส่งมา)
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
                      Get.to(() => const DebtPaymentScreen()); 
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
                const SizedBox(height: 70), 
            

                const Text('รายชื่อทั้งหมด', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 10),

                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _allDebtors.isEmpty
                          ? const Center(child: Text("ยังไม่มีรายการค้างชำระ"))
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