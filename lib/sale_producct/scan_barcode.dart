import 'package:eazy_store/sale_producct/book_list_no_barcode.dart';
import 'package:eazy_store/sale_producct/checkout_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// ----------------------------------------------------------------------
// 1. Controller: จัดการ Logic การสแกน (แก้ไขแล้ว ✅)
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
    Get.to(() => CheckoutPage());
  }

  void goToListPage() {
    // ✅ หยุดกล้องก่อนไปหน้าอื่น
    cameraController.stop();
    Get.to(() => ManualListPage());
  }
}

// ----------------------------------------------------------------------
// 2. The View: หน้าจอ UI (เหมือนเดิม)
// ----------------------------------------------------------------------
class ScanBarcodePage extends StatelessWidget {
  const ScanBarcodePage({super.key});

  @override
  Widget build(BuildContext context) {
    // ใช้ Get.put เพื่อสร้าง Controller (มันจะถูกทำลายเมื่อออกจากหน้านี้)
    final ScanBarcodeController controller = Get.put(ScanBarcodeController());

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // --- 1. Camera Layer ---
          MobileScanner(
            controller: controller.cameraController,
            onDetect: controller.onDetect,
            fit: BoxFit.cover,
            errorBuilder: (context, error) {
              return Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 50),
                      const SizedBox(height: 10),
                      Text(
                        "ไม่สามารถเปิดกล้องได้\n${error.errorCode}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // --- 2. Overlay Layer ---
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    height: 280,
                    width: 280,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- 3. UI Layer ---
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 280,
                  width: 280,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.redAccent, width: 4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                Container(
                  height: 2,
                  width: 260,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.6),
                        spreadRadius: 2,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- 4. ปุ่มปิด ---
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
          ),

          // --- 5. ปุ่มแฟลช ---
          Positioned(
            top: 50,
            right: 20,
            child: Obx(
              () => GestureDetector(
                onTap: controller.toggleFlash,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: controller.isFlashOn.value
                        ? Colors.white.withOpacity(0.8)
                        : Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    controller.isFlashOn.value
                        ? Icons.flash_on
                        : Icons.flash_off,
                    color: controller.isFlashOn.value
                        ? Colors.black
                        : Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          // --- 6. Bottom UI ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40, height: 40),
                      // ปุ่มถ่ายรูป (Shutter)
                      GestureDetector(
                        onTap: controller.onCapturePressed,
                        child: Container(
                          height: 70,
                          width: 70,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.5),
                              width: 4,
                            ),
                          ),
                        ),
                      ),
                      // ปุ่มสมุด
                      GestureDetector(
                        onTap: controller.goToListPage,
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.book, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "สแกนบาร์โค้ด ดูราคาสินค้า\nหรือ เปิดสมุดลิสต์ของที่ไม่มีบาร์โค้ด",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
