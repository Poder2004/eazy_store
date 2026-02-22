import 'package:eazy_store/api/api_dashboad.dart'; // ตรวจสอบ path ของคุณ
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalesAccountController extends GetxController {
  var isLoading = true.obs;
  var selectedView = 'วันนี้'.obs;
  var currentDate = DateTime.now().obs;
  var currentNavIndex = 1.obs;

  // 📊 ข้อมูลปัจจุบัน
  var totalSales = 0.0.obs;
  var totalCost = 0.0.obs;
  var netProfit = 0.0.obs;
  var totalTransactions = 0.obs;

  // 📈 ข้อมูลเปรียบเทียบ (Trend %)
  var salesTrend = 0.0.obs;
  var costTrend = 0.0.obs;
  var profitTrend = 0.0.obs;
  var transTrend = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSummaryData();
    ever(selectedView, (_) => fetchSummaryData());
    ever(currentDate, (_) => fetchSummaryData());
  }

  // คำนวณช่วงเวลาปัจจุบัน
  Map<String, String> _getDateRange() {
    DateTime now = currentDate.value;
    String start = "";
    String end = "";
    var formatter = DateFormat('yyyy-MM-dd');

    if (selectedView.value == 'วันนี้') {
      start = formatter.format(now);
      end = formatter.format(now);
    } else if (selectedView.value == 'เดือนนี้') {
      start = formatter.format(DateTime(now.year, now.month, 1));
      end = formatter.format(DateTime(now.year, now.month + 1, 0));
    } else if (selectedView.value == 'ปีนี้') {
      start = formatter.format(DateTime(now.year, 1, 1));
      end = formatter.format(DateTime(now.year, 12, 31));
    }
    return {"start": start, "end": end};
  }

  // คำนวณช่วงเวลาในอดีต (เพื่อเอามาเทียบ %)
  Map<String, String> _getPreviousDateRange() {
    DateTime now = currentDate.value;
    String start = "";
    String end = "";
    var formatter = DateFormat('yyyy-MM-dd');

    if (selectedView.value == 'วันนี้') {
      DateTime yesterday = now.subtract(const Duration(days: 1));
      start = formatter.format(yesterday);
      end = formatter.format(yesterday);
    } else if (selectedView.value == 'เดือนนี้') {
      start = formatter.format(DateTime(now.year, now.month - 1, 1));
      end = formatter.format(DateTime(now.year, now.month, 0));
    } else if (selectedView.value == 'ปีนี้') {
      start = formatter.format(DateTime(now.year - 1, 1, 1));
      end = formatter.format(DateTime(now.year - 1, 12, 31));
    }
    return {"start": start, "end": end};
  }

  // สูตรคำนวณ % การเติบโต
  double _calculateTrend(double current, double previous) {
    if (previous == 0) return current > 0 ? 100.0 : 0.0;
    return ((current - previous) / previous) * 100;
  }

  // ดึงข้อมูลหลัก + ดึงอดีตมาคำนวณ Trend
  Future<void> fetchSummaryData() async {
    isLoading(true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;

      var currentRange = _getDateRange();
      var previousRange = _getPreviousDateRange();

      // ดึง 2 รอบพร้อมกัน (ปัจจุบัน และ อดีต)
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

      final currentSummary = results[0];
      final previousSummary = results[1];

      if (currentSummary != null) {
        totalSales.value = currentSummary.sales;
        totalCost.value = currentSummary.cost;
        netProfit.value = currentSummary.profit;
        totalTransactions.value = currentSummary.transactions;

        // คำนวณ Trend % ถ้ามีข้อมูลอดีต
        if (previousSummary != null) {
          salesTrend.value = _calculateTrend(
            currentSummary.sales,
            previousSummary.sales,
          );
          costTrend.value = _calculateTrend(
            currentSummary.cost,
            previousSummary.cost,
          );
          profitTrend.value = _calculateTrend(
            currentSummary.profit,
            previousSummary.profit,
          );
          transTrend.value = _calculateTrend(
            currentSummary.transactions.toDouble(),
            previousSummary.transactions.toDouble(),
          );
        } else {
          salesTrend.value = 0;
          costTrend.value = 0;
          profitTrend.value = 0;
          transTrend.value = 0;
        }
      } else {
        _resetData();
      }
    } catch (e) {
      print("Fetch summary error: $e");
      _resetData();
    } finally {
      isLoading(false);
    }
  }

  void _resetData() {
    totalSales.value = 0.0;
    totalCost.value = 0.0;
    netProfit.value = 0.0;
    totalTransactions.value = 0;
    salesTrend.value = 0;
    costTrend.value = 0;
    profitTrend.value = 0;
    transTrend.value = 0;
  }

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

  String getPeriodLabel() {
    DateTime now = currentDate.value;
    if (selectedView.value == 'วันนี้') {
      return DateFormat('dd MMM yyyy').format(now);
    } else if (selectedView.value == 'เดือนนี้') {
      return DateFormat('MMMM yyyy').format(now);
    } else {
      return 'ปี ${now.year}';
    }
  }

  String getTrendTextLabel() {
    if (selectedView.value == 'วันนี้') return 'เทียบเมื่อวาน';
    if (selectedView.value == 'เดือนนี้') return 'เทียบเดือนก่อน';
    return 'เทียบปีก่อน';
  }

  String formatNumber(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
