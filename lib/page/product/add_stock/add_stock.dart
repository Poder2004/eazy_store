import 'package:eazy_store/page/menu_bar/bottom_navbar.dart';
import 'package:eazy_store/page/sale_producct/scanBarcode/scan_barcode.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// ✅ นำเข้า Controller ที่แยกไว้
import 'add_stock_controller.dart';

// 🎨 Theme Colors
const Color _kPrimaryColor = Color(0xFF6B8E23);
const Color _kBackgroundColor = Color(0xFFF7F7F7);
const Color _kInputFillColor = Color(0xFFF0F0E0);
const Color _kReadOnlyColor = Color(0xFFEEEEEE);

class AddStockScreen extends StatelessWidget {
  const AddStockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ เรียกใช้ Controller
    final AddStockController controller = Get.put(AddStockController());

    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        title: Text(
          'เพิ่มสต็อกสินค้า',
          style: GoogleFonts.prompt(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: _kBackgroundColor,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.refreshCurrentProduct(),
        color: _kPrimaryColor,
        child: SingleChildScrollView(
          // ต้องกำหนด AlwaysScrollable เพื่อให้รูดได้แม้เนื้อหาน้อย
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildSearchSection(controller),
              const SizedBox(height: 20),

              Obx(() {
                if (controller.foundProduct.value != null) {
                  return Column(
                    children: [
                      _buildProductCard(controller),
                      const SizedBox(height: 20),
                      _buildStockInputSection(controller),
                      const SizedBox(height: 20),
                      _buildPriceEditSection(controller),
                      const SizedBox(height: 30),
                      _buildActionButtons(controller),
                    ],
                  );
                } else if (controller.showDropdown.value && controller.searchMatches.isNotEmpty) {
                  // dropdown จากช่องค้นหาด้านบนกำลังให้เลือกอยู่แล้ว ไม่ต้องซ้อนข้อความอื่น
                  return const SizedBox.shrink();
                } else if (controller.isSearching.value && controller.searchController.text.length > 2) {
                   // โชว์ Loading เฉพาะตอนค้นหาคำยาวๆ
                  return const Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: CircularProgressIndicator(color: _kPrimaryColor),
                  );
                } else {
                  return _buildEmptyState();
                }
              }),
              // เพิ่มพื้นที่ด้านล่างเพื่อให้ Scroll ได้สะดวกขึ้น
              const SizedBox(height: 100), 
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: -1, // ใส่ -1 จะไม่มีปุ่มไหนถูกเลือก (ไม่มีสีแดงโชว์)
        onTap: (index) {
          // ใส่ Logic การเปลี่ยนหน้าตามปกติของคุณ
          print("Tab tapped: $index");
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 50),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            "พิมพ์ชื่อสินค้าหรือสแกนบาร์โค้ด",
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
        ],
      ),
    );
  }

  // --- Widgets ---

  Widget _buildSearchSection(AddStockController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller.searchController,
            decoration: InputDecoration(
              hintText: 'ชื่อสินค้า หรือ รหัสบาร์โค้ด',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: _kPrimaryColor),
                onPressed: () async {
                  var result = await Get.to(() => const ScanBarcodePage());
                  if (result != null && result is String) {
                    controller.searchController.text = result;
                    controller.handleSearch();
                  }
                },
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
            onSubmitted: (_) => controller.handleSearch(),
          ),
        ),
        Obx(() {
          if (!controller.showDropdown.value || controller.searchMatches.isEmpty) {
            return const SizedBox.shrink();
          }
          return Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 460),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: controller.searchMatches.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final p = controller.searchMatches[index];
                return ListTile(
                  dense: true,
                  onTap: () => controller.selectProduct(p),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      p.imgProduct,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 36,
                        height: 36,
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.image_not_supported, size: 16, color: Colors.grey),
                      ),
                    ),
                  ),
                  title: Text(
                    p.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    "รหัส: ${p.productCode ?? '-'}",
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildProductCard(AddStockController controller) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 40),
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Column(
            children: [
              Text(
                controller.nameController.text,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                "รหัส: ${controller.foundProduct.value?.productCode ?? '-'}",
                style: const TextStyle(color: Colors.grey),
              ),
              const Divider(height: 30),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      "ราคาขาย",
                      "฿${controller.salePriceController.text}",
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      "ต้นทุน",
                      "฿${controller.costController.text}",
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      "คงเหลือ",
                      "${controller.currentStockController.text} ${controller.unitController.text}",
                      isHighlight: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
            ],
            image: DecorationImage(
              image: NetworkImage(
                controller.foundProduct.value?.imgProduct ?? '',
              ),
              fit: BoxFit.cover,
              onError: (e, s) {},
            ),
          ),
          child:
              controller.foundProduct.value?.imgProduct == null ||
                  controller.foundProduct.value!.imgProduct.isEmpty
              ? const Icon(Icons.image_not_supported, color: Colors.grey)
              : null,
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isHighlight ? _kPrimaryColor : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceEditSection(AddStockController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // หัวข้อ (กดเพื่อยุบ/ขยาย — ไม่บังคับให้เห็นตลอดเวลา)
          InkWell(
            onTap: controller.togglePriceEdit,
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.price_change_outlined,
                    color: _kPrimaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "แก้ไขราคาสินค้า",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        "ไม่บังคับ — กดเพื่อขยาย",
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                Obx(
                  () => AnimatedRotation(
                    turns: controller.isPriceEditExpanded.value ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400),
                  ),
                ),
              ],
            ),
          ),
          Obx(
            () => AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: !controller.isPriceEditExpanded.value
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        children: [
                          const Divider(height: 1, color: Color(0xFFF0F0F0)),
                          const SizedBox(height: 16),
                          _buildPriceInputRow(
                            label: "ราคาขาย",
                            unit: "บาท",
                            icon: Icons.sell_outlined,
                            controller: controller.editSellPriceCtrl,
                          ),
                          const SizedBox(height: 12),
                          _buildPriceInputRow(
                            label: "ราคาต้นทุน",
                            unit: "บาท",
                            icon: Icons.shopping_bag_outlined,
                            controller: controller.editCostPriceCtrl,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInputRow({
    required String label,
    required String unit,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                isDense: true,
              ),
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _kPrimaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: _kPrimaryColor, size: 22),
      ),
    );
  }

  Widget _buildStockInputSection(AddStockController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add_circle_outline,
                  color: _kPrimaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "เพิ่มจำนวนสต็อก",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStepBtn(
                Icons.remove,
                () {
                  int v = int.tryParse(controller.addAmountController.text) ?? 0;
                  if (v > 0) controller.addAmountController.text = (v - 1).toString();
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller.addAmountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _kPrimaryColor,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(color: Colors.grey[300], fontSize: 32),
                    filled: true,
                    fillColor: const Color(0xFFF7F8FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _buildStepBtn(
                Icons.add,
                () {
                  int v = int.tryParse(controller.addAmountController.text) ?? 0;
                  controller.addAmountController.text = (v + 1).toString();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Obx(
              () => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _kPrimaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "ยอดรวมใหม่: ${controller.calculatedTotal.value} ${controller.unitController.text}",
                  style: const TextStyle(
                    color: _kPrimaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🛡️ ปรับ Popup มาไว้ใน View
  void _showSaveCheckDialog(AddStockController controller) {
    if (controller.foundProduct.value == null) return;

    int amount = int.tryParse(controller.addAmountController.text) ?? 0;
    if (amount <= 0) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณาระบุจำนวนที่ต้องการเพิ่ม",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.playlist_add_check_circle,
                size: 60,
                color: _kPrimaryColor,
              ),
              const SizedBox(height: 15),
              const Text(
                "ยืนยันเพิ่มสต็อก",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 30),
              _buildConfirmRow("สินค้า", controller.nameController.text),
              _buildConfirmRow(
                "คงเหลือเดิม",
                "${controller.currentStockController.text} ${controller.unitController.text}",
              ),
              _buildConfirmRow(
                "เพิ่มจำนวน",
                "+$amount ${controller.unitController.text}",
                valueColor: Colors.green,
              ),
              const Divider(),
              _buildConfirmRow(
                "รวมสุทธิ",
                "${controller.calculatedTotal.value} ${controller.unitController.text}",
                isBold: true,
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "แก้ไข",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back(); // ปิด Popup
                        controller.executeSave(amount); // ยิง API
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "ยืนยัน",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // 🟢 Dialog ยืนยันแบบใหม่ (แสดงสิ่งที่จะเปลี่ยน)
  void _showConfirmDialog(AddStockController controller) {
    if (controller.foundProduct.value == null) return;

    final hasPrice = controller.isPriceChangedPublic;
    final hasStock = controller.hasStockToAddPublic;

    if (!hasPrice && !hasStock) {
      Get.snackbar(
        "แจ้งเตือน",
        "ยังไม่มีการเปลี่ยนแปลงข้อมูล",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final newSell = double.tryParse(controller.editSellPriceCtrl.text);
    final newCost = double.tryParse(controller.editCostPriceCtrl.text);
    final origSell = controller.foundProduct.value?.sellPrice ?? 0;
    final origCost = controller.foundProduct.value?.costPrice ?? 0;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _kPrimaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  color: _kPrimaryColor,
                  size: 36,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                "ยืนยันการบันทึก",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                controller.nameController.text,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // --- สรุปการเปลี่ยนแปลง ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    if (hasPrice) ...[
                      _buildChangeRow(
                        icon: Icons.sell_outlined,
                        label: "ราคาขาย",
                        from: "฿${origSell.toStringAsFixed(0)}",
                        to: "฿${newSell?.toStringAsFixed(0) ?? '-'}",
                        changed: newSell != origSell,
                      ),
                      const SizedBox(height: 10),
                      _buildChangeRow(
                        icon: Icons.shopping_bag_outlined,
                        label: "ราคาต้นทุน",
                        from: "฿${origCost.toStringAsFixed(0)}",
                        to: "฿${newCost?.toStringAsFixed(0) ?? '-'}",
                        changed: newCost != origCost,
                      ),
                    ],
                    if (hasPrice && hasStock)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1),
                      ),
                    if (hasStock)
                      _buildChangeRow(
                        icon: Icons.inventory_2_outlined,
                        label: "สต็อกคงเหลือ",
                        from: controller.currentStockController.text,
                        to: "${controller.calculatedTotal.value} ${controller.unitController.text}",
                        changed: true,
                        toColor: _kPrimaryColor,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        "แก้ไข",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        controller.saveAll();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "ยืนยันบันทึก",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildChangeRow({
    required IconData icon,
    required String label,
    required String from,
    required String to,
    required bool changed,
    Color? toColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
        if (changed) ...[
          Text(
            from,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.arrow_forward, size: 12, color: Colors.grey),
          ),
        ],
        Text(
          to,
          style: TextStyle(
            color: toColor ?? _kPrimaryColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.black87,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AddStockController controller) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: controller.isSavingPrice.value
              ? null
              : () => _showConfirmDialog(controller),
          icon: controller.isSavingPrice.value
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_rounded, color: Colors.white, size: 22),
          label: Text(
            controller.isSavingPrice.value ? "กำลังบันทึก..." : "บันทึกสต็อก",
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: controller.isSavingPrice.value
                ? _kPrimaryColor.withOpacity(0.6)
                : _kPrimaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: controller.isSavingPrice.value ? 0 : 4,
          ),
        ),
      ),
    );
  }
}
