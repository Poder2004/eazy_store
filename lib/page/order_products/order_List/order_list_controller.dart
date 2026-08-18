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

  // จำนวนล่าสุดที่ยังถูกต้อง (>0) ไว้ใช้คืนค่าตอนกดยกเลิกลบ เพราะพอผู้ใช้พิมพ์
  // เลขในช่องจนกลายเป็น "0" ไปแล้ว ตัว TextField เองจะอัปเดต .text ไปก่อน
  // ที่ onChanged จะทำงาน ทำให้อ่าน .text ตอนนั้นไม่ได้ค่าเดิมที่แท้จริงอีกต่อไป
  String lastValidQuantity;

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
       unitController = TextEditingController(text: unit),
       lastValidQuantity = initialQuantity.toString();

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

  // เรียกทุกครั้งที่กลับมาที่หน้านี้ (ไม่ใช่แค่ตอนสร้าง controller ครั้งแรก)
  // เพื่อให้ orderItems ตรงกับสินค้าที่ติ๊กเลือกไว้ในหน้า buy_products เสมอ
  // - ลบรายการที่ถูกเลือก/ลบออกไปแล้วในหน้า buy_products
  // - เพิ่มรายการที่เพิ่งถูกเลือกใหม่
  // - คงจำนวน/หมายเหตุของรายการเดิมที่ยังเลือกอยู่ไว้ ไม่รีเซ็ตทับ
  void loadItemsFromBuyPage() {
    try {
      final buyController = Get.find<BuyProductsController>();
      final selectedFromBuyPage = buyController.selectedProducts;
      final selectedIds = selectedFromBuyPage
          .map((p) => p.productId.toString())
          .toSet();

      final noLongerSelected = orderItems
          .where((item) => !selectedIds.contains(item.id))
          .toList();
      for (final item in noLongerSelected) {
        item.dispose();
      }
      orderItems.removeWhere((item) => !selectedIds.contains(item.id));

      final existingIds = orderItems.map((item) => item.id).toSet();
      final newItems = selectedFromBuyPage
          .where((p) => !existingIds.contains(p.productId.toString()))
          .map(
            (item) => OrderItem(
              id: item.productId.toString(),
              name: item.name,
              unit: item.unit,
              imageUrl: item.imgProduct,
              initialQuantity: 1,
            ),
          );
      orderItems.addAll(newItems);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // 🔥 ฟังก์ชันสำหรับ Export PDF ที่เพิ่มเข้าไป
  void exportToPdf() {
    if (orderItems.isEmpty) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณาเพิ่มรายการสินค้าก่อนส่งออก PDF",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF5390F2).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Color(0xFF5390F2),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "ยืนยันส่งออก PDF",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                "รายการสินค้า ${orderItems.length} รายการที่จะส่งออก",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Scrollbar(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      itemCount: orderItems.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        final item = orderItems[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF6B8E23),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "${item.quantityController.text} ${item.unitController.text}",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "ยกเลิก",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        _performExport();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5390F2),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "ส่งออก PDF",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _performExport() async {
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
          "เกิดข้อผิดพลาด",
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
        final now = DateTime.now();
        final dateStr = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
        final shopName = prefs.getString('shopName') ?? 'shop';
        final cleanShopName = shopName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
        final String filePath = '${directory.path}/${dateStr}-$cleanShopName.pdf';
        final file = File(filePath);

        // เขียนข้อมูลลงไฟล์และรอให้เสร็จจริงๆ
        await file.writeAsBytes(bytes, flush: true);

        // ตรวจสอบขนาดไฟล์ ถ้าขนาดไฟล์ < 100 bytes แสดงว่าข้อมูลที่ส่งมาผิดปกติ
        if (await file.length() < 100) {
          Get.snackbar(
            "เกิดข้อผิดพลาด",
            "ไฟล์ PDF ไม่สมบูรณ์ กรุณาลองใหม่อีกครั้ง",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }

        // 5. เปิดไฟล์ PDF
        await OpenFile.open(filePath);
      } else {
        Get.snackbar(
          "เกิดข้อผิดพลาด",
          "เซิร์ฟเวอร์ขัดข้อง ไม่สามารถสร้าง PDF ได้",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back();
      debugPrint("Export PDF Error: $e");
      Get.snackbar(
        "เกิดข้อผิดพลาด",
        "ไม่สามารถสร้างไฟล์ PDF ได้ กรุณาลองใหม่อีกครั้ง",
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
      item.lastValidQuantity = newQuantity.toString();
    }
  }

  // เรียกจากช่องกรอกจำนวนตอนพิมพ์เอง (ต่างจาก updateQuantity ที่มาจากปุ่ม +/-)
  void onQuantityTyped(OrderItem item, String value) {
    if (value.isEmpty || value == '0') {
      showDeleteConfirmation(item);
    } else if ((int.tryParse(value) ?? 0) > 0) {
      item.lastValidQuantity = value;
    }
  }

  void removeItem(String id) {
    // อย่าลืม dispose controller ของไอเทมที่ถูกลบด้วย
    final item = orderItems.firstWhere((element) => element.id == id);
    item.dispose();
    orderItems.removeWhere((element) => element.id == id);

    // ยกเลิกติ๊กเลือกสินค้าตัวนี้ในหน้า buy_products ด้วย ไม่งั้นพอกลับไปหน้า
    // เลือกสินค้าหรือกดเพิ่มรายการ จะยังเห็นสินค้าที่ลบไปแล้วติ๊กเลือกค้างอยู่
    try {
      final buyController = Get.find<BuyProductsController>();
      for (final p in buyController.allProducts) {
        if (p.productId.toString() == id) {
          p.isSelected = false;
        }
      }
      buyController.allProducts.refresh();
      buyController.products.refresh();
    } catch (e) {
      debugPrint("Error unselecting product: $e");
    }
  }

  void showDeleteConfirmation(OrderItem item, {bool isFromButton = false}) {
    ConfirmDialog.show(
      title: 'ลบรายการสินค้า',
      message: 'คุณต้องการลบ "${item.name}" ออกหรือไม่?',
      confirmLabel: 'ลบ',
      onCancel: () {
        if (isFromButton ||
            (int.tryParse(item.quantityController.text) ?? 0) <= 0) {
          // ใช้ lastValidQuantity แทนการอ่าน .text ตอนนี้ตรงๆ เพราะถ้ามาจาก
          // การพิมพ์ในช่อง .text จะถูกอัปเดตเป็นค่าใหม่ (เช่น "0") ไปแล้วก่อนหน้านี้
          item.quantityController.text = item.lastValidQuantity;
        }
      },
      onConfirm: () => removeItem(item.id),
    );
  }
}
