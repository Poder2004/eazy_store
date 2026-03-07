import 'package:flutter/material.dart';
import 'package:get/get.dart';
// Import controller ของหน้าซื้อสินค้า (ปรับ path ให้ตรงกับโปรเจกต์คุณ)
import 'package:eazy_store/page/order_products/buyProducts/buy_products_controller.dart';

class OrderItem {
  final String id;
  final String name;
  final String unit;
  final String imageUrl;
  final TextEditingController quantityController;
  final TextEditingController noteController;

  OrderItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.imageUrl,
    required int initialQuantity,
    String initialNote = '',
  }) : quantityController = TextEditingController(
         text: initialQuantity.toString(),
       ),
       noteController = TextEditingController(text: initialNote);

  void dispose() {
    quantityController.dispose();
    noteController.dispose();
  }
}

class OrderListController extends GetxController {
  var orderItems = <OrderItem>[].obs;
  var selectedIndex = 4.obs;

  @override
  void onInit() {
    super.onInit();
    loadItemsFromBuyPage(); // เปลี่ยนจาก Mock เป็นดึงข้อมูลจริง
  }

  void loadItemsFromBuyPage() {
    try {
      // 1. ค้นหา BuyProductsController
      final buyController = Get.find<BuyProductsController>();

      // 2. ดึงข้อมูลจาก Getter ที่เราเพิ่งสร้าง (selectedProducts)
      var selectedFromBuyPage = buyController.selectedProducts;

      if (selectedFromBuyPage.isNotEmpty) {
        orderItems.value = selectedFromBuyPage.map((item) {
          return OrderItem(
            id: item.productId.toString(),
            name: item.name ?? 'ไม่มีชื่อสินค้า',
            unit:
                item.unit ??
                'ชิ้น', // ตรวจสอบว่าใน ProductResponse ใช้ชื่อ unit หรือ unitName
            imageUrl: item.imgProduct ?? '',
            initialQuantity: 1, // หรือใส่ค่าเริ่มต้นที่คุณต้องการ
          );
        }).toList();
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // --- Logic อื่นๆ (updateQuantity, removeItem, showDeleteConfirmation) คงเดิม ---

  void updateQuantity(OrderItem item, int change) {
    int currentQuantity = int.tryParse(item.quantityController.text) ?? 0;
    int newQuantity = currentQuantity + change;
    if (newQuantity <= 0) {
      showDeleteConfirmation(item, isFromButton: true);
    } else {
      item.quantityController.text = newQuantity.toString();
    }
  }

  void removeItem(String id) {
    orderItems.removeWhere((element) => element.id == id);
  }

  void onTabTapped(int index) {
    selectedIndex.value = index;
  }

  void showDeleteConfirmation(OrderItem item, {bool isFromButton = false}) {
    String originalQuantity = item.quantityController.text;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        title: const Text(
          'ลบรายการสินค้า',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text('คุณต้องการลบ "${item.name}" ออกหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              if (isFromButton ||
                  (int.tryParse(item.quantityController.text) ?? 0) <= 0) {
                item.quantityController.text = originalQuantity == '0'
                    ? '1'
                    : originalQuantity;
              }
            },
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              removeItem(item.id);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ลบ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
