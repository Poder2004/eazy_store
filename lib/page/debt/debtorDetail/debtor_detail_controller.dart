import 'dart:io';
import 'package:eazy_store/model/response/debtor_history_model.dart';
import 'package:flutter/material.dart';
import '../../../model/response/debtor_response.dart';
import '../../../model/request/debtor_history_model.dart'; // ตัวนี้ต้องมีทั้ง DebtorHistoryResponse และ PaymentHistoryResponse
import '../../../api/api_debtor.dart';
import '../../../api/api_payment.dart';
import '../../../api/api_service_image.dart';

class DebtorDetailController extends ChangeNotifier {
  late DebtorResponse currentDebtor;
  List<DebtorHistoryResponse> historyList = [];
  List<PaymentHistoryResponse> paymentList = [];
  bool isLoading = true;
  bool isUpdating = false;

  void init(DebtorResponse debtor) {
    currentDebtor = debtor;
    fetchAllData();
  }

  // ดึงข้อมูลใหม่ทั้งหมด
  Future<void> fetchAllData() async {
    isLoading = true;
    notifyListeners();
    try {
      await Future.wait([
        fetchBillHistory(),
        fetchPaymentHistory(),
      ]);
    } catch (e) {
      print("Error fetching all data: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBillHistory() async {
    final result = await ApiDebtor.getDebtorHistory(currentDebtor.debtorId!);
    if (result != null) {
      List<dynamic> rawHistories = result['histories'] ?? [];
      historyList = rawHistories.map((bill) => DebtorHistoryResponse.fromJson(bill)).toList();
    }
  }

  Future<void> fetchPaymentHistory() async {
    final result = await ApiPayment.getPaymentHistory(currentDebtor.debtorId!);
    if (result != null) {
      paymentList = (result as List)
          .map((item) => PaymentHistoryResponse.fromJson(item))
          .toList();
    }
  }

  Future<bool> updateDebtorData({
    required String name,
    required String phone,
    required String address,
    required double creditLimit,
    File? imageFile,
  }) async {
    isUpdating = true;
    notifyListeners();
    try {
      String? newImageUrl;
      if (imageFile != null) {
        newImageUrl = await ImageUploadService().uploadImage(imageFile);
      }

      Map<String, dynamic> updateData = {
        "name": name,
        "phone": phone,
        "address": address,
        "credit_limit": creditLimit,
      };

      if (newImageUrl != null) updateData["img_debtor"] = newImageUrl;

      final result = await ApiDebtor.updateDebtor(currentDebtor.debtorId!, updateData);

      if (result['success'] == true) {
        // อัปเดตข้อมูลในตัวแปร currentDebtor ทันที
        currentDebtor = result['data'];
        return true;
      }
      return false;
    } catch (e) {
      print("Update Error: $e");
      return false;
    } finally {
      isUpdating = false;
      notifyListeners();
    }
  }
}