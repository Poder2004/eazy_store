import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:eazy_store/page/homepage/home_page.dart';
import 'package:eazy_store/page/sale_producct/bookListNoBarcode/book_list_no_barcode.dart';
import 'package:eazy_store/widgets/confirm_dialog.dart';

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

  // ✅ สถานะสิทธิ์กล้อง: จะเปิดกล้องก็ต่อเมื่อได้รับอนุญาตแล้วเท่านั้น
  var hasPermission = false.obs;

  @override
  void onInit() {
    super.onInit();
    // ✅ 1. เริ่มดักจับสถานะแอป (เช่น ตอนพับจอ)
    WidgetsBinding.instance.addObserver(this);

    // ✅ 2. โหลดเสียงเตรียมไว้ล่วงหน้า
    _initAudioPool();

    // ✅ 3. สร้าง Controller ตรงนี้เพื่อให้มั่นใจว่าใหม่เสมอเมื่อเข้าหน้า
    // autoStart: false เพราะเราจะขอสิทธิ์เองก่อน แล้วค่อยสั่ง start
    // (ถ้าปล่อยให้ mobile_scanner ขอเอง จะเกิด dialog เด้งวนตอนถูกปฏิเสธ)
    cameraController = MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
      returnImage: false,
    );
  }

  @override
  void onReady() {
    super.onReady();
    // ✅ ขอสิทธิ์กล้องหลังหน้าจอแสดงผลแล้ว
    requestCameraPermission();
  }

  // ✅ ขอสิทธิ์กล้อง: ได้รับ -> เปิดกล้อง / ถูกปฏิเสธ -> ถามผู้ใช้ว่าจะขออีกครั้งไหม
  Future<void> requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      _startCamera();
      return;
    }

    // ⚠️ Quirk ของ Android: ถ้าผู้ใช้เคยปฏิเสธครบ 2 ครั้ง ระบบจะไม่แสดง dialog
    // ขอสิทธิ์อีกเลย แต่ request() บางเครื่องยังคืนค่า denied เฉยๆ
    // (ไม่ใช่ permanentlyDenied) ทำให้ปุ่ม "ขอสิทธิ์อีกครั้ง" กดแล้วเงียบ
    // จึงเช็ค shouldShowRequestRationale เพิ่ม: ถ้า false = ระบบไม่ให้ขอซ้ำแล้ว
    bool isPermanent = status.isPermanentlyDenied;
    if (!isPermanent && GetPlatform.isAndroid) {
      isPermanent = !(await Permission.camera.shouldShowRequestRationale);
    }
    _showPermissionDialog(isPermanentlyDenied: isPermanent);
  }

  void _startCamera() {
    if (hasPermission.value) return; // กันสั่ง start ซ้ำ
    hasPermission.value = true;
    cameraController.start();
  }

  // ✅ Dialog เมื่อถูกปฏิเสธสิทธิ์
  // - ปฏิเสธธรรมดา: ปุ่ม "ขอสิทธิ์อีกครั้ง"
  // - ปฏิเสธถาวร: ปุ่ม "เปิดการตั้งค่า" (ระบบไม่ยอมให้ขอซ้ำแล้ว)
  // - ปุ่ม "ยกเลิก": กลับไปหน้า Home
  void _showPermissionDialog({required bool isPermanentlyDenied}) {
    ConfirmDialog.show(
      title: "ไม่ได้รับสิทธิ์กล้อง",
      message: isPermanentlyDenied
          ? "แอปต้องใช้กล้องเพื่อสแกนบาร์โค้ด\nกรุณาไปเปิดสิทธิ์กล้องในการตั้งค่า"
          : "แอปต้องใช้กล้องเพื่อสแกนบาร์โค้ด\nต้องการขอสิทธิ์อีกครั้งหรือไม่?",
      icon: Icons.no_photography_rounded,
      confirmColor: const Color(0xFFC0392B),
      confirmLabel: isPermanentlyDenied ? "เปิดการตั้งค่า" : "ขอสิทธิ์อีกครั้ง",
      barrierDismissible: false,
      onCancel: () => Get.offAll(() => const HomePage()), // กลับหน้า Home
      onConfirm: () {
        if (isPermanentlyDenied) {
          // กลับมาจากหน้าตั้งค่าแล้ว จะเช็คสิทธิ์ใหม่ใน didChangeAppLifecycleState
          openAppSettings();
        } else {
          requestCameraPermission();
        }
      },
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
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        if (hasPermission.value) {
          // กลับมาหน้าแอป -> สั่งเริ่มกล้องใหม่ (ป้องกันจอดำ)
          cameraController.start();
        } else {
          // ⚠️ ยังไม่ได้สิทธิ์: ห้าม request ตรงนี้เด็ดขาด
          // (dialog ขอสิทธิ์ของระบบทำให้แอป inactive->resumed วนไม่รู้จบ)
          // แค่เช็คสถานะเฉยๆ เผื่อผู้ใช้เพิ่งกลับมาจากหน้าตั้งค่าหลังเปิดสิทธิ์ให้แล้ว
          final status = await Permission.camera.status;
          if (status.isGranted) _startCamera();
        }
        break;
      case AppLifecycleState.inactive:
        // พับจอ/สลับแอป -> หยุดกล้องชั่วคราว (stop มี guard ภายใน ปลอดภัยแม้ยังไม่เปิด)
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
