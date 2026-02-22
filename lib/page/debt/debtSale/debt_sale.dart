import 'package:flutter/material.dart';
import 'package:get/get.dart';

// --- Imports ---
import '../../sale_producct/sale/checkout_controller.dart';
import 'package:eazy_store/page/debt/debtRegister/debt_register.dart';
import 'debt_sale_controller.dart';

class DebtSalePage extends StatelessWidget {
  DebtSalePage({super.key});

  // เรียกใช้ Controller ประจำหน้า และ Controller ตะกร้าสินค้า
  final DebtSaleController controller = Get.put(DebtSaleController());
  final CheckoutController checkoutController = Get.find<CheckoutController>();

  @override
  Widget build(BuildContext context) {
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
            child: _buildSearchBar(),
          ),
          Obx(() {
            if (controller.showResults.value) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(10),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: controller.searchResults.length,
                  separatorBuilder: (ctx, i) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final item = controller.searchResults[i];
                    final String? profileImage = item.imgDebtor;
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        backgroundImage:
                            (profileImage != null && profileImage.isNotEmpty)
                            ? NetworkImage(
                                profileImage,
                              ) // *หมายเหตุ: ถ้า API ส่งมาแค่ path อย่าลืมต่อ Base URL นะครับ
                            : null,
                        // ถ้าไม่มีรูป ให้โชว์ตัวอักษรตัวแรกสีเทาๆ แทน
                        child: (profileImage == null || profileImage.isEmpty)
                            ? Text(
                                item.name.isNotEmpty ? item.name[0] : "?",
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(item.phone),
                      trailing: const Icon(
                        Icons.search,
                        size: 20,
                        color: Colors.grey,
                      ),
                      onTap: () => controller.selectDebtor(item),
                    );
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          Obx(() {
            if (!controller.showResults.value) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: () => Get.to(() => DebtRegisterScreen()),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("สมัครบัญชีลูกหนี้"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                      elevation: 0,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          const Divider(thickness: 1),

          // รายการสินค้า
          Expanded(
            child: Obx(() {
              final groupedItems = <String, List<dynamic>>{};
              for (var item in checkoutController.cartItems) {
                groupedItems.putIfAbsent(item.id, () => []).add(item);
              }
              if (groupedItems.isEmpty)
                return const Center(child: Text("ไม่มีสินค้าในตะกร้า"));

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: groupedItems.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 15),
                itemBuilder: (context, index) {
                  String key = groupedItems.keys.elementAt(index);
                  List<dynamic> items = groupedItems[key]!;
                  var item = items.first;
                  return Row(
                    children: [
                      _buildQtyCounter(item, checkoutController),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "${items.length} ${item.category == 'เครื่องดื่ม' ? 'ขวด' : 'ชิ้น'}",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "${(item.price * items.length).toInt()} บาท",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  );
                },
              );
            }),
          ),

          // Summary Section
          _buildSummarySection(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[100], // ใช้สีให้เข้ากับธีมหน้านี้
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.grey.shade300, width: 1.0),
      ),
      child: TextField(
        controller: controller
            .searchController, // เช็คใน Controller ด้วยว่ามีตัวแปรนี้นะครับ
        onChanged: controller.onSearchChanged,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'กรอกชื่อหรือเบอร์ลูกหนี้เพื่อค้นหา',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10.0,
            horizontal: 12.0,
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),

          // ✅ รวมร่าง! โชว์ตัวโหลดตอนหา และโชว์กากบาทตอนพิมพ์
          suffixIcon: Obx(() {
            if (controller.isSearching.value) {
              return const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            } else if (!controller.isSearchEmpty.value) {
              return IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: controller.clearSearch,
              );
            }
            return const SizedBox.shrink(); // ถ้าไม่ได้พิมพ์อะไรเลย ก็ไม่ต้องโชว์อะไร
          }),

          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Obx(
            () => _rowLabelValue(
              "รวมทั้งหมด",
              "${checkoutController.totalPrice.toInt()} บาท",
              isBold: true,
            ),
          ),
          const Divider(height: 25),

          // ใช้ ValueListenableBuilder เพื่อให้ชื่ออัปเดตอัตโนมัติเมื่อเลือก
          ValueListenableBuilder(
            valueListenable: controller.debtorNameController,
            builder: (context, value, child) {
              return _rowInfo(
                "ชื่อคนเซ็น",
                value.text.isEmpty ? "-" : value.text,
                isBold: true,
              );
            },
          ),
          _rowInputSimple(
            "เบอร์โทรศัพท์",
            _textField(controller.debtorPhoneController, readOnly: true),
          ),
          _rowInput(
            "จ่ายตอนนี้",
            _textField(controller.payAmountController, isNumber: true),
          ),

          Obx(() {
            int debt =
                (checkoutController.totalPrice - controller.payAmount.value)
                    .toInt();
            return _rowInfo("ยอดที่เซ็น", "$debt", isRed: true);
          }),

          _rowInput(
            "หมายเหตุ",
            _textField(controller.debtRemarkController),
            unit: "",
          ),
          const SizedBox(height: 20),

          Column(
            children: [
              _actionBtn("ยืนยันการค้างชำระ", Colors.black, () {
                controller.confirmSubmit(checkoutController);
              }),
              const SizedBox(height: 10),
              _actionBtn("ล้างรายการ", Colors.white, () {
                controller.clearForm(checkoutController);
              }, isOutlined: true),
            ],
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _rowLabelValue(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _rowInfo(
    String label,
    String value, {
    bool isBold = false,
    bool isRed = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
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
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 150, height: 35, child: inputWidget),
          const SizedBox(width: 10),
          SizedBox(
            width: 30,
            child: Text(
              unit,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
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
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
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

  Widget _textField(
    TextEditingController ctrl, {
    bool isNumber = false,
    bool readOnly = false,
  }) {
    return TextField(
      controller: ctrl,
      readOnly: readOnly,
      textAlign: TextAlign.center,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        filled: readOnly,
        fillColor: readOnly ? Colors.grey[100] : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
    );
  }

  Widget _actionBtn(
    String label,
    Color bgColor,
    VoidCallback onTap, {
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: isOutlined ? Colors.black : Colors.white,
          side: isOutlined ? const BorderSide(color: Colors.black54) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
