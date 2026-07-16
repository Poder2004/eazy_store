import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

// ✅ Import Controller ที่แยกออกไป
import 'scan_barcode_controller.dart';

// ----------------------------------------------------------------------
// 2. The View: หน้าจอ UI
// ----------------------------------------------------------------------
class ScanBarcodePage extends StatelessWidget {
  final bool showBookButton;

  const ScanBarcodePage({super.key, this.showBookButton = false});

  @override
  Widget build(BuildContext context) {
    // ใช้ Get.put เพื่อสร้าง Controller (มันจะถูกทำลายเมื่อออกจากหน้านี้)
    final ScanBarcodeController controller = Get.put(ScanBarcodeController());

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // --- 1. Camera Layer ---
          // ✅ แสดงกล้องเฉพาะเมื่อได้รับสิทธิ์แล้ว (Controller เป็นคนขอสิทธิ์เอง)
          // ระหว่างรอสิทธิ์จะเป็นจอดำ และมี Dialog ขอสิทธิ์ลอยอยู่ด้านบน
          Obx(
            () => controller.hasPermission.value
                ? MobileScanner(
                    controller: controller.cameraController,
                    onDetect: controller.onDetect,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error) {
                      // กรณีผู้ใช้ปฏิเสธสิทธิ์กล้อง ให้มีปุ่มพาไปเปิดในตั้งค่า
                      final isPermissionDenied = error.errorCode ==
                          MobileScannerErrorCode.permissionDenied;
                      return Container(
                        color: Colors.black,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPermissionDenied
                                    ? Icons.no_photography
                                    : Icons.error,
                                color: Colors.red,
                                size: 50,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                isPermissionDenied
                                    ? "กรุณาอนุญาตให้แอปเข้าถึงกล้อง\nเพื่อใช้งานการสแกนบาร์โค้ด"
                                    : "ไม่สามารถเปิดกล้องได้\n${error.errorCode}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white),
                              ),
                              if (isPermissionDenied) ...[
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: openAppSettings,
                                  icon: const Icon(Icons.settings),
                                  label: const Text("เปิดการตั้งค่า"),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : Container(color: Colors.black),
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
                if (showBookButton)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
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
                  )
                else
                  const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Text(
                    showBookButton
                        ? "สแกนบาร์โค้ด ดูราคาสินค้า\nหรือ เปิดสมุดลิสต์ของที่ไม่มีบาร์โค้ด"
                        : "จัดบาร์โค้ดให้อยู่ในกรอบเพื่อทำการสแกน",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
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
