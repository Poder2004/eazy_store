import 'dart:io'; // ✨ นำเข้า File
import 'package:eazy_store/api/api_service_image.dart';
import 'package:flutter/material.dart';
import '../../../model/response/debtor_response.dart';
import '../../../model/request/debtor_history_model.dart';
import '../../../api/api_debtor.dart';
// ✨ อย่าลืม import ImageUploadService ของคุณให้ตรง Path นะครับ
// import '../../../services/image_upload_service.dart';

class DebtorDetailController extends ChangeNotifier {
  late DebtorResponse currentDebtor;
  List<DebtorHistoryResponse> historyList = [];
  bool isLoading = true;

  // ✨ เพิ่มตัวแปรเช็คสถานะตอนกดบันทึก
  bool isUpdating = false;

  void init(DebtorResponse debtor) {
    currentDebtor = debtor;
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    isLoading = true;
    notifyListeners();

    try {
      final result = await ApiDebtor.getDebtorHistory(currentDebtor.debtorId!);

      if (result != null) {
        List<dynamic> rawHistories = result['histories'] ?? [];

        List<DebtorHistoryResponse> fetchedHistory = rawHistories.map((bill) {
          List<dynamic> rawItems = bill['items'] ?? [];
          List<DebtorHistoryItem> itemsList = rawItems.map((item) {
            return DebtorHistoryItem(
              name: item['name'] ?? 'ไม่ทราบชื่อ',
              qty: item['qty'] ?? 0,
              unit: item['unit']?.toString() ?? '',
              price: double.parse((item['price'] ?? 0).toString()),
            );
          }).toList();

          return DebtorHistoryResponse(
            orderId: bill['order_id'] ?? 0,
            date: bill['date'] ?? '-',
            totalAmount: double.parse((bill['total_amount'] ?? 0).toString()),
            paidAmount: double.parse((bill['paid_amount'] ?? 0).toString()),
            remainingAmount: double.parse(
              (bill['remaining_amount'] ?? 0).toString(),
            ),
            items: itemsList,
          );
        }).toList();

        historyList = fetchedHistory;
      }
    } catch (e) {
      print("Error fetching history: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ✨ แก้ไขฟังก์ชันนี้ให้รองรับการอัปโหลดรูปภาพ และเรียก API
  Future<bool> updateDebtorData({
    required String name,
    required String phone,
    required String address,
    required double creditLimit,
    File? imageFile, // ✨ รับไฟล์รูปมาด้วย
  }) async {
    isUpdating = true;
    notifyListeners(); // ให้หน้าจอโชว์ Loading (ถ้ามีการดักไว้)

    try {
      String? newImageUrl;

      // 1. ถ้ามีการเลือกรูปใหม่ ให้อัปโหลดขึ้น Cloudinary ก่อน
      if (imageFile != null) {
        newImageUrl = await ImageUploadService().uploadImage(imageFile);
      }

      // 2. เตรียมข้อมูล (Partial Update)
      Map<String, dynamic> updateData = {
        "name": name,
        "phone": phone,
        "address": address,
        "credit_limit": creditLimit,
      };

      // 3. ถ้ารูปอัปโหลดสำเร็จ ค่อยแนบ URL ใหม่ไปกับ Data
      if (newImageUrl != null) {
        updateData["img_debtor"] = newImageUrl;
      }

      // 4. ยิง API บันทึกข้อมูล
      final result = await ApiDebtor.updateDebtor(
        currentDebtor.debtorId!,
        updateData,
      );

      if (result['success'] == true) {
        // เอาข้อมูลล่าสุดที่ API ตอบกลับมา ทับของเดิม
        currentDebtor = result['data'];
        return true;
      } else {
        print("Update Failed: ${result['message']}");
        return false;
      }
    } catch (e) {
      print("Error: $e");
      return false;
    } finally {
      isUpdating = false;
      notifyListeners(); // โหลดเสร็จสั่งให้หน้าจออัปเดตโชว์ข้อมูลใหม่
    }
  }
}
