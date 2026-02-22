import 'package:flutter/material.dart';
import '../../../model/response/debtor_response.dart';
import '../../../model/request/debtor_history_model.dart';
import '../../../api/api_debtor.dart';

class DebtorDetailController extends ChangeNotifier {
  late DebtorResponse currentDebtor;
  List<DebtorHistoryResponse> historyList = [];
  bool isLoading = true;

  // ฟังก์ชันเริ่มต้น (เรียกตอนเปิดหน้าจอ)
  void init(DebtorResponse debtor) {
    currentDebtor = debtor;
    fetchHistory();
  }

  // ฟังก์ชันดึงประวัติบิล (Logic การเรียก API และจัดการ JSON อยู่ที่นี่หมด)
  Future<void> fetchHistory() async {
    isLoading = true;
    notifyListeners(); // สั่งให้อัปเดตหน้าจอ

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
            remainingAmount: double.parse((bill['remaining_amount'] ?? 0).toString()),
            items: itemsList,
          );
        }).toList();

        historyList = fetchedHistory;
      }
    } catch (e) {
      print("Error fetching history: $e");
    } finally {
      isLoading = false;
      notifyListeners(); // โหลดเสร็จแล้ว สั่งอัปเดตหน้าจออีกรอบ
    }
  }

  // ฟังก์ชันอัปเดตข้อมูลลูกหนี้หลังกดแก้ไข
  void updateDebtorData({required String name, required String phone, required String address, required double creditLimit}) {
    // TODO: เรียก API Update ข้อมูลไปยัง Backend
    // await ApiDebtor.updateDebtor(...);

    // จำลองการอัปเดตค่าในหน้าจอทันที (ถ้า Model ของคุณอนุญาตให้แก้ไขค่าได้)
    // currentDebtor.name = name;
    // currentDebtor.phone = phone;
    // currentDebtor.address = address;
    // currentDebtor.creditLimit = creditLimit;
    
    notifyListeners();
  }
}