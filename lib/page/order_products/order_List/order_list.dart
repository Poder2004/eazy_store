import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eazy_store/page/menu_bar/bottom_navbar.dart';
import 'package:eazy_store/page/order_products/buyProducts/buy_products.dart';
import 'order_list_controller.dart'; // Import controller ที่แยกออกมา

// --- CONSTANTS ---
const Color _kPrimaryColor = Color(0xFF6B8E23);
const Color _kSecondaryButtonColor = Color(0xFF5390F2);
const Color _kBackgroundColor = Color(0xFFF7F7F7);
const Color _kInputFillColor = Color(0xFFF0F0E0);

class OrderListScreen extends StatelessWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // เรียกใช้งาน Controller
    final controller = Get.put(OrderListController());

    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: const Text('รายการสั่งของ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: true,
        backgroundColor: _kBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() => controller.orderItems.isEmpty
                ? const Center(child: Text('ไม่มีรายการสินค้าที่ต้องสั่งซื้อ'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
                    itemCount: controller.orderItems.length,
                    itemBuilder: (context, index) => 
                      _buildOrderItemCard(controller.orderItems[index], controller),
                  )),
          ),
          _buildBottomActionArea(controller),
        ],
      ),
      bottomNavigationBar: Obx(() => BottomNavBar(
            currentIndex: controller.selectedIndex.value,
            onTap: controller.onTabTapped,
          )),
    );
  }

  Widget _buildOrderItemCard(OrderItem item, OrderListController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15.0),
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(item.imageUrl, width: 70, height: 70, fit: BoxFit.cover),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Text('ใส่จำนวนและหมายเหตุ:', style: TextStyle(fontSize: 14, color: Colors.black45)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => controller.showDeleteConfirmation(item),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('จำนวน:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(width: 10),
              _buildQtyBtn(Icons.remove, () => controller.updateQuantity(item, -1)),
              _buildQtyField(item.quantityController, (v) {
                if (v.isEmpty || v == '0') controller.showDeleteConfirmation(item);
              }),
              _buildQtyBtn(Icons.add, () => controller.updateQuantity(item, 1)),
              const SizedBox(width: 10),
              Text(item.unit, style: const TextStyle(fontSize: 16, color: Colors.black54)),
              const SizedBox(width: 15),
            ],
          ),
          const SizedBox(height: 15),
          TextField(
            controller: item.noteController,
            decoration: InputDecoration(
              hintText: 'เพิ่มหมายเหตุ (ถ้ามี)',
              prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(color: _kPrimaryColor, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildQtyField(TextEditingController ctrl, Function(String) onChange) {
    return SizedBox(
      width: 70, height: 35,
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        onChanged: onChange,
        decoration: InputDecoration(
          filled: true, fillColor: _kInputFillColor,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildBottomActionArea(OrderListController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -3))]),
      child: SafeArea(
        child: Column(
          children: [
            _buildBigButton('เพิ่มรายการสินค้า', Icons.add, _kPrimaryColor, () => Get.to(() => const BuyProductsScreen())),
            const SizedBox(height: 10),
           // _buildBigButton('ส่งออกเป็น PDF', Icons.picture_as_pdf, _kSecondaryButtonColor, () => controller.exportToPdf()),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildBigButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 55, width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      ),
    );
  }
}