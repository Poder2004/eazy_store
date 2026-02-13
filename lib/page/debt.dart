import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// --- Imports ที่จำเป็น (ตรวจสอบ path ให้ตรงกับเครื่องคุณ) ---
import '../sale_producct/checkout_page.dart'; // ที่อยู่ของ CheckoutController
import 'package:eazy_store/page/debt_register.dart'; // หน้าสมัครลูกหนี้
import '../api/api_debtor.dart'; // ไฟล์ API
import '../model/response/debtor_response.dart'; // ไฟล์ Model Response

class DebtPage extends StatefulWidget {
  const DebtPage({super.key});

  @override
  State<DebtPage> createState() => _DebtPageState();
}

class _DebtPageState extends State<DebtPage> {
  // --- ตัวแปรสำหรับระบบค้นหา ---
  Timer? _debounce; // ตัวหน่วงเวลา
  bool _isSearching = false; // สถานะกำลังโหลด
  List<DebtorResponse> _searchResults = []; // ลิสต์ผลลัพธ์ (ใช้ Type DebtorResponse)
  bool _showResults = false; // สถานะแสดง List

  // ฟังก์ชันค้นหา (ทำงานเมื่อพิมพ์)
  void _onSearchChanged(String keyword, CheckoutController controller) {
    if (keyword.isEmpty) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
      // เคลียร์ค่าใน Controller ถ้าต้องการ
      // controller.debtorNameController.clear();
      // controller.debtorPhoneController.clear();
      return;
    }

