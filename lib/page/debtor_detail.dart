// file: page/debtor_detail_screen.dart

import 'package:flutter/material.dart';
import '../model/response/debtor_response.dart';
import '../model/request/debtor_history_model.dart'; // import model ที่เพิ่งสร้าง
// import '../api/api_debtor.dart'; // อย่าลืม import API จริงของคุณ

class DebtorDetailScreen extends StatefulWidget {
  final DebtorResponse debtor;

  const DebtorDetailScreen({super.key, required this.debtor});

  @override
  State<DebtorDetailScreen> createState() => _DebtorDetailScreenState();
}

class _DebtorDetailScreenState extends State<DebtorDetailScreen> {
  late DebtorResponse _currentDebtor;
  List<DebtorHistoryResponse> _historyList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentDebtor = widget.debtor;
    _fetchHistory();
  }

  // จำลองการดึงข้อมูลประวัติ (เปลี่ยนเป็น API จริงของคุณตรงนี้)
  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      // final result = await ApiDebtor.getHistory(_currentDebtor.id); // เรียก API จริง
      
      // ★ Mock Data (สมมติว่าได้ข้อมูลมาแบบนี้) ★
      await Future.delayed(const Duration(seconds: 1)); 
      final mockData = [
        DebtorHistoryResponse(
          orderId: 101,
          date: "15 ต.ค. 2023 14:30",
          totalAmount: 500.0,
          paidAmount: 200.0,
          remainingAmount: 300.0,
          items: [
            DebtorHistoryItem(name: "ปุ๋ยสูตรเสมอ", qty: 1, price: 450),
            DebtorHistoryItem(name: "ถุงมือผ้า", qty: 2, price: 25),
          ],
        ),
        DebtorHistoryResponse(
          orderId: 99,
          date: "10 ต.ค. 2023 09:15",
          totalAmount: 1200.0,
          paidAmount: 0.0,
          remainingAmount: 1200.0,
          items: [
            DebtorHistoryItem(name: "อาหารไก่", qty: 2, price: 600),
          ],
        ),
      ];
      
      setState(() {
        _historyList = mockData;
        _isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() => _isLoading = false);
    }
  }

  // ฟังก์ชันแก้ไขข้อมูลลูกหนี้
  void _editDebtorInfo() {
    final nameController = TextEditingController(text: _currentDebtor.name);
    final phoneController = TextEditingController(text: _currentDebtor.phone);
    final addressController = TextEditingController(text: _currentDebtor.address ?? "");
    final creditController = TextEditingController(text: _currentDebtor.creditLimit.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("แก้ไขข้อมูลลูกหนี้"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "ชื่อ-นามสกุล", icon: Icon(Icons.person)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "เบอร์โทรศัพท์", icon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: "ที่อยู่", icon: Icon(Icons.home)),
                maxLines: 2, // ให้พิมพ์ได้หลายบรรทัด
              ),
              const SizedBox(height: 10),
              TextField(
                controller: creditController,
                decoration: const InputDecoration(labelText: "วงเงินเครดิต (บาท)", icon: Icon(Icons.credit_card)),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: เรียก API Update (ส่ง address, creditLimit ไปด้วย)
              setState(() {
                // อัปเดตค่าในหน้าจอทันที (จำลอง)
                // ในการใช้งานจริงต้องสร้าง Object ใหม่จาก Response ของ API
                 /* _currentDebtor = DebtorResponse(
                     id: _currentDebtor.id,
                     name: nameController.text,
                     phone: phoneController.text,
                     address: addressController.text,
                     creditLimit: double.tryParse(creditController.text) ?? 0,
                     currentDebt: _currentDebtor.currentDebt,
                 ); */
              });
              Navigator.pop(context);
            },
            child: const Text("บันทึก"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("รายละเอียดลูกหนี้"),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFFF7F7F7),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text("ประวัติการติดหนี้", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            _buildHistoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    // คำนวณ % การใช้เครดิต
    double percentUsed = _currentDebtor.creditLimit > 0 
        ? (_currentDebtor.currentDebt / _currentDebtor.creditLimit) 
        : 1.0;
    if (percentUsed > 1.0) percentUsed = 1.0; // กันเกินหลอด

    double availableCredit = _currentDebtor.creditLimit - _currentDebtor.currentDebt;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ส่วนหัว: รูป + ชื่อ + เบอร์
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.blue.shade50,
                child: const Icon(Icons.person, size: 40, color: Colors.blue),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_currentDebtor.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text(_currentDebtor.phone, style: TextStyle(color: Colors.grey[700], fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _currentDebtor.address ?? "ไม่ระบุที่อยู่", 
                            style: TextStyle(color: Colors.grey[700], fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_note, color: Colors.blue, size: 30),
                onPressed: _editDebtorInfo,
              )
            ],
          ),
          
          const Divider(height: 30),

          // ส่วนแสดงสถานะเครดิต
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("ยอดหนี้ปัจจุบัน", style: TextStyle(fontSize: 16)),
                  Text(
                    "${_currentDebtor.currentDebt.toStringAsFixed(0)} บาท",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // หลอดแสดงเปอร์เซ็นต์
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentUsed,
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percentUsed > 0.8 ? Colors.red : Colors.green, // ถ้าใช้เกิน 80% หลอดเป็นสีแดง
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // รายละเอียดวงเงิน
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("วงเงิน: ${_currentDebtor.creditLimit.toStringAsFixed(0)}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  Text("เครดิตคงเหลือ: ${availableCredit.toStringAsFixed(0)}", style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_isLoading) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
    if (_historyList.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("ไม่พบประวัติการติดหนี้")));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _historyList.length,
      itemBuilder: (context, index) {
        final history = _historyList[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(history.date, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text("ยอดบิล: ${history.totalAmount} บาท"),
                if (history.paidAmount > 0)
                  Text("จ่ายแล้ว: ${history.paidAmount} บาท", style: const TextStyle(color: Colors.green, fontSize: 12)),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text("คงเหลือ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  "${history.remainingAmount}", 
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            children: [
              Container(
                color: Colors.grey.shade50,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("รายการสินค้า", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    ...history.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("${item.name} x${item.qty}"),
                          Text("${item.price * item.qty}"),
                        ],
                      ),
                    )),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("รวมทั้งสิ้น", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("${history.totalAmount} บาท", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}