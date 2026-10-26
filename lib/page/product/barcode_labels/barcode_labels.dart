import 'package:eazy_store/page/product/barcode_labels/barcode_labels_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const Color _kPrimaryColor = Color(0xFF6B8E23);
const Color _kBackgroundColor = Color(0xFFF7F7F7);

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
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'ยังไม่มีบาร์โค้ดที่ร้านสร้างให้\n\nตอนเพิ่มหรือแก้ไขสินค้า กดปุ่มสร้างบาร์โค้ด (ไอคอนประกาย) ข้างช่องบาร์โค้ด เพื่อสร้างให้อัตโนมัติ',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], height: 1.5),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            generateBar,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'เลือก ${controller.selectedIds.length}/${controller.products.length} รายการ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: controller.toggleAll,
                    child: Text(
                      controller.allSelected ? 'ยกเลิกทั้งหมด' : 'เลือกทั้งหมด',
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
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: controller.products.length,
                  itemBuilder: (context, i) {
                    final p = controller.products[i];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CheckboxListTile(
                        activeColor: _kPrimaryColor,
                        value: controller.selectedIds.contains(p.key),
                        onChanged: (_) => controller.toggle(p),
                        title: Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          p.barcode,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    );
                  },
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
                    onPressed: controller.exportPdf,
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text(
                      'สร้าง PDF เพื่อพิมพ์',
                      style: TextStyle(
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
