import 'package:eazy_store/page/sale_producct/sale/checkout_controller.dart';
import 'package:eazy_store/page/sale_producct/sale/park_order_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ParkedOrdersSheet extends StatelessWidget {
  final CheckoutController checkoutController;

  const ParkedOrdersSheet({super.key, required this.checkoutController});

  @override
  Widget build(BuildContext context) {
    final parkCtrl = Get.find<ParkOrderController>();
    final priceFormat = NumberFormat('#,##0.00', 'en_US');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.pause_circle_outline, color: Color(0xFFF59E0B), size: 24),
              const SizedBox(width: 8),
              const Text(
                'ออเดอร์ที่พักไว้',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Obx(() => Text(
                '${parkCtrl.parkedOrders.length} รายการ',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              )),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Obx(() {
            if (parkCtrl.parkedOrders.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('ไม่มีออเดอร์ที่พักไว้', style: TextStyle(color: Colors.grey, fontSize: 15)),
                  ],
                ),
              );
            }
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: parkCtrl.parkedOrders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final order = parkCtrl.parkedOrders[index];
                  final timeStr = DateFormat('HH:mm').format(order.parkedAt);
                  final itemCount = order.items.fold<int>(0, (sum, i) => sum + i.quantity);

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.pause_circle_outline, color: Color(0xFFF59E0B), size: 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(order.label,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 2),
                              Text(
                                '$itemCount ชิ้น • ฿${priceFormat.format(order.totalPrice)} • $timeStr น.',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            Get.back();
                            checkoutController.resumeOrder(order.id);
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('เรียกคืน', style: TextStyle(color: Colors.white, fontSize: 13)),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () => parkCtrl.removeOrder(order.id),
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
