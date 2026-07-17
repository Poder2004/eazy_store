import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eazy_store/api/api_dashboad.dart';
import 'package:eazy_store/model/response/advanced_report_response.dart';

class AdvancedReportController extends GetxController {
  var isLoading = true.obs;
  // เหลือแค่ 2 ตัวเลือก: เดือนนี้ / ปีนี้
  var selectedView = 'เดือนนี้'.obs;
  var currentDate = DateTime.now().obs;
  var reportData = Rxn<AdvancedReportResponse>();
  var isAgingDetailLoading = false.obs;
  var agingDetail = Rxn<AgingReportDetail>();

  @override
  void onInit() {
    super.onInit();
    Intl.defaultLocale = 'th_TH';
    fetchReportData();
    ever(selectedView, (_) => fetchReportData());
    ever(currentDate, (_) => fetchReportData());
  }

  Future<void> fetchReportData() async {
    isLoading(true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;
      final range = _getDateRange();
      final data = await ApiDashboad.getAdvancedReport(
        shopId,
        range['start']!,
        range['end']!,
      );
      reportData.value = data;
    } catch (e) {
      debugPrint('Error fetching advanced report: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchAgingReportDetail() async {
    isAgingDetailLoading(true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;
      final range = _getDateRange();
      final data = await ApiDashboad.getAgingReportDetail(
        shopId,
        range['end']!,
      );
      agingDetail.value = data;
    } catch (e) {
      debugPrint('Error fetching aging report detail: $e');
    } finally {
      isAgingDetailLoading(false);
    }
  }

  Map<String, String> _getDateRange() {
    final now = currentDate.value;
    final fmt = DateFormat('yyyy-MM-dd');
    if (selectedView.value == 'เดือนนี้') {
      return {
        'start': fmt.format(DateTime(now.year, now.month, 1)),
        'end': fmt.format(DateTime(now.year, now.month + 1, 0)),
      };
    }
    // ปีนี้
    return {
      'start': fmt.format(DateTime(now.year, 1, 1)),
      'end': fmt.format(DateTime(now.year, 12, 31)),
    };
  }

  String formatNumber(double value) => NumberFormat('#,##0.##').format(value);

  String formatCompact(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return formatNumber(value);
  }

  String getPeriodLabel() {
    final date = currentDate.value;
    if (selectedView.value == 'เดือนนี้') {
      return '${DateFormat('MMMM').format(date)} ${date.year + 543}';
    }
    return 'ปี ${date.year + 543}';
  }

  String getPeriodShortLabel() {
    final date = currentDate.value;
    if (selectedView.value == 'เดือนนี้') {
      return DateFormat('MMM').format(date);
    }
    return '${date.year + 543}';
  }

  void navigatePeriod(int direction) {
    final now = currentDate.value;
    if (selectedView.value == 'เดือนนี้') {
      currentDate.value = DateTime(now.year, now.month + direction, 1);
    } else {
      currentDate.value = DateTime(now.year + direction, 1, 1);
    }
  }

  Future<void> selectDate(BuildContext context) async {
    if (selectedView.value == 'เดือนนี้') {
      _showMonthPicker(context);
    } else {
      _showYearPicker(context);
    }
  }

  void _showMonthPicker(BuildContext context) {
    const months = [
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม',
    ];
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
          child: Text(
            'เลือกเดือน  พ.ศ. ${currentDate.value.year + 543}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.6,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: 12,
            itemBuilder: (_, index) {
              final isSelected = currentDate.value.month == index + 1;
              return GestureDetector(
                onTap: () {
                  currentDate.value = DateTime(
                    currentDate.value.year,
                    index + 1,
                    1,
                  );
                  Get.back();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF1558D6), Color(0xFF2D7EFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    months[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF3D5168),
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
            child: const Text(
              'ยกเลิก',
              style: TextStyle(color: Color(0xFF1558D6)),
            ),
          ),
        ],
      ),
    );
  }

  void _showYearPicker(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(12, (i) => currentYear - 5 + i);
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Text(
            'เลือกปี (พ.ศ.)',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.6,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: years.length,
            itemBuilder: (_, index) {
              final year = years[index];
              final isSelected = currentDate.value.year == year;
              return GestureDetector(
                onTap: () {
                  currentDate.value = DateTime(year, 1, 1);
                  Get.back();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF1558D6), Color(0xFF2D7EFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${year + 543}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF3D5168),
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
            child: const Text(
              'ยกเลิก',
              style: TextStyle(color: Color(0xFF1558D6)),
            ),
          ),
        ],
      ),
    );
  }
}
