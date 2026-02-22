import 'package:flutter/material.dart';
import '../../../model/response/debtor_response.dart';
import 'debtor_detail_controller.dart'; // import ไฟล์ Controller เข้ามา

class DebtorDetailScreen extends StatefulWidget {
  final DebtorResponse debtor;

  const DebtorDetailScreen({super.key, required this.debtor});

  @override
  State<DebtorDetailScreen> createState() => _DebtorDetailScreenState();
}

class _DebtorDetailScreenState extends State<DebtorDetailScreen> {
  // สร้างตัวแปรเรียกใช้งาน Controller
  final DebtorDetailController _controller = DebtorDetailController();

  @override
  void initState() {
    super.initState();
    _controller.init(widget.debtor); // โยนข้อมูลตั้งต้นให้ Controller
    
    // สั่งให้หน้าจอรีเฟรชตัวเอง (setState) เมื่อ Controller สั่ง notifyListeners()
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // เคลียร์หน่วยความจำเมื่อปิดหน้าจอ
    super.dispose();
  }

  // ให้อยู่ในหน้า UI เพราะต้องใช้งาน BuildContext และ TextField
  void _editDebtorInfo() {
    final nameController = TextEditingController(text: _controller.currentDebtor.name);
    final phoneController = TextEditingController(text: _controller.currentDebtor.phone);
    final addressController = TextEditingController(text: _controller.currentDebtor.address ?? "");
    final creditController = TextEditingController(text: _controller.currentDebtor.creditLimit.toStringAsFixed(0));

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
                maxLines: 2,
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
              // ส่งข้อมูลที่แก้ ไปให้ Controller จัดการ
              _controller.updateDebtorData(
                name: nameController.text,
                phone: phoneController.text,
                address: addressController.text,
                creditLimit: double.tryParse(creditController.text) ?? 0,
              );
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
              child: Text(
                "ประวัติการติดหนี้",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _buildHistoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final debtor = _controller.currentDebtor;
    
    double percentUsed = debtor.creditLimit > 0 ? (debtor.currentDebt / debtor.creditLimit) : 1.0;
    if (percentUsed > 1.0) percentUsed = 1.0;
    double availableCredit = debtor.creditLimit - debtor.currentDebt;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
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
                    Text(
                      debtor.name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text(
                          debtor.phone,
                          style: TextStyle(color: Colors.grey[700], fontSize: 16),
                        ),
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
                            debtor.address ?? "ไม่ระบุที่อยู่",
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
              ),
            ],
          ),
          const Divider(height: 30),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("ยอดหนี้ปัจจุบัน", style: TextStyle(fontSize: 16)),
                  Text(
                    "${debtor.currentDebt.toStringAsFixed(0)} บาท",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentUsed,
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percentUsed > 0.8 ? Colors.red : Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "วงเงิน: ${debtor.creditLimit.toStringAsFixed(0)}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    "เครดิตคงเหลือ: ${availableCredit.toStringAsFixed(0)}",
                    style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    if (_controller.isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
    }
    if (_controller.historyList.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("ไม่พบประวัติการติดหนี้")));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _controller.historyList.length,
      itemBuilder: (context, index) {
        final history = _controller.historyList[index];
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
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(3),
                        1: FlexColumnWidth(1.5),
                        2: FlexColumnWidth(2.5),
                        3: FlexColumnWidth(2),
                      },
                      children: [
                        const TableRow(
                          children: [
                            Text("ชื่อ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                            Text("จำนวน", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                            Text("ราคา/ชิ้น", textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                            Text("ราคารวม", textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                          ],
                        ),
                        ...history.items.map((item) {
                          double pricePerUnit = item.qty > 0 ? (item.price / item.qty) : 0;
                          return TableRow(
                            children: [
                              Padding(padding: const EdgeInsets.only(top: 8), child: Text(item.name, style: const TextStyle(fontSize: 13))),
                              Padding(padding: const EdgeInsets.only(top: 8), child: Text("${item.qty}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 13))),
                              Padding(padding: const EdgeInsets.only(top: 8), child: Text(pricePerUnit.toStringAsFixed(0), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13))),
                              Padding(padding: const EdgeInsets.only(top: 8), child: Text(item.price.toStringAsFixed(0), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13))),
                            ],
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("รวมทั้งสิ้น", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("${history.totalAmount} บาท", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}