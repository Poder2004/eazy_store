import 'package:get/get.dart';
import '../../../model/request/baskets_model.dart';
import '../../../model/request/parked_order_model.dart';

class ParkOrderController extends GetxController {
  // เก็บออเดอร์ที่พักไว้ของ "ทุกร้าน" รวมกัน แยกกันด้วย shopId ในแต่ละออเดอร์
  // (คอนโทรลเลอร์นี้ถูก Get.put แบบ permanent ใน main.dart เลยมีชีวิตอยู่ข้ามการสลับร้านค้า
  // ถ้าไม่กรองด้วย shopId ออเดอร์ที่พักไว้ของร้าน A จะรั่วไปโชว์/กู้คืนได้ตอนอยู่ร้าน B)
  var parkedOrders = <ParkedOrder>[].obs;
  int _labelCounter = 1;

  // ร้านปัจจุบัน ให้ CheckoutController อัปเดตทุกครั้งที่เช็ค/สลับร้าน
  var currentShopId = 0.obs;

  List<ParkedOrder> get visibleOrders =>
      parkedOrders.where((o) => o.shopId == currentShopId.value).toList(); //รายการออเดอร์ที่พักไว้ของ ทุกร้าน

  int get count => visibleOrders.length;

  void parkCurrentOrder(List<ProductItem> cartItems) {
    // group ด้วย lineKey (ไม่ใช่แค่ product id) เพื่อไม่ให้สินค้าเดียวกันแต่คนละ
    // หน่วย (เช่น ขวด กับ ลัง) ถูกนับรวมเป็นแถวเดียวกันตอนพักออเดอร์
    final Map<String, ParkedItem> grouped = {};
    for (final item in cartItems) {
      final key = item.lineKey;
      if (grouped.containsKey(key)) {
        final existing = grouped[key]!;
        grouped[key] = ParkedItem(
          id: existing.id,
          name: existing.name,
          price: existing.price,
          category: existing.category,
          imagePath: existing.imagePath,
          maxStock: existing.maxStock,
          quantity: existing.quantity + 1,
          unitId: existing.unitId,
          unitName: existing.unitName,
          conversionQty: existing.conversionQty,
          unit: existing.unit,
        );
      } else {
        grouped[key] = ParkedItem(
          id: item.id,
          name: item.name,
          price: item.price,
          category: item.category,
          imagePath: item.imagePath,
          maxStock: item.maxStock,
          quantity: 1,
          unitId: item.unitId,
          unitName: item.unitName,
          conversionQty: item.conversionQty,
          unit: item.unit,
        );
      }
    }

    final totalPrice = cartItems.fold<double>(0, (sum, item) => sum + item.price);

    // ถ้าร้านนี้ยังไม่มีออเดอร์พักเลย ให้ reset counter กลับเป็น 1
    // กันกรณีที่พักแล้วกู้คืน/ลบหมดแล้ว แต่ counter ยังนับต่อจากเดิม
    if (visibleOrders.isEmpty) _labelCounter = 1;

    final order = ParkedOrder(
      id: 'park_${DateTime.now().millisecondsSinceEpoch}',
      label: 'ออเดอร์ ${_labelCounter++}',
      items: grouped.values.toList(),
      totalPrice: totalPrice,
      parkedAt: DateTime.now(),
      shopId: currentShopId.value,
    );

    parkedOrders.insert(0, order);
  }

  // ✅ กรองด้วย shopId เสมอ กันดึงออเดอร์ที่พักไว้ของร้านอื่นข้ามมาแม้จะรู้ parkId ก็ตาม
  ParkedOrder? retrieveOrder(String parkId) {
    final index = parkedOrders.indexWhere(
      (o) => o.id == parkId && o.shopId == currentShopId.value,
    );
    if (index == -1) return null;
    final order = parkedOrders[index];
    parkedOrders.removeAt(index);
    return order;
  }

  void removeOrder(String parkId) {
    parkedOrders.removeWhere(
      (o) => o.id == parkId && o.shopId == currentShopId.value,
    );
  }

  // ล้างเฉพาะออเดอร์ที่พักไว้ของร้านปัจจุบัน ไม่แตะของร้านอื่น
  void clearAll() {
    parkedOrders.removeWhere((o) => o.shopId == currentShopId.value);
  }
}
