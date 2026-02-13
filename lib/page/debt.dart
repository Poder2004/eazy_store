import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// --- Imports ---
import '../sale_producct/checkout_page.dart'; 
import 'package:eazy_store/page/debt_register.dart'; 
import '../api/api_debtor.dart'; 
import '../model/response/debtor_response.dart'; 

class DebtPage extends StatefulWidget {
  const DebtPage({super.key});

  @override
  State<DebtPage> createState() => _DebtPageState();
}

class _DebtPageState extends State<DebtPage> {
  // --- 1. Controller ประจำหน้านี้ ---
  final TextEditingController _debtorNameController = TextEditingController();
  final TextEditingController _debtorPhoneController = TextEditingController();
  final TextEditingController _payAmountController = TextEditingController();
  final TextEditingController _debtRemarkController = TextEditingController();

  // --- ตัวแปรสำหรับระบบค้นหา ---
  Timer? _debounce;
  bool _isSearching = false;
  List<DebtorResponse> _searchResults = [];
  bool _showResults = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _debtorNameController.dispose();
    _debtorPhoneController.dispose();
    _payAmountController.dispose();
    _debtRemarkController.dispose();
    super.dispose();
  }

  // ... (ฟังก์ชัน Search _onSearchChanged และ _selectDebtor เหมือนเดิม ไม่ต้องแก้) ...
  void _onSearchChanged(String keyword) {
    if (keyword.isEmpty) {
      setState(() {
        _searchResults = [];
        _showResults = false;
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
          _showResults = results.isNotEmpty;
        });
      } catch (e) {
        debugPrint("Error searching: $e");
        setState(() => _searchResults = []);
      } finally {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  void _selectDebtor(DebtorResponse debtor) {
    _debtorNameController.text = debtor.name;
    _debtorPhoneController.text = debtor.phone;
    setState(() {
      _showResults = false;
      FocusScope.of(context).unfocus();
    });
  }

  // =======================================================
  // ★★★ [จุดที่ 1] สร้างฟังก์ชันยืนยัน ตรงนี้เลย ★★★
  // =======================================================
  void _submitDebt(CheckoutController controller) {
    // 1. ดึงค่าจาก Text Controller ในหน้านี้โดยตรง
    String name = _debtorNameController.text;
    String phone = _debtorPhoneController.text;
    double payAmount = double.tryParse(_payAmountController.text) ?? 0;
    String remark = _debtRemarkController.text;

    // เช็คหน่อยว่าเลือกคนหรือยัง (Optional)
    if (name.isEmpty) {
      Get.snackbar("แจ้งเตือน", "กรุณาระบุชื่อลูกค้า", backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    // 2. คำนวณยอดค้าง (ยอดรวมจากตะกร้า - ที่จ่ายจริง)
    double total = controller.totalPrice;
    double debt = total - payAmount;

    // --- TODO: ตรงนี้ใส่โค้ดเรียก API บันทึกหนี้ ---
    print("--- บันทึกรายการ ---");
    print("ลูกค้า: $name, โทร: $phone");
    print("ยอดเต็ม: $total, จ่าย: $payAmount, แปะไว้: $debt");
    print("หมายเหตุ: $remark");

    // 3. ปิดหน้าจอและแจ้งเตือน
    Get.back(); // กลับไปหน้าขาย
    Get.snackbar(
      "สำเร็จ",
      "บันทึกค้างชำระเรียบร้อย (ค้าง $debt บาท)",
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );

    // 4. สั่งเคลียร์ตะกร้าสินค้าใน CheckoutController
    controller.clearAll(); 
  }

  @override
  Widget build(BuildContext context) {
    final CheckoutController controller = Get.find<CheckoutController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        centerTitle: true,
        title: const Text(
          "บันทึกค้างชำระ",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // ... (Search Bar และ List Search เหมือนเดิม) ...
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
            child: TextField(
              onChanged: (value) => _onSearchChanged(value),
              decoration: InputDecoration(
                hintText: 'พิมพ์ 0 หรือชื่อ/เบอร์ เพื่อค้นหา...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(strokeWidth: 2)))
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
           if (_showResults)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final item = _searchResults[i];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(backgroundColor: Colors.blue[100], child: Text(item.name.isNotEmpty ? item.name[0] : "?")),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item.phone),
                    trailing: const Icon(Icons.touch_app, size: 18, color: Colors.blue),
                    onTap: () => _selectDebtor(item),
                  );
                },
              ),
            ),
          
          if (!_showResults)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: () => Get.to(() => const DebtRegisterScreen()),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("สมัครบัญชีลูกหนี้"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300], foregroundColor: Colors.black87, elevation: 0),
                ),
              ),
            ),

          const Divider(thickness: 1),

          // ... (List รายการสินค้า เหมือนเดิม) ...
          Expanded(
            child: Obx(() {
              final groupedItems = <String, List<dynamic>>{};
              for (var item in controller.cartItems) {
                groupedItems.putIfAbsent(item.id, () => []).add(item);
              }
              if (groupedItems.isEmpty) return const Center(child: Text("ไม่มีสินค้าในตะกร้า"));
              
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: groupedItems.length,
                separatorBuilder: (context, index) => const SizedBox(height: 15),
                itemBuilder: (context, index) {
                  String key = groupedItems.keys.elementAt(index);
                  List<dynamic> items = groupedItems[key]!;
                  var item = items.first;
                  return Row(
                    children: [
                      _buildQtyCounter(item, controller),
                      const SizedBox(width: 15),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("${items.length} ${item.category == 'เครื่องดื่ม' ? 'ขวด' : 'ชิ้น'}", style: TextStyle(color: Colors.grey[600])),
                        ])),
                      Text("${(item.price * items.length).toInt()} บาท", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  );
                },
              );
            }),
          ),

          // --- Summary Section ---
          _buildSummarySection(controller),
        ],
      ),
    );
  }

  Widget _buildSummarySection(CheckoutController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Column(
        children: [
          Obx(() => _rowLabelValue("รวมทั้งหมด", "${controller.totalPrice.toInt()} บาท", isBold: true)),
          const Divider(height: 25),

          _rowInfo("ชื่อคนเซ็น", _debtorNameController.text.isEmpty ? "-" : _debtorNameController.text, isBold: true),
          _rowInputSimple("เบอร์โทรศัพท์", _textField(_debtorPhoneController, readOnly: true)),
          _rowInput("จ่ายวันนี้", _textField(_payAmountController, isNumber: true)),

          Builder(
            builder: (_) {
              double pay = double.tryParse(_payAmountController.text) ?? 0;
              int debt = (controller.totalPrice - pay).toInt(); 
              return _rowInfo("ยอดที่แปะไว้", "$debt", isRed: true);
            },
          ),

          _rowInput("หมายเหตุ", _textField(_debtRemarkController), unit: ""),
          const SizedBox(height: 20),

          Column(
            children: [
              // =======================================================
              // ★★★ [จุดที่ 2] เรียกใช้ฟังก์ชัน local ที่สร้างไว้ ★★★
              // =======================================================
              _actionBtn("ยืนยันการค้างชำระ", Colors.black, () {
                 _submitDebt(controller);
              }),
              
              const SizedBox(height: 10),
              _actionBtn("ล้างรายการ", Colors.white, () {
                setState(() {
                    _debtorNameController.clear();
                    _debtorPhoneController.clear();
                    _payAmountController.clear();
                    _debtRemarkController.clear();
                });
                controller.clearAll();
              }, isOutlined: true),
            ],
          ),
        ],
      ),
    );
  }

  // ... (Helper Widgets ด้านล่างเหมือนเดิมเป๊ะ) ...
  Widget _rowLabelValue(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 18, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _rowInfo(String label, String value, {bool isBold = false, bool isRed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Container(
            width: 150, alignment: Alignment.center,
            child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isRed ? Colors.red : Colors.black)),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _rowInput(String label, Widget inputWidget, {String unit = "บาท"}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 150, height: 35, child: inputWidget),
          const SizedBox(width: 10),
          SizedBox(width: 30, child: Text(unit, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _rowInputSimple(String label, Widget inputWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 190, height: 35, child: inputWidget),
        ],
      ),
    );
  }

  Widget _buildQtyCounter(dynamic item, CheckoutController controller) {
    return Column(
      children: [
        _miniBtn(Icons.add, () => controller.increaseItem(item)),
        const SizedBox(height: 5),
        _miniBtn(Icons.remove, () => controller.decreaseItem(item)),
      ],
    );
  }

  Widget _miniBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
        child: Icon(icon, size: 18, color: Colors.black54),
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, {bool isNumber = false, bool readOnly = false}) {
    return TextField(
      controller: ctrl,
      readOnly: readOnly,
      onChanged: (v) { setState(() {}); },
      textAlign: TextAlign.center,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        filled: readOnly,
        fillColor: readOnly ? Colors.grey[100] : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
      ),
    );
  }

  Widget _actionBtn(String label, Color bgColor, VoidCallback onTap, {bool isOutlined = false}) {
    return SizedBox(
      width: double.infinity, height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: isOutlined ? Colors.black : Colors.white,
          side: isOutlined ? const BorderSide(color: Colors.black54) : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}