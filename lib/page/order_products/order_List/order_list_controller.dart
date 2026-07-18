import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:eazy_store/api/api_orderlist.dart'; // Import API ที่เราสร้างไว้
import 'package:eazy_store/page/order_products/buyProducts/buy_products_controller.dart';
import 'package:eazy_store/widgets/confirm_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderItem {
  final String id;
  final String name;
  final String unit;
  final String imageUrl;
  final TextEditingController quantityController;
  final TextEditingController noteController;

  // หน่วยนับที่แก้ไขได้เฉพาะในใบสั่งของนี้ (ไม่บันทึกกลับลงสินค้าจริง)
  // เริ่มต้นจาก `unit` เดิม แต่ผู้ใช้พิมพ์ทับได้ เช่นเปลี่ยน "คู่" เป็น "1 โหล"
  final TextEditingController unitController;

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
       noteController = TextEditingController(text: initialNote),
       unitController = TextEditingController(text: unit);

  // สั่งปิดการทำงานของ Controller เมื่อไม่ได้ใช้
  void dispose() {
    quantityController.dispose();
    noteController.dispose();
    unitController.dispose();
  }
}

class OrderListController extends GetxController {
  var orderItems = <OrderItem>[].obs;
  var searchQuery = ''.obs;

  // รายการที่กำลังกางช่องหมายเหตุอยู่ (การ์ดแบบย่อ ไม่โชว์ช่องหมายเหตุ
  // ตลอดเวลาเหมือนเดิม แต่กางเฉพาะรายการที่กดไอคอนหมายเหตุ)
  var notesExpanded = <String>{}.obs;

  // รายการที่กำลังแก้ไข "หน่วยนับ" อยู่ (กดไอคอนดินสอก่อนถึงพิมพ์ได้)
  var unitsEditing = <String>{}.obs;

  List<OrderItem> get visibleItems {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return orderItems;
    return orderItems
        .where((item) => item.name.toLowerCase().contains(query))
        .toList();
  }

  void toggleNote(String id) {
    if (notesExpanded.contains(id)) {
      notesExpanded.remove(id);
    } else {
      notesExpanded.add(id);
    }
  }

  void toggleUnitEdit(String id) {
    if (unitsEditing.contains(id)) {
      unitsEditing.remove(id);
    } else {
      unitsEditing.add(id);
    }
  }

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

      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;

      if (shopId == 0) {
        Get.back();
        Get.snackbar(
          "Error",
          "ไม่พบข้อมูลร้านค้า กรุณาล็อกอินหรือเลือกใช้งานร้านค้าใหม่อีกครั้ง",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // 2. เตรียมข้อมูลส่งไป Backend
      final Map<String, dynamic> requestData = {
        "shop_id": shopId, // ส่งแค่ ID ไปตัวเดียว
        "items": orderItems
            .map(
              (item) => {
                "name": item.name,
                "quantity": int.tryParse(item.quantityController.text) ?? 0,
                "unit": item.unitController.text,
                "note": item.noteController.text,
              },
            )
            .toList(),
      };

      debugPrint("Export PDF Request Data: $requestData");

      // 3. ยิง API
      final bytes = await ApiOrderList.exportOrderPdf(requestData);

      Get.back(); // ปิด Loading

      if (bytes != null && bytes.isNotEmpty) {
        final directory = await getApplicationDocumentsDirectory();
        final String filePath =
            '${directory.path}/order_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File(filePath);

        // เขียนข้อมูลลงไฟล์และรอให้เสร็จจริงๆ
        await file.writeAsBytes(bytes, flush: true);

        // ตรวจสอบขนาดไฟล์ ถ้าขนาดไฟล์ < 100 bytes แสดงว่าข้อมูลที่ส่งมาผิดปกติ
        if (await file.length() < 100) {
          Get.snackbar("Error", "ไฟล์ PDF ไม่สมบูรณ์");
          return;
        }

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

  void showDeleteConfirmation(OrderItem item, {bool isFromButton = false}) {
    String originalQuantity = item.quantityController.text;
    ConfirmDialog.show(
      title: 'ลบรายการสินค้า',
      message: 'คุณต้องการลบ "${item.name}" ออกหรือไม่?',
      confirmLabel: 'ลบ',
      onCancel: () {
        if (isFromButton ||
            (int.tryParse(item.quantityController.text) ?? 0) <= 0) {
          item.quantityController.text = (originalQuantity == '0' || originalQuantity.trim().isEmpty)
              ? '1'
              : originalQuantity;
        }
      },
      onConfirm: () => removeItem(item.id),
    );
  }
}
