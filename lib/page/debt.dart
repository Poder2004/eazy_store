import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../sale_producct/checkout_page.dart';
import 'package:eazy_store/page/debt_register.dart';

class DebtPage extends StatelessWidget {
  const DebtPage({super.key});

  void registerNewDebtor() {
    Get.to(() => const DebtRegisterScreen());
  }

  @override
  Widget build(BuildContext context) {
    // ดึง Controller เดิมมาใช้เพื่อให้ข้อมูลสินค้าตรงกัน
    final CheckoutController controller = Get.find<CheckoutController>();

    // สร้างตัวแปรภายในสำหรับคำนวณยอดเซ็น
    final RxDouble debtAmount = 0.0.obs;

    // ฟังการเปลี่ยนแปลงของช่อง "จ่าย" เพื่อคำนวณ "จำนวนที่เซ็น"
    controller.payAmountController.addListener(() {
      double pay = double.tryParse(controller.payAmountController.text) ?? 0;
      debtAmount.value = controller.totalPrice - pay;
    });

    // ตั้งค่าเริ่มต้น
    debtAmount.value =
        controller.totalPrice -
        (double.tryParse(controller.payAmountController.text) ?? 0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text("ค้างชำระ", style: TextStyle(color: Colors.black)),
      ),
      body: Column(
        children: [
          // 1. ส่วนค้นหาชื่อลูกหนี้
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                TextField(
                  controller: controller.debtorNameController,
                  decoration: InputDecoration(
                    hintText: 'ค้นหารายชื่อ',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    // เรียกใช้ฟังก์ชันที่ประกาศไว้ใน CheckoutController
                    onPressed: () => controller.registerNewDebtor(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("สมัครบัญชีลูกหนี้"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "รายการสินค้า",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // 2. รายการสินค้าในตะกร้า
          Expanded(
            child: Obx(() {
              // จัดกลุ่มสินค้าเหมือนในหน้า Checkout
              final groupedItems = <String, List<ProductItem>>{};
              for (var item in controller.cartItems) {
                groupedItems.putIfAbsent(item.id, () => []).add(item);
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: groupedItems.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  String key = groupedItems.keys.elementAt(index);
                  List<ProductItem> items = groupedItems[key]!;
                  var firstItem = items.first;

                  return Row(
                    children: [
                      _buildQtyCounter(firstItem, items.length, controller),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              firstItem.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${items.length} ${firstItem.category == 'เครื่องดื่ม' ? 'ขวด' : 'ชิ้น'}",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${(firstItem.price * items.length).toInt()} บาท",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "${firstItem.price.toInt()}",
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            }),
          ),

          // 3. สรุปยอดและฟอร์มกรอกข้อมูล (ส่วนล่าง)
          _buildSummarySection(controller, debtAmount),
        ],
      ),
    );
  }

  Widget _buildQtyCounter(
    ProductItem item,
    int qty,
    CheckoutController controller,
  ) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => controller.increaseItem(item),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.add, size: 16),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => controller.decreaseItem(item),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.remove, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySection(
    CheckoutController controller,
    RxDouble debtAmount,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          _rowLabelValue(
            "รวมทั้งหมด",
            "${controller.totalPrice.toInt()} บาท",
            isBold: true,
          ),
          const Divider(height: 30),
          _rowInput(
            "ชื่อคนเซ็น",
            Text(
              controller.debtorNameController.text.isEmpty
                  ? "สมศรี"
                  : controller.debtorNameController.text,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          _rowInput("จ่าย", _textField(controller.payAmountController)),
          _rowInput(
            "จำนวนที่เซ็น",
            Obx(
              () => _textField(
                TextEditingController(
                  text: debtAmount.value.toInt().toString(),
                ),
                readOnly: true,
              ),
            ),
          ),
          _rowInput(
            "เบอร์โทรศัพท์",
            _textField(TextEditingController()),
          ), // เพิ่ม Controller ตามความเหมาะสม
          _rowInput("หมายเหตุ", _textField(controller.debtRemarkController)),
          const SizedBox(height: 20),

          // ปุ่มยืนยัน
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: () => controller.confirmPayment(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
              child: const Text("ค้างชำระ"),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: OutlinedButton(
              onPressed: () => controller.clearAll(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.black),
              ),
              child: const Text(
                "ล้างทั้งหมด",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowLabelValue(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _rowInput(String label, Widget inputWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 180, height: 35, child: inputWidget),
          const SizedBox(width: 10),
          const Text("บาท"),
        ],
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, {bool readOnly = false}) {
    return TextField(
      controller: ctrl,
      readOnly: readOnly,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
      ),
    );
  }
}
