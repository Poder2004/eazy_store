import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/model/response/product_response.dart';
import 'package:eazy_store/utils/internal_barcode.dart';
import 'package:eazy_store/utils/thai_sort.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// หนึ่งดวงบาร์โค้ดที่จะพิมพ์ (บาร์โค้ดหลักของสินค้า หรือบาร์โค้ดของหน่วยขาย เช่น แผง)
class BarcodeLabel {
  final String key;
  final String name;
  final String barcode;
  // ถ้าเป็นฉลากของสินค้าหลักมี productId ถ้าเป็นของหน่วยขายมี unitId (ใช้ทำเครื่องหมายพิมพ์แล้วที่ backend)
  final int? productId;
  final int? unitId;
  // เวลาที่พิมพ์ไปแล้ว (null = ใหม่ ยังไม่เคยพิมพ์)
  final DateTime? printedAt;
  const BarcodeLabel({
    required this.key,
    required this.name,
    required this.barcode,
    this.productId,
    this.unitId,
    this.printedAt,
  });

  bool get isPrinted => printedAt != null;
}

/// แท็บกรองรายการในหน้าพิมพ์บาร์โค้ด
enum LabelFilter { unprinted, printed, all }

class BarcodeLabelsController extends GetxController {
  var isLoading = true.obs;
  var products = <BarcodeLabel>[].obs;
  // สินค้าที่ยังไม่มีบาร์โค้ดเลย (ให้กดสร้างให้ทีเดียวได้)
  var missing = <ProductResponse>[].obs;
  var isGenerating = false.obs;
  // เก็บ key ที่ถูกติ๊กเลือก (ค่าเริ่มต้น เลือกเฉพาะรายการ "ใหม่" ที่ยังไม่เคยพิมพ์)
  var selectedIds = <String>{}.obs;
  var filter = LabelFilter.unprinted.obs;
  var isMarking = false.obs;

  int get unprintedCount => products.where((l) => !l.isPrinted).length;
  int get printedCount => products.where((l) => l.isPrinted).length;

