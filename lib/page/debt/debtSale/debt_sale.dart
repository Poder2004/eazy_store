import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

// --- Imports ---
import '../../sale_producct/sale/checkout_controller.dart';
import 'debt_sale_controller.dart';

class DebtSalePage extends StatelessWidget {
  DebtSalePage({super.key});

  final DebtSaleController controller = Get.put(DebtSaleController());
  final CheckoutController checkoutController = Get.find<CheckoutController>();

  final Color _bgColor = const Color(0xFFF4F7FA);
  final Color _primaryColor = const Color(0xFF2563EB); // ฟ้าพรีเมียม
  final Color _successColor = const Color(0xFF10B981); // เขียว

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        centerTitle: true,
        title: const Text(
          "บันทึกค้างชำระ",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      // คุมสเกลฟอนต์ทั้งหน้าจอ
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: MediaQuery.textScalerOf(
            context,
          ).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.2),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. หัวข้อ + ปุ่มสร้างลูกหนี้ใหม่ (ย้ายขึ้นมาไว้ด้านบน) ---
                    Row(
                      children: [
                        const Text(
                          "ข้อมูลลูกหนี้",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: controller.goToRegisterDebtor,
                          icon: const Icon(
                            Icons.person_add_alt_1_rounded,
                            size: 18,
                          ),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "สร้างลูกหนี้ใหม่",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: _primaryColor,
                            backgroundColor: _primaryColor.withOpacity(0.08),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // --- 2. การ์ดเลือกลูกหนี้ (แตะเพื่อเปิดสมุด ค้นหาในสมุดที่เดียว) ---
                    _buildDebtorPicker(),
                    const SizedBox(height: 20),

                    // --- 2. ส่วนตะกร้าสินค้า ---
                    const Text(
                      "รายการสินค้า",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildCartList(),
                    const SizedBox(height: 20),

                    // --- 3. ส่วนสรุปข้อมูลและบันทึก ---
                    const Text(
                      "สรุปการค้างชำระ",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildSummarySection(),
                  ],
                ),
              ),
            ),
            // --- 4. ปุ่ม Action ด้านล่างสุด ---
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  /// การ์ดเลือกลูกหนี้ — แตะเพื่อเปิด "สมุดลูกหนี้" (ค้นหาอยู่ในสมุดที่เดียว ไม่ซ้ำซ้อน)
  Widget _buildDebtorPicker() {
    return Obx(() {
      final debtor = controller.selectedDebtorRx.value;
      final bool hasDebtor = debtor != null;

      return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        child: InkWell(
          onTap: controller.openDebtorBook,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasDebtor ? _primaryColor : Colors.grey.shade300,
                width: hasDebtor ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // รูป/ไอคอน
                hasDebtor
                    ? CircleAvatar(
                        radius: 22,
                        backgroundColor: _primaryColor.withOpacity(0.1),
                        backgroundImage: debtor.imgDebtor.isNotEmpty
                            ? NetworkImage(debtor.imgDebtor)
                            : null,
                        child: debtor.imgDebtor.isEmpty
                            ? Text(
                                debtor.name.isNotEmpty
                                    ? debtor.name[0].toUpperCase()
                                    : "?",
                                style: TextStyle(
                                  color: _primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      )
                    : Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: _primaryColor,
                          size: 22,
                        ),
                      ),
                const SizedBox(width: 12),

                // ข้อความ
                Expanded(
                  child: hasDebtor
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${debtor.name} (${debtor.phone})",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "วงเงินคงเหลือ ${controller.creditRemain.toInt()} ฿",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "เลือกลูกหนี้",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "แตะเพื่อเปิดสมุดลูกหนี้ / ค้นหาชื่อหรือเบอร์",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                ),

                // ปุ่มท้ายการ์ด
                Text(
                  hasDebtor ? "เปลี่ยน" : "เลือก",
                  style: TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: _primaryColor),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCartList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Obx(() {
        final groupedItems = <String, List<dynamic>>{};
        for (var item in checkoutController.cartItems) {
          groupedItems.putIfAbsent(item.id, () => []).add(item);
        }
        if (groupedItems.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(30.0),
            child: Center(
              child: Text(
                "ไม่มีสินค้าในตะกร้า",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: groupedItems.length,
          separatorBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(color: Colors.grey.shade100, height: 1),
          ),
          itemBuilder: (context, index) {
            String key = groupedItems.keys.elementAt(index);
            List<dynamic> items = groupedItems[key]!;
            var item = items.first;
            return Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "${items.length} ${item.unit}",
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                const SizedBox(width: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "${(item.price * items.length).toInt()} ฿",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Obx(
            () => _rowLabelValue(
              "รวมทั้งหมด",
              "${checkoutController.totalPrice.toInt()} บาท",
              isBold: true,
              valueSize: 22,
              valueColor: Colors.black87,
            ),
          ),
          const Divider(height: 30, color: Color(0xFFF1F5F9), thickness: 1.5),

          ValueListenableBuilder(
            valueListenable: controller.debtorNameController,
            builder: (context, value, child) {
              return _rowInfo(
                "ชื่อคนเซ็น",
                value.text.isEmpty ? "-" : value.text,
                isBold: true,
              );
            },
          ),
          _rowInputSimple(
            "เบอร์โทรศัพท์",
            _textField(controller.debtorPhoneController, readOnly: true),
          ),
          _rowInput(
            "จ่ายตอนนี้",
            _textField(controller.payAmountController, isNumber: true),
          ),

          Obx(() {
            final double total = checkoutController.totalPrice.toDouble();
            final double debt = controller.remainingDebt(total);
            final double change = controller.changeAmount(total);

            return Column(
              children: [
                // ยอดค้างไม่ติดลบ จ่ายเกินถือว่าค้าง 0
                _rowInfo(
                  "ยอดที่เซ็นค้าง",
                  "${debt.toInt()} บาท",
                  isRed: debt > 0,
                  valueSize: 18,
                ),

                // จ่ายเกิน แสดงเงินทอนให้ร้านทอนถูก
                if (change > 0)
                  _rowInfo(
                    "เงินทอน",
                    "${change.toInt()} บาท",
                    isBold: true,
                    valueSize: 18,
                  ),

                // จ่ายครบแล้ว = ไม่ใช่รายการค้างชำระ เตือนให้ไปใช้ขายเงินสด
                if (debt <= 0 && controller.payAmount.value > 0)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            change > 0
                                ? "ลูกค้าจ่ายเกินยอดสินค้า ไม่มียอดค้างชำระ\nกดปุ่ม \"ไปคิดเงินสด\" ด้านล่างเพื่อปิดการขายและทอนเงิน"
                                : "ลูกค้าจ่ายครบแล้ว ไม่มียอดค้างชำระ\nกดปุ่ม \"ไปคิดเงินสด\" ด้านล่างเพื่อปิดการขาย",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          }),

          _rowInput(
            "หมายเหตุ",
            _textField(
              controller.debtRemarkController,
              hint: "ระบุเพิ่มเติม...",
            ),
            unit: "",
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: _actionBtn(
                "ล้าง",
                Colors.grey.shade100,
                () => controller.confirmClearForm(checkoutController),
                textColor: Colors.black87,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              flex: 2,
              child: Obx(() {
                // จ่ายครบแล้ว = ไม่ใช่รายการค้างชำระ เปลี่ยนปุ่มเป็นไปคิดเงินสดแทน
                final bool cashCase = controller.isCashCase(
                  checkoutController.totalPrice.toDouble(),
                );

                if (cashCase) {
                  return _actionBtn(
                    "ไปคิดเงินสด",
                    _primaryColor,
                    () => controller.switchToCashCheckout(checkoutController),
                    textColor: Colors.white,
                    icon: Icons.point_of_sale_rounded,
                  );
                }

                return _actionBtn(
                  "ยืนยันการค้างชำระ",
                  _successColor,
                  () => controller.confirmSubmit(checkoutController),
                  textColor: Colors.white,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _rowLabelValue(
    String label,
    String value, {
    bool isBold = false,
    double valueSize = 18,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: Colors.blueGrey,
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: valueSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _rowInfo(
    String label,
    String value, {
    bool isBold = false,
    bool isRed = false,
    double valueSize = 16,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: isBold || isRed ? FontWeight.bold : FontWeight.w500,
                fontSize: valueSize,
                color: isRed ? Colors.red.shade600 : Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowInput(String label, Widget inputWidget, {String unit = "บาท"}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(flex: 3, child: inputWidget),
          if (unit.isNotEmpty) ...[
            const SizedBox(width: 10),
            Text(
              unit,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _rowInputSimple(String label, Widget inputWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(flex: 3, child: inputWidget),
        ],
      ),
    );
  }

  Widget _textField(
    TextEditingController ctrl, {
    bool isNumber = false,
    bool readOnly = false,
    String hint = "",
  }) {
    return TextField(
      controller: ctrl,
      readOnly: readOnly,
      textAlign: TextAlign.right,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))]
          : null,
      style: TextStyle(
        fontWeight: readOnly ? FontWeight.w500 : FontWeight.bold,
        fontSize: 16,
        color: readOnly ? Colors.grey.shade600 : Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        filled: true,
        fillColor: readOnly ? Colors.grey[50] : Colors.blueGrey.shade50,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: readOnly
            ? null
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF2563EB),
                  width: 1.5,
                ),
              ),
      ),
    );
  }

  Widget _actionBtn(
    String label,
    Color bgColor,
    VoidCallback onTap, {
    required Color textColor,
    IconData? icon,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: bgColor == Colors.white || bgColor == Colors.grey.shade100
            ? 0
            : 2,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: textColor),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
