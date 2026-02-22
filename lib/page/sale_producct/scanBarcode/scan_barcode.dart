import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// ✅ Import Controller ที่แยกออกไป
import 'scan_barcode_controller.dart';

// ----------------------------------------------------------------------
// 2. The View: หน้าจอ UI
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