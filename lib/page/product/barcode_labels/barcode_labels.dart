import 'package:eazy_store/page/product/barcode_labels/barcode_labels_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const Color _kPrimaryColor = Color(0xFF6B8E23);
const Color _kBackgroundColor = Color(0xFFF7F7F7);

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year + 543}';

class BarcodeLabelsScreen extends StatelessWidget {
  const BarcodeLabelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BarcodeLabelsController controller = Get.put(
      BarcodeLabelsController(),
    );

    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'พิมพ์บาร์โค้ดสินค้า',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Obx(() {
        final Widget generateBar = _buildGenerateBar(controller);
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: _kPrimaryColor),
          );
        }
        if (controller.products.isEmpty) {
          return Column(
            children: [
              generateBar,
              Expanded(
                child: _buildEmpty(
                  'ยังไม่มีบาร์โค้ดที่ร้านสร้างให้\n\nตอนเพิ่มหรือแก้ไขสินค้า กดปุ่มสร้างบาร์โค้ด (ไอคอนประกาย) ข้างช่องบาร์โค้ด เพื่อสร้างให้อัตโนมัติ',
                ),
              ),
            ],
          );
        }

        final shown = controller.visibleLabels;
        return Column(
          children: [
            generateBar,
            _buildFilterTabs(controller),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'เลือก ${controller.selectedIds.length} รายการ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  if (shown.isNotEmpty)
                    TextButton(
                      onPressed: controller.toggleAll,
                      child: Text(
                        controller.allSelected
                            ? 'ยกเลิกทั้งหมด'
                            : 'เลือกทั้งหมด',
                        style: const TextStyle(color: _kPrimaryColor),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: _kPrimaryColor,
                onRefresh: controller.loadProducts,
                child: shown.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: 240,
                            child: _buildEmpty(
                              controller.filter.value == LabelFilter.unprinted
                                  ? 'ไม่มีรายการใหม่ที่ต้องพิมพ์\nพิมพ์ครบทุกรายการแล้ว'
                                  : 'ยังไม่มีรายการที่พิมพ์แล้ว',
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: shown.length,
                        itemBuilder: (context, i) =>
                            _buildLabelTile(controller, shown[i]),
                      ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: controller.selectedIds.isEmpty
                        ? null
                        : controller.exportPdf,
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: Text(
                      controller.selectedIds.isEmpty
                          ? 'สร้าง PDF เพื่อพิมพ์'
                          : 'สร้าง PDF เพื่อพิมพ์ (${controller.selectedIds.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildEmpty(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600], height: 1.5),
        ),
      ),
    );
  }

  Widget _buildFilterTabs(BarcodeLabelsController controller) {
    Widget chip(LabelFilter value, String label, int count) {
      final selected = controller.filter.value == value;
      return ChoiceChip(
        label: Text('$label ($count)'),
        selected: selected,
        showCheckmark: false,
        selectedColor: _kPrimaryColor,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
        onSelected: (_) => controller.filter.value = value,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Wrap(
        spacing: 8,
        children: [
          chip(LabelFilter.unprinted, 'ยังไม่พิมพ์', controller.unprintedCount),
          chip(LabelFilter.printed, 'พิมพ์แล้ว', controller.printedCount),
          chip(LabelFilter.all, 'ทั้งหมด', controller.products.length),
        ],
      ),
    );
  }

  Widget _buildLabelTile(BarcodeLabelsController controller, BarcodeLabel l) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: CheckboxListTile(
        activeColor: _kPrimaryColor,
        value: controller.selectedIds.contains(l.key),
        onChanged: (_) => controller.toggle(l),
        title: Row(
          children: [
            Flexible(
              child: Text(
                l.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _statusBadge(l),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                l.isPrinted
                    ? '${l.barcode} · พิมพ์เมื่อ ${_fmtDate(l.printedAt!)}'
                    : l.barcode,
                style: TextStyle(color: Colors.grey[600], fontSize: 12.5),
              ),
            ),
            if (l.isPrinted)
              InkWell(
                onTap: controller.isMarking.value
                    ? null
                    : () => controller.markAsNew(l),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'ทำเป็นใหม่',
                    style: TextStyle(
                      color: _kPrimaryColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(BarcodeLabel l) {
    final printed = l.isPrinted;
    final color = printed ? Colors.grey.shade600 : Colors.orange.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        printed ? 'พิมพ์แล้ว' : 'ใหม่',
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildGenerateBar(BarcodeLabelsController controller) {
    final count = controller.missing.length;
    if (count == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: controller.isGenerating.value
              ? null
              : controller.generateForMissing,
          icon: controller.isGenerating.value
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome),
          label: Text('สร้างบาร์โค้ดให้สินค้าที่ยังไม่มี ($count รายการ)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _kPrimaryColor,
            side: const BorderSide(color: _kPrimaryColor),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
