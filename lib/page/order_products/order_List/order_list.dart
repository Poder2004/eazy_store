import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: MediaQuery.textScalerOf(context).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.2),
      ),
      child: Scaffold(
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
            _buildListHeader(controller),
            Expanded(
              child: Obx(() {
                if (controller.orderItems.isEmpty) {
                  return const Center(child: Text('ไม่มีรายการสินค้าที่ต้องสั่งซื้อ'));
                }
                final items = controller.visibleItems;
                if (items.isEmpty) {
                  return const Center(child: Text('ไม่พบสินค้าที่ค้นหา'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  itemCount: items.length,
                  itemBuilder: (context, index) =>
                      _buildOrderItemCard(items[index], controller),
                );
              }),
            ),
            _buildBottomActionArea(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildListHeader(OrderListController controller) {
    return Obx(() {
      if (controller.orderItems.isEmpty) return const SizedBox.shrink();
      final total = controller.orderItems.length;
      final visible = controller.visibleItems.length;
      final hasQuery = controller.searchQuery.value.trim().isNotEmpty;

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE7EDDA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                hasQuery ? '$visible จาก $total รายการ' : '$total รายการ',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF516B1A),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
                ],
              ),
              child: TextField(
                onChanged: (v) => controller.searchQuery.value = v,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'ค้นหาในรายการที่เลือกไว้...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildOrderItemCard(OrderItem item, OrderListController controller) {
    return Obx(() {
      final isNoteOpen = controller.notesExpanded.contains(item.id);
      final hasNote = item.noteController.text.isNotEmpty;
      final isUnitEditing = controller.unitsEditing.contains(item.id);

      return Container(
        margin: const EdgeInsets.only(bottom: 10.0),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 9.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 1)),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.network(
                    item.imageUrl,
                    width: 34,
                    height: 34,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 34,
                      height: 34,
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.image_not_supported, size: 16, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                _buildQtyBtn(Icons.remove, () => controller.updateQuantity(item, -1)),
                _buildQtyField(item.quantityController, (v) {
                  if (v.isEmpty || v == '0') controller.showDeleteConfirmation(item);
                }),
                _buildQtyBtn(Icons.add, () => controller.updateQuantity(item, 1)),
                const SizedBox(width: 4),
                SizedBox(
                  width: 40,
                  child: isUnitEditing
                      ? TextField(
                          controller: item.unitController,
                          autofocus: true,
                          maxLines: 1,
                          style: const TextStyle(fontSize: 10.5, color: Colors.black87),
                          onSubmitted: (_) => controller.toggleUnitEdit(item.id),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                            border: UnderlineInputBorder(),
                          ),
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            item.unitController.text,
                            style: const TextStyle(fontSize: 10.5, color: Colors.black45),
                            maxLines: 1,
                          ),
                        ),
                ),
                _buildIconToggle(
                  icon: Icons.edit_outlined,
                  active: isUnitEditing,
                  onTap: () => controller.toggleUnitEdit(item.id),
                ),
                _buildIconToggle(
                  icon: Icons.note_alt_outlined,
                  active: isNoteOpen || hasNote,
                  onTap: () => controller.toggleNote(item.id),
                ),
                _buildIconToggle(
                  icon: Icons.close,
                  active: false,
                  onTap: () => controller.showDeleteConfirmation(item),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: !isNoteOpen
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextField(
                        controller: item.noteController,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'เพิ่มหมายเหตุ (ถ้ามี)',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 22, height: 22,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(color: _kPrimaryColor, borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, color: Colors.white, size: 13),
      ),
    );
  }

  Widget _buildQtyField(TextEditingController ctrl, Function(String) onChange) {
    return SizedBox(
      width: 30, height: 22,
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        onChanged: onChange,
        decoration: InputDecoration(
          filled: true, fillColor: _kInputFillColor,
          contentPadding: EdgeInsets.zero,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildIconToggle({required IconData icon, required bool active, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 24, height: 24,
          decoration: BoxDecoration(
            color: active ? const Color(0xFFE7EDDA) : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 13, color: active ? const Color(0xFF516B1A) : Colors.grey.shade500),
        ),
      ),
    );
  }

  Widget _buildBottomActionArea(OrderListController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -3))]),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: _buildBigButton('เพิ่มรายการสินค้า', Icons.add, _kPrimaryColor, () => Get.to(() => const BuyProductsScreen())),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildBigButton('ส่งออกเป็น PDF', Icons.picture_as_pdf, _kSecondaryButtonColor, () => controller.exportToPdf()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBigButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 55,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}