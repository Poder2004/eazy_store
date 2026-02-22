import 'package:eazy_store/api/api_dashboad.dart';
import 'package:eazy_store/api/api_sale.dart';
import 'package:eazy_store/menu_bar/bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- THEME & CONSTANTS ---
const Color _kBackgroundColor = Color(0xFFF8FAFC);
const Color _kCardColor = Colors.white;
const Color _kPrimaryBlue = Color(0xFF2563EB);
const Color _kSuccessGreen = Color(0xFF16A34A);
const Color _kDangerRed = Color(0xFFDC2626);
const Color _kTextDark = Color(0xFF1E293B);
const Color _kTextMuted = Color(0xFF64748B);

// ----------------------------------------------------------------------
// 1. Controller
// ----------------------------------------------------------------------
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

// ----------------------------------------------------------------------
// 2. View (UI)
// ----------------------------------------------------------------------
class SalesAccountScreen extends StatelessWidget {
  const SalesAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SalesAccountController controller = Get.put(SalesAccountController());

    // 🔥 ระบบ Real-time: บังคับโหลดข้อมูลใหม่ทุกครั้งที่เปิดหน้านี้ขึ้นมา
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchSummaryData();
    });

    return Scaffold(
      backgroundColor: _kBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.fetchSummaryData, // ดึงจอลงมาเพื่อรีเฟรชได้ด้วย
          color: _kPrimaryBlue,
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(), // บังคับให้ดึงรีเฟรชได้ตลอด
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ภาพรวมบัญชี',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _kTextDark,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'ตรวจสอบยอดขายแบบเรียลไทม์',
                          style: TextStyle(fontSize: 14, color: _kTextMuted),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Get.snackbar(
                        "รอก่อนนะ",
                        "ระบบรายงานแบบละเอียดกำลังพัฒนา",
                        colorText: Colors.white,
                        backgroundColor: _kTextDark,
                      ),
                      child: const Text(
                        'ดูรายงานทั้งหมด',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _kPrimaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // 2. Segmented Control
                _buildModernSegmentedControl(controller),
                const SizedBox(height: 15),

                // 3. Date Navigator (< วันที่ >)
                _buildDateNavigator(controller),
                const SizedBox(height: 20),

                // 4. แสดงข้อมูล (ใช้ Obx ครอบให้เปลี่ยนอัตโนมัติ)
                Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(color: _kPrimaryBlue),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'ยอดขายรวม',
                              amount:
                                  '฿${controller.formatNumber(controller.totalSales.value)}',
                              trend: controller.salesTrend.value,
                              trendLabel: controller.getTrendTextLabel(),
                              icon: Icons.attach_money,
                              iconColor: _kPrimaryBlue,
                              iconBgColor: Colors.blue.shade50,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildStatCard(
                              title: 'ต้นทุนรวม',
                              amount:
                                  '฿${controller.formatNumber(controller.totalCost.value)}',
                              trend: controller.costTrend.value,
                              trendLabel: controller.getTrendTextLabel(),
                              icon: Icons.shopping_bag_outlined,
                              iconColor: Colors.grey.shade700,
                              iconBgColor: Colors.grey.shade200,
                              isCost: true, // ต้นทุนใช้ Logic สีต่างออกไป
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'กำไรสุทธิ',
                              amount:
                                  '฿${controller.formatNumber(controller.netProfit.value)}',
                              trend: controller.profitTrend.value,
                              trendLabel: controller.getTrendTextLabel(),
                              icon: Icons.account_balance_wallet,
                              iconColor: _kSuccessGreen,
                              iconBgColor: Colors.green.shade50,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildStatCard(
                              title: 'จำนวนรายการ',
                              amount: controller.formatNumber(
                                controller.totalTransactions.value.toDouble(),
                              ),
                              trend: controller.transTrend.value,
                              trendLabel: controller.getTrendTextLabel(),
                              icon: Icons.receipt_long,
                              iconColor: Colors.purple.shade600,
                              iconBgColor: Colors.purple.shade50,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Obx(
        () => BottomNavBar(
          currentIndex: controller.currentNavIndex.value,
          onTap: (index) => controller.currentNavIndex.value = index,
        ),
      ),
    );
  }

  Widget _buildModernSegmentedControl(SalesAccountController controller) {
    final views = ['วันนี้', 'เดือนนี้', 'ปีนี้'];
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: views.map((view) {
            final isSelected = controller.selectedView.value == view;
            return Expanded(
              child: GestureDetector(
                onTap: () => controller.selectedView.value = view,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? _kCardColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    view,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected ? _kTextDark : _kTextMuted,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDateNavigator(SalesAccountController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: _kTextMuted),
          onPressed: () => controller.navigatePeriod(-1),
        ),
        Obx(
          () => Text(
            controller.getPeriodLabel(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _kTextDark,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: _kTextMuted),
          onPressed: () => controller.navigatePeriod(1),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String amount,
    required double trend,
    required String trendLabel,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    bool isCost = false,
  }) {
    // 🎨 Logic วิเคราะห์สีของ Trend
    // ยอดขาย/กำไรขึ้น = สีเขียว, ลง = สีแดง
    // ต้นทุนขึ้น = สีแดง(ไม่ดี), ลง = สีเขียว(ดี)
    bool isPositive = trend >= 0;
    Color trendColor;
    if (isCost) {
      trendColor = isPositive ? _kDangerRed : _kSuccessGreen;
    } else {
      trendColor = isPositive ? _kSuccessGreen : _kDangerRed;
    }
    if (trend == 0) trendColor = Colors.grey;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // จัดให้ข้อความชิดซ้าย
        children: [
          // Row 1: ไอคอน + ชื่อหัวข้อ
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _kTextMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Row 2: ตัวเลขหลัก
          Text(
            amount,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _kTextDark,
            ),
          ),
          const SizedBox(height: 10),

          // Row 3: Trend % เปรียบเทียบ
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                trend == 0
                    ? Icons.remove
                    : (isPositive ? Icons.trending_up : Icons.trending_down),
                color: trendColor,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${isPositive && trend != 0 ? '+' : ''}${trend.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: trendColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  trendLabel,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
