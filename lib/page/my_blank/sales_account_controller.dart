// sales_account_controller.dart
import 'package:flutter/material.dart'; // เพิ่ม import นี้
import 'package:eazy_store/api/api_dashboad.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalesAccountController extends GetxController {
  var isLoading = true.obs;
  var selectedView = 'วันนี้'.obs;
  var currentDate = DateTime.now().obs;
  var currentNavIndex = 1.obs;

  // 📊 ข้อมูล
  var totalSales = 0.0.obs;
  var totalCost = 0.0.obs;
  var netProfit = 0.0.obs;
  var totalTransactions = 0.obs;

  // 📈 Trend
  var salesTrend = 0.0.obs;
  var costTrend = 0.0.obs;
  var profitTrend = 0.0.obs;
  var transTrend = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    // ตั้งค่า Locale เป็นไทย
    Intl.defaultLocale = 'th_TH';
    fetchSummaryData();
    ever(selectedView, (_) => fetchSummaryData());
    ever(currentDate, (_) => fetchSummaryData());
  }

  // ฟังก์ชันเลือกวันที่/เดือน/ปี
  Future<void> selectDate(BuildContext context) async {
    if (selectedView.value == 'วันนี้') {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: currentDate.value,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
        locale: const Locale('th', 'TH'),
      );
      if (picked != null) currentDate.value = picked;
    } 
    // ✅ กรณีเลือก "เดือนนี้" - สร้าง Dialog รายชื่อเดือนเอง
    else if (selectedView.value == 'เดือนนี้') {
      _showMonthPicker(context);
    } 
    else {
      // เลือกปี - ใช้มาตรฐานเดิม
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: currentDate.value,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
        initialDatePickerMode: DatePickerMode.year,
        locale: const Locale('th', 'TH'),
      );
      if (picked != null) currentDate.value = DateTime(picked.year, 1, 1);
    }
  }

  // 🗓️ ฟังก์ชันสร้างหน้าเลือกเดือนแบบรายชื่อ (ม.ค. - ธ.ค.)
  void _showMonthPicker(BuildContext context) {
    final List<String> months = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];

    Get.dialog(
      AlertDialog(
        title: Center(
          child: Text(
            'เลือกเดือน (พ.ศ. ${currentDate.value.year + 543})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // แสดง 3 เดือนต่อแถว
              childAspectRatio: 1.5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              bool isSelected = currentDate.value.month == (index + 1);
              return GestureDetector(
                onTap: () {
                  currentDate.value = DateTime(currentDate.value.year, index + 1, 1);
                  Get.back(); // เลือกเสร็จปิด Dialog
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    months[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // แปลงปี ค.ศ. เป็น พ.ศ. และแสดงภาษาไทย
  String getPeriodLabel() {
    DateTime date = currentDate.value;
    if (selectedView.value == 'วันนี้') {
      return DateFormat('d MMM ').format(date) + (date.year + 543).toString();
    } else if (selectedView.value == 'เดือนนี้') {
      return DateFormat('MMMM ').format(date) + (date.year + 543).toString();
    } else {
      return 'ปี ${(date.year + 543)}';
    }
  }

  // --- ส่วน API และคำนวณคงเดิม (ข้ามเพื่อความกระชับ) ---
  // ... (ฟังก์ชัน fetchSummaryData, _getDateRange, _calculateTrend ฯลฯ ของเดิม) ...

  void navigatePeriod(int direction) {
    DateTime now = currentDate.value;
    if (selectedView.value == 'วันนี้') {
      currentDate.value = now.add(Duration(days: direction));
    } else if (selectedView.value == 'เดือนนี้') {
      currentDate.value = DateTime(now.year, now.month + direction, 1);
    } else if (selectedView.value == 'ปีนี้') {
      currentDate.value = DateTime(now.year + direction, 1, 1);
    }
  }

  String getTrendTextLabel() {
    if (selectedView.value == 'วันนี้') return 'เทียบเมื่อวาน';
    if (selectedView.value == 'เดือนนี้') return 'เทียบเดือนก่อน';
    return 'เทียบปีก่อน';
  }

  String formatNumber(double value) {
    return NumberFormat('#,###').format(value);
  }

  Future<void> fetchSummaryData() async {
    // ... โค้ด fetch เดิมของคุณ ...
    isLoading(true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;
      var currentRange = _getDateRange();
      var previousRange = _getPreviousDateRange();

      final results = await Future.wait([
        ApiDashboad.getSalesSummary(
          shopId,
          currentRange['start']!,
          currentRange['end']!,
        ),
        ApiDashboad.getSalesSummary(
          shopId,
          previousRange['start']!,
          previousRange['end']!,
        ),
      ]);

      if (results[0] != null) {
        totalSales.value = results[0]!.sales;
        totalCost.value = results[0]!.cost;
        netProfit.value = results[0]!.profit;
        totalTransactions.value = results[0]!.transactions;
        if (results[1] != null) {
          salesTrend.value = _calculateTrend(
            results[0]!.sales,
            results[1]!.sales,
          );
          costTrend.value = _calculateTrend(results[0]!.cost, results[1]!.cost);
          profitTrend.value = _calculateTrend(
            results[0]!.profit,
            results[1]!.profit,
          );
          transTrend.value = _calculateTrend(
            results[0]!.transactions.toDouble(),
            results[1]!.transactions.toDouble(),
          );
        }
      }
    } catch (e) {
      print(e);
    } finally {
      isLoading(false);
    }
  }

  Map<String, String> _getDateRange() {
    DateTime now = currentDate.value;
    var formatter = DateFormat('yyyy-MM-dd');
    if (selectedView.value == 'วันนี้')
      return {"start": formatter.format(now), "end": formatter.format(now)};
    if (selectedView.value == 'เดือนนี้')
      return {
        "start": formatter.format(DateTime(now.year, now.month, 1)),
        "end": formatter.format(DateTime(now.year, now.month + 1, 0)),
      };
    return {
      "start": formatter.format(DateTime(now.year, 1, 1)),
      "end": formatter.format(DateTime(now.year, 12, 31)),
    };
  }

  Map<String, String> _getPreviousDateRange() {
    DateTime now = currentDate.value;
    var formatter = DateFormat('yyyy-MM-dd');
    if (selectedView.value == 'วันนี้') {
      DateTime prev = now.subtract(const Duration(days: 1));
      return {"start": formatter.format(prev), "end": formatter.format(prev)};
    }
    if (selectedView.value == 'เดือนนี้')
      return {
        "start": formatter.format(DateTime(now.year, now.month - 1, 1)),
        "end": formatter.format(DateTime(now.year, now.month, 0)),
      };
    return {
      "start": formatter.format(DateTime(now.year - 1, 1, 1)),
      "end": formatter.format(DateTime(now.year - 1, 12, 31)),
    };
  }

  double _calculateTrend(double current, double previous) {
    if (previous == 0) return current > 0 ? 100.0 : 0.0;
    return ((current - previous) / previous) * 100;
  }
}
