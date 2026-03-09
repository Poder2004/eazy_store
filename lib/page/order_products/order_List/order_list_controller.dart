import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:eazy_store/api/api_orderlist.dart'; // Import API ที่เราสร้างไว้
import 'package:eazy_store/page/order_products/buyProducts/buy_products_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // สั่งปิดการทำงานของ Controller เมื่อไม่ได้ใช้
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
    loadItemsFromBuyPage();
  }

  // ⚠️ สำคัญ: คืนคืนหน่วยความจำเมื่อ Controller ของหน้าถูกลบ
  @override
  void onClose() {
    for (var item in orderItems) {
      item.dispose();
    }
    super.onClose();
  }

  void loadItemsFromBuyPage() {
    try {
      final buyController = Get.find<BuyProductsController>();
      var selectedFromBuyPage = buyController.selectedProducts;

      if (selectedFromBuyPage.isNotEmpty) {
        orderItems.value = selectedFromBuyPage.map((item) {
          return OrderItem(
            id: item.productId.toString(),
            name: item.name ?? 'ไม่มีชื่อสินค้า',
            unit: item.unit ?? 'ชิ้น',
            imageUrl: item.imgProduct ?? '',
            initialQuantity: 1,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // 🔥 ฟังก์ชันสำหรับ Export PDF ที่เพิ่มเข้าไป
  Future<void> exportToPdf() async {
    if (orderItems.isEmpty) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณาเพิ่มรายการสินค้าก่อนส่งออก PDF",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      // 1. แสดง Loading
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Colors.white)),
        barrierDismissible: false,
      );

      final prefs = await SharedPreferences.getInstance();
      final int shopId = prefs.getInt('shop_id') ?? 0;

      // 2. เตรียมข้อมูลส่งไป Backend
      final Map<String, dynamic> requestData = {
        "shop_id": shopId, // ส่งแค่ ID ไปตัวเดียว
        "items": orderItems
            .map(
              (item) => {
                "name": item.name,
                "quantity": int.tryParse(item.quantityController.text) ?? 0,
                "unit": item.unit,
                "note": item.noteController.text,
              },
            )
            .toList(),
      };

      // 3. ยิง API
      final bytes = await ApiOrderList.exportOrderPdf(requestData);

      Get.back(); // ปิด Loading

      if (bytes != null) {
        // 4. บันทึกไฟล์ลงในเครื่อง
        final directory = await getApplicationDocumentsDirectory();
        final String filePath =
            '${directory.path}/order_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        // 5. เปิดไฟล์ PDF
        await OpenFile.open(filePath);
      } else {
        Get.snackbar(
          "Error",
          "เซิร์ฟเวอร์ขัดข้อง ไม่สามารถสร้าง PDF ได้",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back();
      debugPrint("Export PDF Error: $e");
      Get.snackbar(
        "Error",
        "เกิดข้อผิดพลาด: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

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
    // อย่าลืม dispose controller ของไอเทมที่ถูกลบด้วย
    final item = orderItems.firstWhere((element) => element.id == id);
    item.dispose();
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
