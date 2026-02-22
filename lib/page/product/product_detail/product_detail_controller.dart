// ไฟล์: lib/page/product/product_detail_controller.dart
import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/model/request/product_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductDetailController extends GetxController {
  late Rx<Product> product;
  var isStatusLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // รับค่า Product มาจาก arguments
    if (Get.arguments != null && Get.arguments is Product) {
      product = (Get.arguments as Product).obs;
    } else {
      // กรณีไม่มีข้อมูลส่งมา ให้เด้งกลับเพื่อป้องกัน Error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.back();
        Get.snackbar("Error", "ไม่พบข้อมูลสินค้า");
      });
    }
  }

  // ✅ ฟังก์ชันลบสินค้า (ต่อ API จริง)
  Future<void> deleteProduct() async {
    Get.back(); // ปิด Dialog ยืนยันก่อน

    // โชว์วงกลมโหลด
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      final result = await ApiProduct.deleteProduct(product.value.productId!);
      Get.back(); // ปิดวงกลมโหลด

      if (result['success']) {
        Get.back(
          result: true,
        ); // กลับไปหน้ารายการสินค้า พร้อมส่ง true กลับไปเพื่อให้หน้าก่อนหน้ารีเฟรช

        // เช็คว่าเป็นการลบจริง หรือแค่ซ่อน เพื่อแสดงข้อความให้เหมาะสม
        String msg = result['status'] == 'hidden'
            ? "สินค้านี้เคยถูกขายแล้ว ระบบได้ทำการซ่อนสินค้าแทนการลบถาวร"
            : "ลบสินค้าออกจากระบบเรียบร้อยแล้ว";

        Get.snackbar(
          "สำเร็จ",
          msg,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          "ผิดพลาด",
          result['error'],
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back(); // ปิดวงกลมโหลด
      Get.snackbar(
        "ผิดพลาด",
        "เกิดข้อผิดพลาด: $e",
        backgroundColor: Colors.red,
      );
    }
  }
}
