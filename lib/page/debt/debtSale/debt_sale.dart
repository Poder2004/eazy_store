import 'package:flutter/material.dart';
import 'package:get/get.dart';

// --- Imports ---
import '../../sale_producct/sale/checkout_controller.dart';
import 'package:eazy_store/page/debt/debtRegister/debt_register.dart';
import 'debt_sale_controller.dart';

class DebtSalePage extends StatelessWidget {
  DebtSalePage({super.key});

  final DebtSaleController controller = Get.put(DebtSaleController());
  final CheckoutController checkoutController = Get.find<CheckoutController>();

  final Color _bgColor = const Color(0xFFF4F7FA);
  final Color _cardColor = Colors.white;
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
                    // --- 1. ส่วนค้นหาลูกหนี้ ---
                    const Text(
                      "ข้อมูลลูกหนี้",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildSearchBar(),
                    const SizedBox(height: 10),

                    // ✨ เพิ่มปุ่ม "สร้างลูกหนี้ใหม่" ไว้ใต้ช่องค้นหา จัดวางแบบพรีเมียม
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => Get.to(() => DebtRegisterScreen()),
                        icon: const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          "สร้างลูกหนี้ใหม่",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: _primaryColor,
                          backgroundColor: _primaryColor.withOpacity(
                            0.08,
                          ), // สีพื้นหลังจางๆ ดูสบายตา
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),

                    _buildSearchResults(),
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

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller.searchController,
        onChanged: controller.onSearchChanged,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: 'กรอกชื่อหรือเบอร์ลูกหนี้เพื่อค้นหา...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14.0,
            horizontal: 16.0,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
          suffixIcon: Obx(() {
            if (controller.isSearching.value) {
              return const Padding(
                padding: EdgeInsets.all(14.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            } else if (!controller.isSearchEmpty.value) {
              return IconButton(
                icon: const Icon(Icons.cancel_rounded, color: Colors.grey),
                onPressed: controller.clearSearch,
              );
            }
            return const SizedBox.shrink();
          }),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Obx(() {
      if (controller.showResults.value) {
        return Container(
          margin: const EdgeInsets.only(top: 8),
          constraints: const BoxConstraints(maxHeight: 250),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: controller.searchResults.length,
            separatorBuilder: (ctx, i) =>
                Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (ctx, i) {
              final item = controller.searchResults[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: CircleAvatar(
                  backgroundColor: _primaryColor.withOpacity(0.1),
                  backgroundImage:
                      (item.imgDebtor != null && item.imgDebtor!.isNotEmpty)
                      ? NetworkImage(item.imgDebtor!)
                      : null,
                  child: (item.imgDebtor == null || item.imgDebtor!.isEmpty)
                      ? Text(
                          item.name.isNotEmpty
                              ? item.name[0].toUpperCase()
                              : "?",
                          style: TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  item.phone,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                trailing: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.grey,
                ),
                onTap: () => controller.selectDebtor(item),
              );
            },
          ),
        );
      }
      // ลบปุ่ม Fallback เก่าที่ซ้อนทับออกไปแล้ว
      return const SizedBox.shrink();
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
                _buildQtyCounter(item, checkoutController),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "${items.length} ${item.category == 'เครื่องดื่ม' ? 'ขวด' : 'ชิ้น'}",
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    ],
                  ),
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
            int debt =
                (checkoutController.totalPrice - controller.payAmount.value)
                    .toInt();
            return _rowInfo(
              "ยอดที่เซ็นค้าง",
              "$debt บาท",
              isRed: true,
              valueSize: 18,
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
                () => controller.clearForm(checkoutController),
                textColor: Colors.black87,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              flex: 2,
              child: _actionBtn(
                "ยืนยันการค้างชำระ",
                _successColor,
                () => controller.confirmSubmit(checkoutController),
                textColor: Colors.white,
              ),
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

  Widget _buildQtyCounter(dynamic item, CheckoutController controller) {
    return Column(
      children: [
        _miniBtn(Icons.add, () => controller.increaseItem(item)),
        const SizedBox(height: 5),
        _miniBtn(Icons.remove, () => controller.decreaseItem(item)),
      ],
    );
  }

  Widget _miniBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 16, color: Colors.black87),
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
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
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
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
