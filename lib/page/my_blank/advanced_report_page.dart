import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:eazy_store/page/my_blank/advanced_report_controller.dart';
import 'package:eazy_store/model/response/advanced_report_response.dart';

// ─── Design Tokens ───────────────────────────────────────────────────────────
const _kBlue1 = Color(0xFF0A2A6E);
const _kBlue2 = Color(0xFF1558D6);
const _kBlue3 = Color(0xFF2D7EFF);
const _kBlue4 = Color(0xFF5BA3FF);
const _kBlueSoft = Color(0xFFDCEAFF);
const _kBluePale = Color(0xFFEEF5FF);
const _kGreen = Color(0xFF00C48C);
const _kGreenLight = Color(0xFFE6FFF8);
const _kAmber = Color(0xFFFFB020);
const _kAmberLight = Color(0xFFFFF8E8);
const _kRed = Color(0xFFFF4D4D);
const _kRedLight = Color(0xFFFFF0F0);
const _kInk = Color(0xFF0A1628);
const _kInk2 = Color(0xFF3D5168);
const _kInk3 = Color(0xFF8DA0B3);
const _kBg = Color(0xFFF5F7FA);
const _kSurface = Colors.white;
const _kCardRadius = 20.0;
const _kIconRadius = 14.0;

class AdvancedReportPage extends StatelessWidget {
  AdvancedReportPage({Key? key}) : super(key: key);

