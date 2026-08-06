// ไฟล์: lib/sale_producct/checkout_page.dart
import 'package:eazy_store/model/request/baskets_model.dart';
import 'package:eazy_store/page/sale_producct/sale/park_order_controller.dart';
import 'package:eazy_store/page/sale_producct/sale/parked_orders_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../menu_bar/bottom_navbar.dart';
import 'checkout_controller.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final CheckoutController controller = Get.put(CheckoutController());

    // ให้หน้าอื่น (เช่น หน้าบันทึกค้างชำระ) สั่งเปิดแผ่นจ่ายเงินสดของหน้านี้ได้
    controller.openCashPaymentSheet = (ctx) => controller.openPaymentSheet(
      ctx,
      false,
      _PaymentBottomSheet(controller: controller),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchFreshProducts();
    });
    return Scaffold(
      backgroundColor: Colors.white,
      // ✨ คุมฟอนต์หน้าหลักตะกร้า
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: MediaQuery.textScalerOf(
            context,
          ).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.2),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextField(
                              controller: controller.searchController,
                              onChanged: controller.onSearchChanged,
                              style: const TextStyle(fontSize: 16),
                              decoration: InputDecoration(
                                hintText: 'พิมพ์ชื่อสินค้า หรือ สแกน...',
                                hintStyle: const TextStyle(color: Colors.grey),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.grey,
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.qr_code_scanner,
                                    color: Colors.black87,
                                  ),
                                  onPressed: controller.openInternalScanner,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Obx(() {
                            if (controller.isSearching.value) {
                              return _buildSearchResults(controller);
                            }
                            return _buildCartList(context, controller);
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Obx(
        () => BottomNavBar(
          currentIndex: controller.currentNavIndex.value,
          onTap: (index) => controller.currentNavIndex.value = index,
        ),
      ),
    );
  }

  Widget _buildSearchResults(CheckoutController controller) {
    if (controller.isSearching.value && controller.searchResults.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.searchResults.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 60, color: Colors.grey),
          const SizedBox(height: 10),
          const Text("ไม่พบสินค้า", style: TextStyle(color: Colors.grey)),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: controller.searchResults.length,
      separatorBuilder: (c, i) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final product = controller.searchResults[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 5,
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              product.imgProduct,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                width: 50,
                height: 50,
                color: Colors.grey[200],
                child: const Icon(Icons.image, color: Colors.grey),
              ),
            ),
          ),
          title: Text(
            product.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            "฿${product.sellPrice.toStringAsFixed(0)} | คงเหลือ: ${product.stock}",
          ),
          trailing: IconButton(
            icon: const Icon(
              Icons.add_circle,
              color: Color(0xFF6B8E23),
              size: 32,
            ),
            onPressed: () => controller.selectProductToAdd(product),
          ),
          onTap: () => controller.selectProductToAdd(product),
        );
      },
    );
  }

  Widget _buildCartList(BuildContext context, CheckoutController controller) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "รายการในตะกร้า",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Obx(() {
                final parkCtrl = Get.find<ParkOrderController>();
                final count = parkCtrl.parkedOrders.length;
                if (count == 0) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () => _showParkedOrdersSheet(context, controller),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pause_circle_outline, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'พัก $count รายการ',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
        Expanded(
          child: Obx(() {
            if (controller.cartItems.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_basket_outlined,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "ตะกร้าว่างเปล่า",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }
            final groupedItems = <String, List<ProductItem>>{};
            for (var item in controller.cartItems) {
              if (!groupedItems.containsKey(item.id)) {
                groupedItems[item.id] = [];
              }
              groupedItems[item.id]!.add(item);
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: groupedItems.keys.length,
              separatorBuilder: (c, i) =>
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
              itemBuilder: (context, index) {
                String key = groupedItems.keys.elementAt(index);
                List<ProductItem> items = groupedItems[key]!;
                return _buildProductRow(items.first, items.length, controller);
              },
            );
          }),
        ),
        _buildBottomPanel(context, controller),
      ],
    );
  }

  Widget _buildProductRow(
    ProductItem item,
    int qty,
    CheckoutController controller,
  ) {
    double totalItemPrice = item.price * qty;
    return GestureDetector(
      onTap: () => controller.toggleDelete(item),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _squareBtn(Icons.add, () => controller.increaseItem(item)),
                const SizedBox(height: 6),
                _squareBtn(Icons.remove, () => controller.decreaseItem(item)),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  // ✨ แตะเพื่อพิมพ์จำนวนเองได้เลย ไม่ต้องกด +/- ทีละครั้งเวลาซื้อเยอะๆ
                  GestureDetector(
                    onTap: () => _showEditQuantityDialog(item, qty, controller),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "$qty ${item.unit}",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.edit, size: 12, color: Colors.grey[500]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "${totalItemPrice.toInt()} บาท",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "หน่วยละ ${item.price.toInt()} บาท",
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
            Obx(
              () => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: item.showDelete.value ? 50 : 0,
                margin: EdgeInsets.only(left: item.showDelete.value ? 15 : 0),
                child: item.showDelete.value
                    ? Center(
                        child: GestureDetector(
                          onTap: () => controller.removeItem(item),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✨ Dialog พิมพ์จำนวนสินค้าโดยตรง ใช้เวลาซื้อจำนวนมากๆ ไม่ต้องกด +/- ทีละครั้ง
  void _showEditQuantityDialog(
    ProductItem item,
    int currentQty,
    CheckoutController controller,
  ) {
    final qtyCtrl = TextEditingController(text: currentQty.toString());
    final unit = item.unit;
    String? errorText;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          void trySubmit() {
            final newQty = int.tryParse(qtyCtrl.text);
            if (newQty == null) {
              Get.back();
              return;
            }
            // ✨ แจ้งเตือนทันทีถ้ากรอกเกินสต็อกที่มี แทนที่จะเงียบๆ ตัดให้เหลือแค่จำนวนสูงสุด
            if (newQty > item.maxStock) {
              setState(() {
                errorText = "สต็อกมีไม่พอ เหลือเพียง ${item.maxStock} $unit";
              });
              return;
            }
            Get.back();
            controller.setItemQuantity(item, newQty);
          }

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "มีในสต็อก ${item.maxStock} $unit",
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: qtyCtrl,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    onChanged: (_) {
                      if (errorText != null) setState(() => errorText = null);
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: errorText == null
                            ? BorderSide.none
                            : const BorderSide(color: Colors.red, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: errorText == null
                            ? BorderSide.none
                            : const BorderSide(color: Colors.red, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onSubmitted: (_) => trySubmit(),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorText!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Get.back(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.grey[700],
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text("ยกเลิก"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: trySubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C853),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            "ยืนยัน",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _squareBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 18, color: Colors.black87),
      ),
    );
  }

  Widget _buildBottomPanel(
    BuildContext context,
    CheckoutController controller,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // แถวยอดรวม — บรรทัดเดียว ไม่ต้องมีเส้นคั่นให้เปลืองที่
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "รวมทั้งหมด",
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
                Obx(
                  () => Text(
                    "${controller.totalPrice.toInt()} บาท",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ปุ่มทั้งหมดอยู่แถวเดียว: พักออเดอร์เป็นไอคอน (รอง) / ชำระเงินเด่นสุด
            Row(
              children: [
                Obx(() {
                  if (controller.cartItems.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: controller.parkOrder,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFFEF3E2),
                            foregroundColor: const Color(0xFFB45309),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            side: const BorderSide(color: Color(0xFFF59E0B)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.pause_circle_outline, size: 17),
                                SizedBox(width: 4),
                                Text(
                                  "พักออเดอร์",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                Expanded(
                  flex: 3,
                  child: _actionButton(
                    "ชำระเงิน",
                    const Color(0xFF00C853),
                    () => controller.openPaymentSheet(
                      context,
                      false,
                      _PaymentBottomSheet(controller: controller),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: _actionButton(
                    "ค้างชำระ",
                    const Color(0xFF03A9F4),
                    controller.goToDebtPaymentPage,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _showParkedOrdersSheet(BuildContext context, CheckoutController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ParkedOrdersSheet(checkoutController: controller),
    );
  }
}

// ----------------------------------------------------------------------
// Payment Sheet UI Component
// ----------------------------------------------------------------------
class _PaymentBottomSheet extends StatelessWidget {
  final CheckoutController controller;
  const _PaymentBottomSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    // ✨ คุมฟอนต์หน้าต่างชำระเงิน
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: MediaQuery.textScalerOf(
          context,
        ).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  color: Colors.transparent,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: DraggableScrollableSheet(
                    initialChildSize: 0.85,
                    minChildSize: 0.5,
                    maxChildSize: 0.95,
                    expand: false,
                    builder: (context, scrollController) {
                      return Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          children: [
                            Center(
                              child: Container(
                                margin: const EdgeInsets.only(
                                  top: 12,
                                  bottom: 20,
                                ),
                                width: 50,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: Text(
                                "ชำระเงิน",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Divider(height: 1, color: Color(0xFFEEEEEE)),
                            Expanded(
                              child: SingleChildScrollView(
                                controller: scrollController,
                                padding: const EdgeInsets.all(20),
                                child: _buildCashForm(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCashForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✨ ปรับแต่งกล่องยอดรวมให้กว้างเต็มขอบ
        Center(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                const Text(
                  "ยอดรวมที่ต้องชำระ",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 5),
                Obx(
                  () => FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "${controller.totalPrice.toInt()} บาท",
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 25),

        const Text(
          "เลือกวิธีชำระเงิน",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Obx(
          () => Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text("จ่ายเงินสด"),
                    ),
                  ),
                  selectedColor: Colors.green.shade100,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: controller.paymentMethod.value == "จ่ายเงินสด"
                        ? Colors.green.shade700
                        : Colors.black87,
                  ),
                  selected: controller.paymentMethod.value == "จ่ายเงินสด",
                  onSelected: (_) =>
                      controller.paymentMethod.value = "จ่ายเงินสด",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: const Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text("โอนจ่าย"),
                    ),
                  ),
                  selectedColor: Colors.blue.shade100,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: controller.paymentMethod.value == "โอนจ่าย"
                        ? Colors.blue.shade700
                        : Colors.black87,
                  ),
                  selected: controller.paymentMethod.value == "โอนจ่าย",
                  onSelected: (_) => controller.paymentMethod.value = "โอนจ่าย",
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 25),

        Obx(
          () => controller.paymentMethod.value == "จ่ายเงินสด"
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _rowInput(
                      "รับเงินมา",
                      controller.receivedAmountController,
                      true,
                    ),
                    const SizedBox(height: 15),
                    // ✨ จัดกล่องเงินทอนใหม่ ให้เต็มความกว้างและจัดข้อความซ้ายขวา
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.shade200,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "เงินทอน",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Flexible(
                            child: Obx(
                              () => FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "${controller.changeAmount.value.toInt()} ฿",
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Center(
                      child: Container(
                        height: 220,
                        width: 220,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Obx(
                          () => controller.shopQrCodeUrl.value.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    controller.shopQrCodeUrl.value,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(
                                      Icons.broken_image,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.qr_code_2,
                                      size: 80,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "ไม่มี QR Code",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "เพิ่มได้ที่ แก้ไขข้อมูลร้านค้า",
                                      style: TextStyle(
                                        color: Colors.blueAccent,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "ให้ลูกค้าสแกนจ่ายผ่านแอปธนาคาร",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
        ),

        const SizedBox(height: 30),

        const Text(
          "หมายเหตุ (ถ้ามี)",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller.noteController,
          decoration: InputDecoration(
            hintText: 'ใส่ข้อมูลเพิ่มเติม หรือเลขอ้างอิงสลิป...',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 16,
            ),
          ),
        ),

        const SizedBox(height: 40),
        SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: Obx(() => ElevatedButton(
              onPressed: controller.isProcessingPayment.value
                  ? null
                  : () => controller.confirmPayment(controller.processPayment),
              style: ElevatedButton.styleFrom(
                backgroundColor: controller.isProcessingPayment.value
                    ? Colors.grey
                    : Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
                shadowColor: Colors.black45,
              ),
              child: controller.isProcessingPayment.value
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "ยืนยันการทำรายการ",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
            )),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _rowInput(String label, TextEditingController ctrl, bool isEditable) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: TextField(
            controller: ctrl,
            readOnly: !isEditable,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: false,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            decoration: InputDecoration(
              isDense: true,
              suffixText: " ฿",
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black87, width: 2),
              ),
              filled: !isEditable,
              fillColor: isEditable ? Colors.white : Colors.grey[100],
            ),
          ),
        ),
      ],
    );
  }
}