    // ยกเลิก Timer เก่าถ้ายังทำงานอยู่
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // เริ่มนับเวลาใหม่ 300ms (0.3 วินาที)
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isSearching = true);

      try {
        // เรียก API ค้นหา
        final results = await ApiDebtor.searchDebtor(keyword);
        
        setState(() {
          _searchResults = results;
          _showResults = results.isNotEmpty; // ถ้ามีข้อมูลให้โชว์ List
        });
      } catch (e) {
        debugPrint("Error searching debtor: $e");
        setState(() => _searchResults = []);
      } finally {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  // ฟังก์ชันเมื่อเลือกรายชื่อจาก List
  void _selectDebtor(DebtorResponse debtor, CheckoutController controller) {
    // 1. นำข้อมูลใส่ Controller
    controller.debtorNameController.text = debtor.name;
    controller.debtorPhoneController.text = debtor.phone;
    
    // *สำคัญ* ถ้าใน Controller มีตัวแปร debtorId ให้ใส่ด้วย
    // controller.selectedDebtorId = debtor.debtorId; 

    controller.update(); // อัปเดตหน้าจอส่วนสรุปยอด

    // 2. ปิด List และคีย์บอร์ด
    setState(() {
      _showResults = false;
      FocusScope.of(context).unfocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ดึง Controller มาใช้
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
          "บันทึกค้างชำระ (แปะ)",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // ---------------------------------------------------
          // 1. ส่วนค้นหา (Search Bar)
          // ---------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
            child: TextField(
              onChanged: (value) => _onSearchChanged(value, controller),
              decoration: InputDecoration(
                hintText: 'พิมพ์ 0 หรือชื่อ/เบอร์ เพื่อค้นหา...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ---------------------------------------------------
          // 2. ส่วนแสดงผลลัพธ์การค้นหา (Dropdown List)
          // ---------------------------------------------------
          if (_showResults)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              constraints: const BoxConstraints(maxHeight: 250), // จำกัดความสูง
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final item = _searchResults[i];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Text(item.name.isNotEmpty ? item.name[0] : "?"),
                    ),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item.phone),
                    trailing: const Icon(Icons.touch_app, size: 18, color: Colors.blue),
                    onTap: () => _selectDebtor(item, controller),
                  );
                },
              ),
            ),

          // ปุ่มสมัครสมาชิกใหม่ (แสดงเมื่อไม่ได้ค้นหา)
          if (!_showResults) // ซ่อนปุ่มนี้ถ้ากำลังโชว์ list search จะได้ไม่เกะกะ

            Padding(

              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),

              child: Align(

                alignment: Alignment.centerLeft,

                child: ElevatedButton.icon(

                  onPressed: () => Get.to(() => const DebtRegisterScreen()),

                  icon: const Icon(Icons.add, size: 18),

                  label: const Text("สมัครบัญชีลูกหนี้"),

                  style: ElevatedButton.styleFrom(

                    backgroundColor: Colors.grey[300],

                    foregroundColor: Colors.black87,

                    elevation: 0,

                  ),

                ),

              ),

            ),

          const Divider(thickness: 1),

          // ---------------------------------------------------
          // 3. รายการสินค้า (Cart Items)
          // ---------------------------------------------------
          Expanded(
            child: Obx(() {
              // Group สินค้าเหมือนเดิม
              final groupedItems = <String, List<dynamic>>{};
              for (var item in controller.cartItems) {
                groupedItems.putIfAbsent(item.id, () => []).add(item);
              }

              if (groupedItems.isEmpty) {
                return const Center(child: Text("ไม่มีสินค้าในตะกร้า"));
              }

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
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(
                              "${items.length} ${item.category == 'เครื่องดื่ม' ? 'ขวด' : 'ชิ้น'}",
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      )),
                      Text("${(item.price * items.length).toInt()} บาท",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  );
                },
              );
            }),
          ),

          // ---------------------------------------------------
          // 4. ส่วนสรุปยอด (Summary)
          // ---------------------------------------------------
          _buildSummarySection(controller),
        ],
      ),
    );
  }

  // --- Widgets ย่อย ---

  Widget _buildSummarySection(CheckoutController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: Column(
        children: [
          // ยอดรวม
          Obx(() => _rowLabelValue(
              "รวมทั้งหมด", "${controller.totalPrice.toInt()} บาท",
              isBold: true)),
          const Divider(height: 25),

          // ชื่อคนเซ็น (ดึงจาก Controller)
          GetBuilder<CheckoutController>(
            builder: (_) => _rowInfo(
              "ชื่อคนเซ็น",
              controller.debtorNameController.text.isEmpty
                  ? "-"
                  : controller.debtorNameController.text,
              isBold: true,
            ),
          ),

          // เบอร์โทรศัพท์ (ReadOnly - ห้ามแก้)
          GetBuilder<CheckoutController>(
            builder: (_) => _rowInputSimple(
              "เบอร์โทรศัพท์",
              _textField(controller.debtorPhoneController, readOnly: true),
            ),
          ),

          // ช่องกรอกยอดจ่ายจริง
          _rowInput("จ่ายวันนี้",
              _textField(controller.payAmountController, isNumber: true)),

          // คำนวณยอดค้างชำระ
          GetBuilder<CheckoutController>(
            builder: (_) {
              double pay =
                  double.tryParse(controller.payAmountController.text) ?? 0;
              int debt = (controller.totalPrice - pay).toInt();
              return _rowInfo("ยอดที่แปะไว้", "$debt", isRed: true);
            },
          ),

          // หมายเหตุ
          _rowInput(
              "หมายเหตุ", _textField(controller.debtRemarkController), unit: ""),

          const SizedBox(height: 20),

          // ปุ่ม Action
          Column(
            children: [
              _actionBtn("ยืนยันการค้างชำระ", Colors.black,
                  () => controller.confirmPayment()),
              const SizedBox(height: 10),
              _actionBtn("ล้างรายการ", Colors.white,
                  () => controller.clearAll(), isOutlined: true),
            ],
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets (เหมือนเดิม) ---

  Widget _rowLabelValue(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 18,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _rowInfo(String label, String value,
      {bool isBold = false, bool isRed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Container(
            width: 150,
            alignment: Alignment.center,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isRed ? Colors.red : Colors.black,
              ),
            ),
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
          Expanded(
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 150, height: 35, child: inputWidget),
          const SizedBox(width: 10),
          SizedBox(
              width: 30,
              child: Text(unit, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _rowInputSimple(String label, Widget inputWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
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
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 18, color: Colors.black54),
      ),
    );
  }

  Widget _textField(TextEditingController ctrl,
      {bool isNumber = false, bool readOnly = false}) {
    return TextField(
      controller: ctrl,
      readOnly: readOnly,
      // บังคับ Cursor ไปหลังสุดเมื่อพิมพ์
      onChanged: (v) {
        if (!readOnly) {
           // ใส่ setState เพื่อให้ UI อัปเดตทันที (เช่น ยอดคงเหลือ)
           // แต่ต้องระวังเรื่อง cursor เด้ง (วิธีแก้ง่ายสุดคือใช้ controller.selection)
           // แต่ในที่นี้เราใช้ GetBuilder คุมคำนวณแล้ว อาจไม่จำเป็นต้อง setState ตรงนี้
           // ctrl.selection = TextSelection.fromPosition(TextPosition(offset: ctrl.text.length));
           final controller = Get.find<CheckoutController>();
           controller.update();
        }
      },
      textAlign: TextAlign.center,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        filled: readOnly,
        fillColor: readOnly ? Colors.grey[100] : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!)),
      ),
    );
  }

  Widget _actionBtn(String label, Color bgColor, VoidCallback onTap,
      {bool isOutlined = false}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: isOutlined ? Colors.black : Colors.white,
          side: isOutlined ? const BorderSide(color: Colors.black54) : null,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}