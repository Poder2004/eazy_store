import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:eazy_store/page/sale_producct/bookListNoBarcode/book_list_no_barcode.dart';
import 'package:eazy_store/page/sale_producct/sale/checkout_page.dart';

// ----------------------------------------------------------------------
// 1. Controller: จัดการ Logic การสแกน
// ----------------------------------------------------------------------
class ScanBarcodeController extends GetxController with WidgetsBindingObserver {
  // ⚠️ เปลี่ยนเป็น late เพื่อกำหนดค่าใน onInit
  late MobileScannerController cameraController;

  var isFlashOn = false.obs;
  var isScanned = false.obs;

  @override
  void onInit() {
    super.onInit();
    // ✅ 1. เริ่มดักจับสถานะแอป (เช่น ตอนพับจอ)
    WidgetsBinding.instance.addObserver(this);

    // ✅ 2. สร้าง Controller ตรงนี้เพื่อให้มั่นใจว่าใหม่เสมอเมื่อเข้าหน้า
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
      returnImage: false, // เพิ่ม: ไม่ต้องประมวลผลรูปภาพ ช่วยลดภาระเครื่อง
    );
  }

  @override
  void onClose() {
    // ✅ 3. ลบตัวดักจับสถานะเมื่อหน้านี้ถูกปิด
    WidgetsBinding.instance.removeObserver(this);

    // ✅ 4. สำคัญมาก: สั่ง STOP ก่อน Dispose เพื่อแก้บัค BufferQueue
    cameraController.stop();
    cameraController.dispose();
    super.onClose();
  }

  // ✅ 5. ฟังก์ชันจัดการเมื่อ user พับจอ หรือสลับแอป
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!cameraController.value.isInitialized) return;

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        // กลับมาหน้าแอป -> สั่งเริ่มกล้องใหม่ (ป้องกันจอดำ)
        cameraController.start();
        break;
      case AppLifecycleState.inactive:
        // พับจอ/สลับแอป -> หยุดกล้องชั่วคราว
        cameraController.stop();
        break;
    }
  }

  void toggleFlash() {
    cameraController.toggleTorch();
    isFlashOn.value = !isFlashOn.value;
  }

  void onDetect(BarcodeCapture capture) {
    if (isScanned.value) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        isScanned.value = true;
        print('สแกนเจอแล้ว: ${barcode.rawValue}');

        // ส่งค่ากลับ
        Get.back(result: barcode.rawValue);
        break;
      }
    }
  }

  void onCapturePressed() {
    print("กดปุ่มถ่ายภาพ (Manual Capture)");
    // ✅ หยุดกล้องก่อนไปหน้าอื่น
    cameraController.stop();
    Get.to(() => const CheckoutPage());
  }

  void goToListPage() {
    // ✅ หยุดกล้องก่อนไปหน้าอื่น
    cameraController.stop();
    Get.to(() => const ManualListPage());
  }
}