import 'package:eazy_store/page/menu_bar/bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ✅ สำคัญ: อย่าลืม Import ไฟล์ Controller ที่เพิ่งสร้างใหม่ให้ตรงกับ Path ของคุณ
import 'sales_account_controller.dart';

// --- THEME & CONSTANTS ---
const Color _kBackgroundColor = Color(0xFFF8FAFC);
const Color _kCardColor = Colors.white;
const Color _kPrimaryBlue = Color(0xFF2563EB);
const Color _kSuccessGreen = Color(0xFF16A34A);
const Color _kDangerRed = Color(0xFFDC2626);
const Color _kTextDark = Color(0xFF1E293B);
const Color _kTextMuted = Color(0xFF64748B);

// ----------------------------------------------------------------------
// View (UI)
// ----------------------------------------------------------------------
class SalesAccountScreen extends StatelessWidget {
  const SalesAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // โหลด Controller จากไฟล์ที่เราแยกไว้
    final SalesAccountController controller = Get.put(SalesAccountController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchSummaryData();
    });

    return Scaffold(
      backgroundColor: _kBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.fetchSummaryData,
          color: _kPrimaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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

                // 4. แสดงข้อมูลการ์ด
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
                              isCost: true,
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
        // ✅ แก้ไขตรงนี้: เพิ่ม InkWell เพื่อให้กดเลือกวันที่ได้
        InkWell(
          onTap: () => controller.selectDate(Get.context!),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
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
                const SizedBox(width: 5),
                const Icon(Icons.calendar_month, size: 18, color: _kPrimaryBlue),
              ],
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
    bool isPositive = trend >= 0;
    Color trendColor;
    if (isCost) {
      trendColor = isPositive ? _kDangerRed : _kSuccessGreen;
    } else {
      trendColor = isPositive ? _kSuccessGreen : _kDangerRed;
    }
    if (trend == 0) trendColor = Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: _kCardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _kTextMuted,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _kTextDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                trend == 0
                    ? Icons.remove
                    : (isPositive ? Icons.trending_up : Icons.trending_down),
                color: trendColor,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                '${isPositive && trend != 0 ? '+' : ''}${trend.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: trendColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  trendLabel,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
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
