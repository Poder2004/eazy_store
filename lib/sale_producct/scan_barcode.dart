import 'package:eazy_store/sale_producct/book_list_no_barcode.dart';
import 'package:eazy_store/sale_producct/checkout_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // อย่าลืมลง package นี้นะครับ

// ----------------------------------------------------------------------
// 1. Controller: จัดการ Logic การสแกน
// ----------------------------------------------------------------------
class ScanBarcodeController extends GetxController {
  // บังคับใช้กล้องหลัง (CameraFacing.back)
  final MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates, // ลดการสแกนรัวๆ
    facing: CameraFacing.back, // บังคับกล้องหลัง
    torchEnabled: false, // เริ่มต้นปิดแฟลช
  );

  // สถานะแฟลช
  var isFlashOn = false.obs;

  void toggleFlash() {
    cameraController.toggleTorch();
    isFlashOn.value = !isFlashOn.value;
  }

  // ฟังก์ชันเมื่อสแกนติด
  void onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        print('สแกนเจอแล้ว: ${barcode.rawValue}');
        Get.snackbar(
          "เจอสินค้า!",
          "รหัส: ${barcode.rawValue}",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        // TODO: ส่งค่าบาร์โค้ดไปหน้าถัดไป
        // cameraController.stop(); // หยุดกล้องถ้าต้องการเปลี่ยนหน้า
      }
    }
  }

  void onCapturePressed() {
    print("กดปุ่มถ่ายภาพ (Manual Capture)");

    Get.to(CheckoutPage());
    cameraController.stop();
  }

  void goToListPage() {
    Get.to(ManualListPage());
  }

  @override
  void onClose() {
    cameraController.dispose(); // คืนค่ากล้องเมื่อปิดหน้า
    super.onClose();
  }
}

// ----------------------------------------------------------------------
// 2. The View: หน้าจอ UI
// ----------------------------------------------------------------------
class ScanBarcodePage extends StatelessWidget {
  const ScanBarcodePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ScanBarcodeController controller = Get.put(ScanBarcodeController());

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // --- 1. Camera Layer (ชั้นล่างสุด) ---
          MobileScanner(
            controller: controller.cameraController,
            onDetect: controller.onDetect,
            fit: BoxFit.cover, // ขยายกล้องให้เต็มจอ
            // แก้ไข errorBuilder: ลบ child ออกเหลือแค่ 2 ตัว
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
                      const SizedBox(height: 10),
                      const Text(
                        "(กรุณารันบนมือถือจริง และอนุญาตให้ใช้กล้อง)",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // --- 2. Overlay Layer (เงาเจาะรู) ---
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

          // --- 3. UI Layer (กรอบแดง + เส้นเลเซอร์) ---
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

          // --- 4. ปุ่มปิด (ซ้ายบน) ---
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

          // --- 5. ปุ่มแฟลช (ขวาบน) ---
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
                      const SizedBox(
                        width: 40,
                        height: 40,
                      ), // ตัวหลอกจัด layout
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
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
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
                          child: Image.asset(
                            'assets/image/Book.png',
                            color: Colors.white,
                            width: 80,
                            height: 80,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 20,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "สแกนบาร์โค้ด ดูราคาสินค้า\nหรือ เปิดสมุดลิสต์ของที่ไม่มีบาร์โค้ด",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
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
