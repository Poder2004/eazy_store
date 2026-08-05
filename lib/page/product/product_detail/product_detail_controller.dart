// ไฟล์: lib/page/product/product_detail_controller.dart
import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/model/response/product_response.dart';
import 'package:eazy_store/widgets/info_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductDetailController extends GetxController {
  late Rx<ProductResponse> product;
  var isStatusLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // รับค่า Product มาจาก arguments
    if (Get.arguments != null && Get.arguments is ProductResponse) {
      product = (Get.arguments as ProductResponse).obs;
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
        // ✨ ใช้ Dialog แทน Snackbar เพราะข้อความยาวและสำคัญ ต้องให้ผู้ใช้อ่านจบก่อนปิดเอง
        // ✨ เปลี่ยนคำอธิบายให้เข้าใจง่ายขึ้น (คนทั่วไปที่ไม่รู้จักระบบอ่านแล้วต้องเข้าใจ)
        if (result['status'] == 'hidden') {
          InfoDialog.show(
            title: "ซ่อนสินค้าเรียบร้อยแล้ว",
            message:
                "สินค้านี้เคยถูกขายไปแล้ว จึงไม่สามารถลบออกจากระบบได้ทั้งหมด\n"
                "ระบบจึงซ่อนสินค้านี้ไว้แทน จะไม่แสดงในหน้าขายสินค้าอีกต่อไป",
            icon: Icons.visibility_off_rounded,
            iconColor: Colors.orange,
          );
        } else {
          InfoDialog.show(
            title: "ลบสินค้าสำเร็จ",
            message: "ลบสินค้าออกจากระบบเรียบร้อยแล้ว",
          );
        }
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
