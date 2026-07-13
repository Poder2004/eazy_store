import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:eazy_store/page/sale_producct/bookListNoBarcode/book_list_no_barcode.dart';

// ----------------------------------------------------------------------
// 1. Controller: จัดการ Logic การสแกน
// ----------------------------------------------------------------------
class ScanBarcodeController extends GetxController with WidgetsBindingObserver {
  // สมาชิกเล่นเสียง Beep ผ่าน AudioPool (ใช้ static เพื่อเล่นได้ทันทีแบบไม่มีดีเลย์ และเล่นซ้ำได้เรื่อยๆ)
  static AudioPool? _audioPool;

  static Future<void> _initAudioPool() async {
    if (_audioPool == null) {
      try {
        _audioPool = await AudioPool.create(
          source: AssetSource('sound/beep.mp3'),
          minPlayers: 1,
          maxPlayers: 3,
        );
      } catch (e) {
        print('Error initializing AudioPool: $e');
      }
    }
  }

  // ⚠️ เปลี่ยนเป็น late เพื่อกำหนดค่าใน onInit
  late MobileScannerController cameraController;

  var isFlashOn = false.obs;
  var isScanned = false.obs;

  @override
  void onInit() {
    super.onInit();
    // ✅ 1. เริ่มดักจับสถานะแอป (เช่น ตอนพับจอ)
    WidgetsBinding.instance.addObserver(this);

    // ✅ 2. โหลดเสียงเตรียมไว้ล่วงหน้า
    _initAudioPool();

    // ✅ 3. สร้าง Controller ตรงนี้เพื่อให้มั่นใจว่าใหม่เสมอเมื่อเข้าหน้า
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
      returnImage: false,
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

        // 1. สั่นเพื่อตอบสนอง (Haptic Feedback)
        HapticFeedback.lightImpact();

        // 2. ส่งเสียง Beep ด้วยไฟล์เสียงที่เราเลือกไว้ (เล่นจาก AudioPool เพื่อความลื่นไหลและไร้ดีเลย์)
        if (_audioPool != null) {
          _audioPool!.start();
        } else {
          // fallback ในกรณีสแกนเร็วมากก่อนที่ Pool จะโหลดเสร็จ
          AudioPlayer().play(AssetSource('sound/beep.mp3'), mode: PlayerMode.lowLatency);
        }

        Get.back(result: barcode.rawValue);
        break;
      }
    }
  }

  void goToListPage() {
    // ✅ หยุดกล้องก่อนไปหน้าอื่น
    cameraController.stop();
    Get.to(() => const ManualListPage());
  }
}