  // รายการที่แสดงตามแท็บที่เลือก
  List<BarcodeLabel> get visibleLabels => switch (filter.value) {
    LabelFilter.unprinted => products.where((l) => !l.isPrinted).toList(),
    LabelFilter.printed => products.where((l) => l.isPrinted).toList(),
    LabelFilter.all => products.toList(),
  };

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  Future<void> loadProducts() async {
    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final shopId = prefs.getInt('shopId') ?? 0;
      final result = await ApiProduct.getProductsByShop(shopId, limit: 100000);

      List<ProductResponse> list = [];
      if (result is ProductPagedResponse) {
        list = result.items;
      } else if (result is List<ProductResponse>) {
        list = result;
      }

      // เอาเฉพาะบาร์โค้ดที่ร้านสร้างให้เอง (prefix 20 ตรวจเลขตรวจสอบผ่าน)
      // ทั้งบาร์โค้ดหลักของสินค้า และบาร์โค้ดของหน่วยขายเพิ่มเติม (เช่น ไข่ไก่ แผง)
      final active = list.where((p) => p.status == true).toList()
        ..sort((a, b) => thaiSortKey(a.name).compareTo(thaiSortKey(b.name)));

      final labels = <BarcodeLabel>[];
      for (final p in active) {
        if (isInternalBarcode(p.barcode)) {
          labels.add(
            BarcodeLabel(
              key: 'p${p.productId}',
              productId: p.productId,
              printedAt: p.barcodePrintedAt,
              // สินค้าที่มีหลายหน่วย (เช่น ไข่ ลูก/แผง) ต้องบอกหน่วยฐานบนฉลากด้วย กันสับสน
              name: p.activeUnits.isEmpty || p.unit.isEmpty
                  ? p.name
                  : '${p.name} (${p.unit})',
              barcode: p.barcode!,
            ),
          );
        }
        for (final u in p.activeUnits) {
          if (isInternalBarcode(u.barcode)) {
            labels.add(
              BarcodeLabel(
                key: 'u${u.productUnitId}',
                unitId: u.productUnitId,
                printedAt: u.barcodePrintedAt,
                name: '${p.name} (${u.unitName})',
                barcode: u.barcode!,
              ),
            );
          }
        }
      }

      missing.assignAll(
        active.where(
          (p) => p.productId != null && (p.barcode ?? '').trim().isEmpty,
        ),
      );
      products.assignAll(labels);
      // ค่าเริ่มต้นเลือกเฉพาะรายการใหม่ กันหลงพิมพ์ฉลากชุดเดิมซ้ำ
      selectedIds
        ..clear()
        ..addAll(labels.where((l) => !l.isPrinted).map((l) => l.key));
    } catch (e) {
      debugPrint('Load barcode products error: $e');
      products.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // "เลือกทั้งหมด" นับเฉพาะรายการที่แสดงอยู่ในแท็บปัจจุบัน
  bool get allSelected {
    final shown = visibleLabels;
    return shown.isNotEmpty && shown.every((l) => selectedIds.contains(l.key));
  }

  void toggleAll() {
    final shown = visibleLabels;
    if (allSelected) {
      selectedIds.removeAll(shown.map((l) => l.key));
    } else {
      selectedIds.addAll(shown.map((l) => l.key));
    }
  }

  void toggle(BarcodeLabel l) {
    if (!selectedIds.remove(l.key)) selectedIds.add(l.key);
  }

  // สร้างบาร์โค้ดให้สินค้าที่ยังไม่มีบาร์โค้ดทุกรายการ (ไม่แตะสินค้าที่มีบาร์โค้ดอยู่แล้ว)
  Future<void> generateForMissing() async {
    final targets = missing.toList();
    if (targets.isEmpty || isGenerating.value) return;

    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('สร้างบาร์โค้ดให้ทุกรายการ'),
        content: Text(
          'จะสร้างบาร์โค้ดให้สินค้า ${targets.length} รายการที่ยังไม่มีบาร์โค้ด\n'
          'สินค้าที่มีบาร์โค้ดอยู่แล้วจะไม่ถูกเปลี่ยน',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('สร้างเลย'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    isGenerating.value = true;
    var done = 0;
    var failed = 0;
    for (final p in targets) {
      var saved = false;
      // รหัสชน (409) แทบไม่เกิด แต่ถ้าเกิดให้สุ่มใหม่อีกไม่เกิน 3 ครั้ง
      for (var attempt = 0; attempt < 3 && !saved; attempt++) {
        final res = await ApiProduct.updateProduct(p.productId!, {
          'barcode': generateInternalBarcode(),
        });
        saved = res['success'] == true;
      }
      saved ? done++ : failed++;
    }
    isGenerating.value = false;

    Get.snackbar(
      failed == 0 ? 'สร้างบาร์โค้ดเรียบร้อย' : 'สร้างได้บางรายการ',
      failed == 0
          ? 'สร้างให้ $done รายการ'
          : 'สำเร็จ $done รายการ ไม่สำเร็จ $failed รายการ (ลองกดใหม่อีกครั้ง)',
      backgroundColor: failed == 0 ? Colors.green : Colors.orange,
      colorText: Colors.white,
    );
    await loadProducts();
  }

  Future<int> _shopId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('shopId') ?? 0;
  }

  Future<void> _askMarkPrinted(List<BarcodeLabel> labels) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('พิมพ์เรียบร้อยแล้วใช่ไหม?'),
        content: Text(
          'ถ้าพิมพ์สำเร็จ จะทำเครื่องหมาย "พิมพ์แล้ว" ให้ ${labels.length} รายการ '
          'ครั้งหน้าจะไม่ถูกเลือกพิมพ์ซ้ำโดยอัตโนมัติ',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('ยังไม่ได้พิมพ์'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('พิมพ์แล้ว'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    if (ok == true) await _setPrinted(labels, true);
  }

  // ยกเลิกเครื่องหมาย "พิมพ์แล้ว" กลับเป็น "ใหม่" (เช่น ฉลากเก่าขาดหรือซีด ต้องพิมพ์ใหม่)
  Future<void> markAsNew(BarcodeLabel label) async {
    await _setPrinted([label], false);
    // ให้ติ๊กเลือกไว้เลย เพราะตั้งใจจะพิมพ์ใหม่
    selectedIds.add(label.key);
  }

  Future<void> _setPrinted(List<BarcodeLabel> labels, bool printed) async {
    if (isMarking.value) return;
    isMarking.value = true;
    try {
      final res = await ApiProduct.markBarcodesPrinted(
        shopId: await _shopId(),
        productIds: labels.map((l) => l.productId).whereType<int>().toList(),
        unitIds: labels.map((l) => l.unitId).whereType<int>().toList(),
        printed: printed,
      );
      if (res['success'] != true) {
        Get.snackbar(
          'บันทึกสถานะไม่สำเร็จ',
          '${res['message']}',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return;
      }
      // เก็บการติ๊กเลือกของรายการอื่นไว้ ไม่รีเซ็ตทั้งหมด
      final keep = selectedIds.toSet()..removeAll(labels.map((l) => l.key));
      await loadProducts();
      selectedIds
        ..clear()
        ..addAll(keep);
    } finally {
      isMarking.value = false;
    }
  }

  // สร้าง PDF แผ่นบาร์โค้ด แล้วเปิดหน้าตัวอย่าง (พิมพ์ / บันทึก / แชร์ ได้จากหน้านั้น)
  Future<void> exportPdf() async {
    final chosen = products.where((l) => selectedIds.contains(l.key)).toList();
    if (chosen.isEmpty) {
      Get.snackbar(
        'ยังไม่ได้เลือกสินค้า',
        'กรุณาติ๊กเลือกสินค้าที่ต้องการพิมพ์บาร์โค้ด',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    try {
      final regular = await PdfGoogleFonts.notoSansThaiRegular();
      final bold = await PdfGoogleFonts.notoSansThaiBold();
      final doc = pw.Document(
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
      );

      const columns = 3;
      const rowsPerPage = 8;
      const perPage = columns * rowsPerPage;

      for (var start = 0; start < chosen.length; start += perPage) {
        final pageItems = chosen.skip(start).take(perPage).toList();
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (_) =>
                pw.Wrap(children: [for (final p in pageItems) _label(p)]),
          ),
        );
      }

      final bytes = await doc.save();
      Get.back(); // ปิด loading
      await Printing.layoutPdf(
        name: 'barcode-labels',
        onLayout: (_) async => bytes,
      );
      // กดสร้างหรือดูตัวอย่างไม่ได้แปลว่าพิมพ์จริง จึงถามก่อนค่อยทำเครื่องหมาย
      await _askMarkPrinted(chosen);
    } catch (e) {
      debugPrint('Export barcode PDF error: $e');
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar(
        'สร้าง PDF ไม่สำเร็จ',
        'ตรวจสอบอินเทอร์เน็ต (ต้องโหลดฟอนต์ภาษาไทย) แล้วลองใหม่อีกครั้ง',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  pw.Widget _label(BarcodeLabel p) {
    // A4 กว้าง 595pt - ขอบ 40 = 555 / 3 คอลัมน์ | 8 แถว (สูงราว 95pt)
    return pw.Container(
      width: 555 / 3,
      height: 95,
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            p.name,
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 3),
          pw.Expanded(
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.ean13(),
              data: p.barcode,
              drawText: true,
              textStyle: const pw.TextStyle(fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }
}