  final AdvancedReportController c = Get.put(AdvancedReportController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildHero(context),
          Expanded(
            child: Obx(() {
              if (c.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: _kBlue2,
                    strokeWidth: 3,
                  ),
                );
              }
              final data = c.reportData.value;
              if (data == null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bar_chart_rounded,
                        size: 56,
                        color: _kInk3.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'ไม่สามารถโหลดข้อมูลได้',
                        style: TextStyle(color: _kInk3, fontSize: 15),
                      ),
                    ],
                  ),
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 48),
                child: Column(
                  children: [
                    _buildPeriodNav(context),
                    const SizedBox(height: 24),
                    _buildKpiRow(data.debtSummary),
                    const SizedBox(height: 24),
                    _buildSalesCard(data.salesChart),
                    const SizedBox(height: 24),
                    _buildPaymentCard(data.paymentMethods),
                    const SizedBox(height: 24),
                    _buildTopProductsCard(data.topProducts),
                    const SizedBox(height: 24),
                    _buildAgingCard(data.agingReport),
                    const SizedBox(height: 24),
                    _buildTopDebtorsCard(data.topDebtors),
                    const SizedBox(height: 24),
                    _buildCashFlowCard(data.debtCollection),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── Hero Header (clean white style) ──────────────────────────────────
  Widget _buildHero(BuildContext context) {
    return Container(
      color: _kSurface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: _kInk2, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'รายงานเชิงลึก',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _kInk,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Advanced Report',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _kInk3,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Obx(() => _buildTabBar()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: ['เดือนนี้', 'ปีนี้'].map((view) {
          final isOn = c.selectedView.value == view;
          return Expanded(
            child: GestureDetector(
              onTap: () => c.selectedView.value = view,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: isOn ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: isOn
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  view,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isOn ? _kBlue2 : _kInk3,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Inline Period Nav (inside scroll) ─────────────────────────────────────
  Widget _buildPeriodNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _navArrow(Icons.chevron_left_rounded, () => c.navigatePeriod(-1)),
          Expanded(
            child: GestureDetector(
              onTap: () => c.selectDate(context),
              child: Obx(
                () => Column(
                  children: [
                    Text(
                      c.getPeriodLabel(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _kInk,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 12, color: _kInk3),
                        const SizedBox(width: 4),
                        const Text('แตะเพื่อเลือกช่วงเวลา',
                            style: TextStyle(fontSize: 12, color: _kInk3)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          _navArrow(Icons.chevron_right_rounded, () => c.navigatePeriod(1)),
        ],
      ),
    );
  }

  Widget _navArrow(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: _kBlue2, size: 22),
      ),
    );
  }

  // ─── Base card ──────────────────────────────────────────────────────────────
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader({
    required Widget icon,
    required String title,
    required String sub,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kInk,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(sub, style: const TextStyle(fontSize: 12, color: _kInk3)),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _iconBox(IconData icon, Color bg, Color fg) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(_kIconRadius),
      ),
      child: Icon(icon, color: fg, size: 22),
    );
  }

  Widget _pill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kBluePale, _kBlueSoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _kBlue2,
        ),
      ),
    );
  }

  // ─── KPI Cards ───────────────────────────────────────────────────────────
  Widget _buildKpiRow(DebtSummary data) {
    return Row(
      children: [
        Expanded(
          child: _kpiCard(
            label: 'ยอดหนี้รวม',
            value: '฿${c.formatNumber(data.totalOutstanding)}',
            sub: 'ค้างชำระทั้งหมด',
            icon: Icons.account_balance_wallet_rounded,
            colors: const [Color(0xFFFF6B6B), _kRed],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _kpiCard(
            label: 'เก็บหนี้ได้',
            value: '฿${c.formatNumber(data.collectedThisMonth)}',
            sub: c.selectedView.value,
            icon: Icons.payments_rounded,
            colors: const [Color(0xFF00D4A0), _kGreen],
          ),
        ),
      ],
    );
  }

  Widget _kpiCard({
    required String label,
    required String value,
    required String sub,
    required IconData icon,
    required List<Color> colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -18,
            right: -18,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 26),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.8),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Sales Chart ──────────────────────────────────────────────────────────
  Widget _buildSalesCard(List<SalesChartItem> chartData) {
    if (chartData.isEmpty) return const SizedBox();

    final spots = chartData.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.totalSales);
    }).toList();

    final maxY = chartData.isEmpty
        ? 100.0
        : (chartData.map((e) => e.totalSales).reduce((a, b) => a > b ? a : b)) *
              1.2;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: _iconBox(Icons.trending_up_rounded, _kBluePale, _kBlue2),
            title: 'แนวโน้มยอดขาย',
            sub: 'ยอดขายรายวันตลอดเดือน',
            trailing: Obx(() => _pill(c.getPeriodShortLabel())),
          ),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        int idx = value.toInt();
                        if (idx < 0 || idx >= chartData.length) return const SizedBox();
                        String label = chartData[idx].date;
                        if (c.selectedView.value == 'เดือนนี้') {
                          try {
                            DateTime d = DateTime.parse(label);
                            if (d.day == 1 || d.day == 7 || d.day == 14 || d.day == 21 || d.day == 28 || d.day == DateTime(d.year, d.month + 1, 0).day) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text('${d.day}', style: const TextStyle(color: _kInk3, fontSize: 10, fontWeight: FontWeight.w600)),
                              );
                            }
                          } catch (_) {}
                        } else if (c.selectedView.value == 'ปีนี้') {
                          try {
                            DateTime d = DateTime.parse(label);
                            if (d.day == 15) {
                              const months = ['ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.', 'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(months[d.month - 1], style: const TextStyle(color: _kInk3, fontSize: 10, fontWeight: FontWeight.w600)),
                              );
                            }
                          } catch (_) {}
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                minX: 0,
                maxX: (chartData.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => _kInk,
                    tooltipRoundedRadius: 12,
                    getTooltipItems: (spots) => spots
                        .map(
                          (s) => LineTooltipItem(
                            '฿${c.formatNumber(s.y)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.42,
                    color: _kBlue2,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          _kBlue2.withOpacity(0.22),
                          _kBlue3.withOpacity(0.07),
                          _kBlue3.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Payment Methods Donut ────────────────────────────────────────────────
  Widget _buildPaymentCard(PaymentMethods data) {
    final total = data.paidCash + data.paidTransfer + data.debtAmount;
    if (total == 0) return const SizedBox();

    // Payment item definitions
    final items = [
      (
        label: 'เงินสด',
        icon: Icons.payments_rounded,
        value: data.paidCash,
        colors: [const Color(0xFF00C896), const Color(0xFF00A57A)],
        bg: const Color(0xFFE8FBF5),
      ),
      (
        label: 'โอน / QR',
        icon: Icons.qr_code_scanner_rounded,
        value: data.paidTransfer,
        colors: [const Color(0xFF2D7EFF), const Color(0xFF1558D6)],
        bg: const Color(0xFFEFF5FF),
      ),
      (
        label: 'ค้างชำระ',
        icon: Icons.hourglass_bottom_rounded,
        value: data.debtAmount,
        colors: [const Color(0xFFFFAA00), const Color(0xFFD97706)],
        bg: const Color(0xFFFFF8E8),
      ),
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: _iconBox(
              Icons.donut_large_rounded,
              const Color(0xFFEFF5FF),
              _kBlue2,
            ),
            title: 'ช่องทางการชำระเงิน',
            sub: 'สัดส่วนยอดรับเงินทั้งหมด',
          ),
          const SizedBox(height: 8),

          // ─── Donut Chart + Centre Label ──────────────────────────────────
          Center(
            child: SizedBox(
              width: 190,
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 62,
                      startDegreeOffset: -90,
                      sections: [
                        if (data.paidCash > 0)
                          PieChartSectionData(
                            color: const Color(0xFF00C896),
                            value: data.paidCash,
                            title: '',
                            radius: 32,
                            borderSide: const BorderSide(color: Colors.white, width: 2.5),
                          ),
                        if (data.paidTransfer > 0)
                          PieChartSectionData(
                            color: const Color(0xFF2D7EFF),
                            value: data.paidTransfer,
                            title: '',
                            radius: 32,
                            borderSide: const BorderSide(color: Colors.white, width: 2.5),
                          ),
                        if (data.debtAmount > 0)
                          PieChartSectionData(
                            color: const Color(0xFFFFAA00),
                            value: data.debtAmount,
                            title: '',
                            radius: 32,
                            borderSide: const BorderSide(color: Colors.white, width: 2.5),
                          ),
                      ],
                    ),
                  ),
                  // Centre content
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('ยอดรวม', style: TextStyle(fontSize: 11, color: _kInk3, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(
                        '฿${c.formatCompact(total)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _kInk,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ─── Payment Item Cards ──────────────────────────────────────────
          ...items.map((item) {
            if (item.value <= 0) return const SizedBox();
            final pct = item.value / total;
            final pctStr = (pct * 100).toStringAsFixed(1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: item.bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: item.colors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(item.icon, color: Colors.white, size: 17),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.label, style: TextStyle(fontSize: 12, color: item.colors.last, fontWeight: FontWeight.w600)),
                              Text('฿${c.formatNumber(item.value)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _kInk, letterSpacing: -0.3)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: item.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('$pctStr%', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        children: [
                          Container(height: 6, color: Colors.black.withValues(alpha: 0.06)),
                          FractionallySizedBox(
                            widthFactor: pct.clamp(0.0, 1.0),
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: item.colors, begin: Alignment.centerLeft, end: Alignment.centerRight),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Top Products ─────────────────────────────────────────────────────────
  Widget _buildTopProductsCard(List<TopProductItem> products) {
    if (products.isEmpty) return const SizedBox();
    final maxQty = products[0].totalQty.toDouble();

    final rankIcons = ['🥇', '🥈', '🥉'];
    final barColors = [
      [_kBlue2, _kBlue4],
      [const Color(0xFF1E77E8), const Color(0xFF66AFFF)],
      [const Color(0xFF2D8AF5), const Color(0xFF7DC0FF)],
      [const Color(0xFF4499F9), const Color(0xFF96CCFF)],
      [const Color(0xFF60AAFC), const Color(0xFFADDCFF)],
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: _iconBox(
              Icons.emoji_events_rounded,
              _kAmberLight,
              const Color(0xFFD97706),
            ),
            title: '5 อันดับสินค้าขายดี',
            sub: 'วัดจากจำนวนชิ้นที่ขายได้',
          ),
          ...products.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final pct = item.totalQty / maxQty;
            final colors = barColors[i.clamp(0, 4)];

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      i < 3 ? rankIcons[i] : '${i + 1}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: i < 3 ? 20 : 13,
                        fontWeight: FontWeight.w800,
                        color: _kInk3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _kInk,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Stack(
                          children: [
                            // Track
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F4F8),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                            // Fill
                            FractionallySizedBox(
                              widthFactor: pct,
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: colors,
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 65,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item.totalQty} ชิ้น',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _kInk,
                          ),
                        ),
                        Text(
                          '฿${c.formatNumber(item.totalSales)}',
                          style: const TextStyle(
                              fontSize: 10, color: _kInk3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Aging Report ─────────────────────────────────────────────────────────
  Widget _buildAgingCard(AgingReport data) {
    final total = data.safe + data.warning + data.danger;
    if (total == 0) return const SizedBox();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: _iconBox(
              Icons.timelapse_rounded,
              const Color(0xFFF4F7FA),
              _kInk2,
            ),
            title: 'รายงานอายุหนี้',
            sub: 'Aging Report',
          ),
          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Row(
              children: [
                if (data.safe > 0)
                  Expanded(
                    flex: data.safe.toInt(),
                    child: Container(
                      height: 12,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_kGreen, Color(0xFF00E5A8)],
                        ),
                      ),
                    ),
                  ),
                if (data.warning > 0)
                  Expanded(
                    flex: data.warning.toInt(),
                    child: Container(
                      height: 12,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_kAmber, Color(0xFFFFCC5A)],
                        ),
                      ),
                    ),
                  ),
                if (data.danger > 0)
                  Expanded(
                    flex: data.danger.toInt(),
                    child: Container(
                      height: 12,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_kRed, Color(0xFFFF7070)],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _agingRow('1–15 วัน (ปลอดภัย)', data.safe, _kGreen),
          const SizedBox(height: 9),
          _agingRow('16–30 วัน (ทวงถาม)', data.warning, _kAmber),
          const SizedBox(height: 9),
          _agingRow('> 30 วัน (อันตราย)', data.danger, _kRed),
        ],
      ),
    );
  }

  Widget _agingRow(String label, double value, Color color) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: _kInk2),
          ),
        ),
        Text(
          '฿${c.formatNumber(value)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  // ─── Top Debtors ──────────────────────────────────────────────────────────
  Widget _buildTopDebtorsCard(List<TopDebtorItem> debtors) {
    if (debtors.isEmpty) return const SizedBox();
    final maxDebt = debtors
        .map((d) => d.currentDebt)
        .reduce((a, b) => a > b ? a : b);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: _iconBox(Icons.people_alt_rounded, _kRedLight, _kRed),
            title: '5 อันดับลูกหนี้ค้างสูงสุด',
            sub: 'ยอดค้างชำระปัจจุบัน',
          ),
          ...debtors.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final barPct = item.currentDebt / maxDebt;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF5F5), Color(0xFFFFF0F0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFE0E0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFD9D9), Color(0xFFFFBABA)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _kRed,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kInk,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '฿${c.formatNumber(item.currentDebt)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kRed,
                        ),
                      ),
                      const SizedBox(height: 3),
                      SizedBox(
                        width: 56,
                        height: 4,
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE0E0),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: barPct,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFFFF6B6B), _kRed],
                                  ),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(99),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Cash Flow ────────────────────────────────────────────────────────────
  Widget _buildCashFlowCard(DebtCollection data) {
    final net = data.collectedDebt - data.newDebt;
    final isPositive = net >= 0;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: _iconBox(
              Icons.swap_horiz_rounded,
              const Color(0xFFE8FDFB),
              const Color(0xFF0D9488),
            ),
            title: 'กระแสเงินสดลูกหนี้',
            sub: 'ตามช่วงเวลาที่เลือก',
          ),
          Row(
            children: [
              Expanded(
                child: _cfCard(
                  label: 'บิลค้างเพิ่ม',
                  value: '฿${c.formatNumber(data.newDebt)}',
                  tag: '↑ เพิ่มขึ้น',
                  bgColors: [const Color(0xFFFFF0F0), const Color(0xFFFFE0E0)],
                  border: const Color(0xFFFFD0D0),
                  labelColor: const Color(0xFFC0392B),
                  valueColor: _kRed,
                  tagBg: const Color(0xFFFFD9D9),
                  tagColor: const Color(0xFFC0392B),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _cfCard(
                  label: 'เก็บหนี้คืนได้',
                  value: '฿${c.formatNumber(data.collectedDebt)}',
                  tag: '↑ ดีขึ้น',
                  bgColors: [const Color(0xFFE6FFF8), const Color(0xFFC8FFF0)],
                  border: const Color(0xFFB0F0E0),
                  labelColor: const Color(0xFF0D7A5A),
                  valueColor: _kGreen,
                  tagBg: const Color(0xFFB8F5E4),
                  tagColor: const Color(0xFF0D7A5A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Net row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kBluePale, _kBlueSoft],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ยอดสุทธิ (เก็บได้ vs ค้างเพิ่ม)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _kBlue2,
                  ),
                ),
                Text(
                  '${isPositive ? '+' : ''}฿${c.formatNumber(net.abs())}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isPositive ? _kGreen : _kRed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cfCard({
    required String label,
    required String value,
    required String tag,
    required List<Color> bgColors,
    required Color border,
    required Color labelColor,
    required Color valueColor,
    required Color tagBg,
    required Color tagColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: valueColor,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: tagBg,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: tagColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
