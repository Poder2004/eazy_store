import 'package:get/get.dart';
import '../../../model/request/baskets_model.dart';
import '../../../model/request/parked_order_model.dart';

class ParkOrderController extends GetxController {
  var parkedOrders = <ParkedOrder>[].obs;
  int _labelCounter = 1;

  int get count => parkedOrders.length;

  void parkCurrentOrder(List<ProductItem> cartItems) {
    final Map<String, ParkedItem> grouped = {};
    for (final item in cartItems) {
      if (grouped.containsKey(item.id)) {
        final existing = grouped[item.id]!;
        grouped[item.id] = ParkedItem(
          id: existing.id,
          name: existing.name,
          price: existing.price,
          category: existing.category,
          imagePath: existing.imagePath,
          maxStock: existing.maxStock,
          quantity: existing.quantity + 1,
        );
      } else {
        grouped[item.id] = ParkedItem(
          id: item.id,
          name: item.name,
          price: item.price,
          category: item.category,
          imagePath: item.imagePath,
          maxStock: item.maxStock,
          quantity: 1,
        );
      }
    }

    final totalPrice = cartItems.fold<double>(0, (sum, item) => sum + item.price);

    final order = ParkedOrder(
      id: 'park_${DateTime.now().millisecondsSinceEpoch}',
      label: 'ออเดอร์ ${_labelCounter++}',
      items: grouped.values.toList(),
      totalPrice: totalPrice,
      parkedAt: DateTime.now(),
    );

    parkedOrders.insert(0, order);
  }

  ParkedOrder? retrieveOrder(String parkId) {
    final index = parkedOrders.indexWhere((o) => o.id == parkId);
    if (index == -1) return null;
    final order = parkedOrders[index];
    parkedOrders.removeAt(index);
    return order;
  }

  void removeOrder(String parkId) {
    parkedOrders.removeWhere((o) => o.id == parkId);
  }

  void clearAll() {
    parkedOrders.clear();
    _labelCounter = 1;
  }
}
