import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:eazy_store/page/my_blank/advanced_report_controller.dart';
import 'package:eazy_store/model/response/advanced_report_response.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const _kBg = Color(0xFFEDEEF2);
const _kSurface = Colors.white;
const _kSurface2 = Color(0xFFF5F6FA);
const _kBorder = Color(0xFFE8EAF0);

const _kBlue = Color(0xFF4A7EFF);
const _kBlue2 = Color(0xFF185FA5);
const _kBlueBg = Color(0xFFEBF3FF);
const _kGreen = Color(0xFF00C48C);
const _kGreenBg = Color(0xFFE8FDF5);
const _kGreenDark = Color(0xFF00A86B);
const _kAmber = Color(0xFFFFB340);
const _kAmberBg = Color(0xFFFFF8EC);
const _kAmberDark = Color(0xFFBA7517);
const _kRed = Color(0xFFD93F4C);
const _kRedBg = Color(0xFFFFF5F5);
const _kRedLight = Color(0xFFFFECEC);

const _kInk = Color(0xFF0D1730);
const _kInk2 = Color(0xFF6B7A99);
const _kInk3 = Color(0xFF9AA4BF);
const _kInk4 = Color(0xFFC0C8DC);

const _kR10 = 10.0;
const _kR12 = 12.0;
const _kR14 = 14.0;
const _kR16 = 16.0;

// ─── Max text scale factor to prevent overflow with accessibility fonts ────────
const _kMaxTextScale = 1.30;

class AdvancedReportPage extends StatefulWidget {
  const AdvancedReportPage({Key? key}) : super(key: key);
  @override
  State<AdvancedReportPage> createState() => _AdvancedReportPageState();
}

class _AdvancedReportPageState extends State<AdvancedReportPage>
    with TickerProviderStateMixin {
  final AdvancedReportController c = Get.put(AdvancedReportController());

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── Cap textScaler to prevent overflow on elderly large-font mode ──────────
    final mq = MediaQuery.of(context);
    final clampedTextScaler = mq.textScaler.clamp(
      minScaleFactor: 1.0,
      maxScaleFactor: _kMaxTextScale,
    );

    return MediaQuery(
      data: mq.copyWith(textScaler: clampedTextScaler),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: _kBg,
          body: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Obx(() {
                  if (c.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: _kBlue,
                        strokeWidth: 2.5,
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
                            size: 48,
                            color: _kInk3.withValues(alpha: .5),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'ไม่สามารถโหลดข้อมูลได้',
                            style: TextStyle(color: _kInk3, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }
                  return FadeTransition(
                    opacity: _fadeAnim,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 48),
                      child: Column(
                        children: [
                          _buildPeriodNav(context),
                          const SizedBox(height: 10),
                          _buildKpiRow(data.debtSummary),
                          const SizedBox(height: 10),
                          _buildSalesCard(data.salesChart),
                          const SizedBox(height: 10),
                          _buildPaymentCard(data.paymentMethods),
                          const SizedBox(height: 10),
                          _buildTopProductsCard(data.topProducts),
                          const SizedBox(height: 10),
                          _buildAgingCard(data.agingReport),
                          const SizedBox(height: 10),
                          _buildTopDebtorsCard(data.topDebtors),
                          const SizedBox(height: 10),
                          _buildCashFlowCard(data.debtCollection),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: _kSurface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _kSurface2,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: _kBorder),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 14,
                        color: _kInk2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'รายงานเชิงลึก',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _kInk,
                            letterSpacing: -.5,
                            height: 1.1,
                          ),
                        ),
                        
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Obx(() => _buildToggle()),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F8),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: ['เดือนนี้', 'ปีนี้'].map((v) {
          final on = c.selectedView.value == v;
          return Expanded(
            child: GestureDetector(
              onTap: () => c.selectedView.value = v,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: on ? _kSurface : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: on
                      ? [
                          BoxShadow(
                            color: _kBlue.withValues(alpha: .12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  v,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: on ? _kBlue : _kInk3,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Period Nav ──────────────────────────────────────────────────────────────
  Widget _buildPeriodNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(_kR14),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          _navBtn(Icons.chevron_left_rounded, () => c.navigatePeriod(-1)),
          Expanded(
            child: GestureDetector(
              onTap: () => c.selectDate(context),
              child: Obx(
                () => Column(
                  children: [
                    Text(
                      c.getPeriodLabel(),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _kInk,
                        letterSpacing: -.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          size: 10,
                          color: _kBlue.withValues(alpha: .6),
                        ),
                        const SizedBox(width: 3),
                        const Text(
                          'แตะเพื่อเลือกช่วงเวลา',
                          style: TextStyle(fontSize: 12, color: _kInk3),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          _navBtn(Icons.chevron_right_rounded, () => c.navigatePeriod(1)),
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: _kSurface2,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: _kBorder),
        ),
        child: Icon(icon, color: _kBlue, size: 22),
      ),
    );
  }

  // ─── Base Card ───────────────────────────────────────────────────────────────
  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(_kR16),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 12,
            offset: const Offset(0, 2),
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
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kInk,
                    letterSpacing: -.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  sub,
                  style: const TextStyle(fontSize: 12, color: _kInk3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: fg, size: 17),
    );
  }

  // ─── KPI Row ─────────────────────────────────────────────────────────────────
  Widget _buildKpiRow(DebtSummary data) {
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            label: 'ยอดหนี้รวม',
            value: '฿${c.formatNumber(data.totalOutstanding)}',
            icon: Icons.account_balance_wallet_rounded,
            iconBg: _kRedLight,
            iconFg: _kRed,
            valueFg: _kRed,
            trend: '↑ เพิ่มขึ้น',
            trendBg: _kRedLight,
            trendFg: const Color(0xFFC0392B),
            cardBg: _kRedBg,
            border: const Color(0xFFFFCDD2),
            barColor: const Color(0xFFFF6B7A),
            barFraction: .72,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _KpiCard(
            label: 'เก็บหนี้ได้',
            value: '฿${c.formatNumber(data.collectedThisMonth)}',
            icon: Icons.payments_rounded,
            iconBg: const Color(0xFFE0F7EE),
            iconFg: _kGreenDark,
            valueFg: _kGreenDark,
            trend: '↑ ดีขึ้น',
            trendBg: const Color(0xFFE0F7EE),
            trendFg: const Color(0xFF0D7A5A),
            cardBg: const Color(0xFFF0FBF6),
            border: const Color(0xFFB2E8D0),
            barColor: _kGreen,
            barFraction: .85,
          ),
        ),
      ],
    );
  }

  // ─── Sales Chart ─────────────────────────────────────────────────────────────
  Widget _buildSalesCard(List<SalesChartItem> chartData) {
    final isMonthly = c.selectedView.value == 'เดือนนี้';

    // ── Section header (always shown) ────────────────────────────────────────
    final header = _sectionHeader(
      icon: _iconBox(Icons.trending_up_rounded, _kBlueBg, _kBlue),
      title: 'แนวโน้มยอดขาย',
      sub: isMonthly ? 'ยอดขายรายวันตลอดเดือน' : 'ยอดขายรวมแต่ละเดือนตลอดปี',
      trailing: Obx(
        () => Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: _kBlueBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            c.getPeriodShortLabel(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _kBlue2,
            ),
          ),
        ),
      ),
    );

    // ── Aggregate Data for Yearly View ────────────────────────────────────────
    List<SalesChartItem> displayData = chartData;
    if (!isMonthly && chartData.isNotEmpty) {
      Map<int, double> monthlySales = {for (var i = 1; i <= 12; i++) i: 0.0};

      for (var item in chartData) {
        try {
          final d = DateTime.parse(item.date);
          monthlySales[d.month] =
              (monthlySales[d.month] ?? 0) + item.totalSales;
        } catch (_) {}
      }

      displayData = [];
      for (int i = 1; i <= 12; i++) {
        displayData.add(
          SalesChartItem(
            date:
                '2024-${i.toString().padLeft(2, '0')}-01', // Dummy date to hold month
            totalSales: monthlySales[i]!,
          ),
        );
      }
    }

    // ── Empty state ───────────────────────────────────────────────────────────
    final allZero =
        displayData.isEmpty || displayData.every((e) => e.totalSales == 0);

    if (allZero) {
      return _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: _kSurface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart_rounded, size: 32, color: _kInk4),
                  const SizedBox(height: 6),
                  const Text(
                    'ยังไม่มียอดขายในช่วงเวลานี้',
                    style: TextStyle(
                      fontSize: 14,
                      color: _kInk3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'เริ่มบันทึกการขายเพื่อดูกราฟแนวโน้ม',
                    style: TextStyle(fontSize: 12, color: _kInk4),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── Chart data prep ───────────────────────────────────────────────────────
    final spots = displayData
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.totalSales))
        .toList();
    final maxY = displayData.isEmpty
        ? 1000.0
        : (displayData.map((e) => e.totalSales).reduce((a, b) => a > b ? a : b)) *
          1.45;

    // Monthly: 10px/day (dense, ~310px for 31 days)
    // Yearly: 40px/point to prevent cramped labels
    final double pxPerPoint = isMonthly ? 10.0 : 40.0;
    final double chartWidth = displayData.length * pxPerPoint;

    const months = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];

    // ── Use LayoutBuilder OUTSIDE to get the card's real width, THEN scroll ──
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          LayoutBuilder(
            builder: (context, constraints) {
              // constraints.maxWidth = real card inner width (no infinity)
              final double cardW = constraints.maxWidth;
              final double scrollW = chartWidth > cardW ? chartWidth : cardW;
              final bool needsScroll = chartWidth > cardW;

              Widget chart = SizedBox(
                width: scrollW,
                height: 106,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY / 4,
                      getDrawingHorizontalLine: (_) =>
                          FlLine(color: _kBorder, strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: 1,
                          getTitlesWidget: (v, meta) {
                            final idx = v.toInt();
                            if (idx < 0 || idx >= displayData.length)
                              return const SizedBox();
                            final label = displayData[idx].date;
                            try {
                              final d = DateTime.parse(label);
                              if (isMonthly) {
                                // Monthly: show day numbers at key intervals
                                final isLast = idx == chartData.length - 1;
                                if (d.day == 1 ||
                                    d.day == 7 ||
                                    d.day == 14 ||
                                    d.day == 21 ||
                                    d.day == 28 ||
                                    isLast) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '${d.day}',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: _kInk3,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                // Yearly: detect month CHANGE (not d.day==1)
                                // because API only returns days with actual sales
                                final isFirst = idx == 0;
                                final prevMonth = idx > 0
                                    ? DateTime.tryParse(
                                        chartData[idx - 1].date,
                                      )?.month
                                    : null;
                                final monthChanged =
                                    isFirst || prevMonth != d.month;
                                if (monthChanged) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      months[d.month - 1],
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: _kInk3,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }
                              }
                            } catch (_) {}
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
                    maxX: (displayData.length - 1).toDouble(),
                    minY: 0,
                    maxY: maxY,
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => _kInk,
                        tooltipRoundedRadius: 8,
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipItems: (touchSpots) => touchSpots
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
                        curveSmoothness: 0.35,
                        color: _kBlue,
                        barWidth: 1.8,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          checkToShowDot: (spot, _) {
                            final maxVal = displayData
                                .map((e) => e.totalSales)
                                .reduce((a, b) => a > b ? a : b);
                            return spot.y == maxVal ||
                                spot.x == (displayData.length - 1).toDouble();
                          },
                          getDotPainter: (spot, _, __, ___) =>
                              FlDotCirclePainter(
                                radius: 3,
                                color: _kBlue,
                                strokeWidth: 1.5,
                                strokeColor: Colors.white,
                              ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              _kBlue.withValues(alpha: .18),
                              _kBlue.withValues(alpha: 0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  needsScroll
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: chart,
                        )
                      : chart,
                  if (needsScroll)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.swipe_rounded, size: 11, color: _kInk4),
                          const SizedBox(width: 4),
                          const Text(
                            'เลื่อนซ้าย-ขวาเพื่อดูข้อมูลทั้งหมด',
                            style: TextStyle(fontSize: 11, color: _kInk4),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Payment Methods ─────────────────────────────────────────────────────────
  Widget _buildPaymentCard(PaymentMethods data) {
    final total = data.paidCash + data.paidTransfer + data.debtAmount;
    if (total == 0) return const SizedBox();

    final items = [
      _PayItem(
        'เงินสด',
        Icons.payments_rounded,
        data.paidCash,
        _kGreen,
        const Color(0xFFE0F7EE),
      ),
      _PayItem(
        'โอน / QR',
        Icons.qr_code_scanner_rounded,
        data.paidTransfer,
        _kBlue,
        _kBlueBg,
      ),
      _PayItem(
        'ค้างชำระ',
        Icons.hourglass_bottom_rounded,
        data.debtAmount,
        _kAmber,
        _kAmberBg,
      ),
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: _iconBox(Icons.donut_large_rounded, _kBlueBg, _kBlue),
            title: 'ช่องทางการชำระเงิน',
            sub: 'สัดส่วนยอดรับเงินทั้งหมด',
          ),
          Row(
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 25,
                        startDegreeOffset: -90,
                        sections: [
                          if (data.paidCash > 0)
                            PieChartSectionData(
                              color: _kGreen,
                              value: data.paidCash,
                              title: '',
                              radius: 12,
                              borderSide: const BorderSide(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          if (data.paidTransfer > 0)
                            PieChartSectionData(
                              color: _kBlue,
                              value: data.paidTransfer,
                              title: '',
                              radius: 12,
                              borderSide: const BorderSide(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          if (data.debtAmount > 0)
                            PieChartSectionData(
                              color: _kAmber,
                              value: data.debtAmount,
                              title: '',
                              radius: 12,
                              borderSide: const BorderSide(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'ยอดรวม',
                          style: TextStyle(
                            fontSize: 9,
                            color: _kInk3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        FittedBox(
                          child: Text(
                            '฿${c.formatCompact(total)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _kInk,
                              letterSpacing: -.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: items.map((item) {
                    if (item.value <= 0) return const SizedBox();
                    final pct = item.value / total;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: item.color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.label,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _kInk2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${(pct * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _kInk,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (data.debtAmount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: _kAmberBg,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: const Color(0xFFFFE0A0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: _kAmber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7A5000),
                        ),
                        children: [
                          const TextSpan(text: 'ค้างชำระ '),
                          TextSpan(
                            text: '฿${c.formatNumber(data.debtAmount)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(data.debtAmount / total * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF854F0B),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Top Products ─────────────────────────────────────────────────────────────
  Widget _buildTopProductsCard(List<TopProductItem> products) {
    if (products.isEmpty) return const SizedBox();
    final maxQty = products[0].totalQty.toDouble();
    const ranks = ['🥇', '🥈', '🥉'];
    final colors = [_kBlue, _kInk3, _kGreenDark, _kBlue, _kBlue];
    final barGrads = [
      [_kBlue, const Color(0xFFA0C4FF)],
      [const Color(0xFF7B8FA0), const Color(0xFFC0CDD8)],
      [_kGreen, const Color(0xFF80E8CA)],
      [_kBlue, _kBlueBg],
      [_kBlue, _kBlueBg],
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: _iconBox(Icons.emoji_events_rounded, _kAmberBg, _kAmberDark),
            title: '5 อันดับสินค้าขายดี',
            sub: 'วัดจากจำนวนชิ้นที่ขายได้',
          ),
          ...products.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final pct = item.totalQty / maxQty;
            return Padding(
              padding: EdgeInsets.only(
                bottom: i < products.length - 1 ? 10 : 0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Rank badge - fixed width, no overflow
                  SizedBox(
                    width: 24,
                    child: i < 3
                        ? Text(
                            ranks[i],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 17),
                          )
                        : Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _kSurface2,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _kBorder),
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: _kInk3,
                                ),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product name + qty in same row - use Flexible to prevent overflow
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.productName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _kInk,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${item.totalQty} ชิ้น',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: colors[i.clamp(0, 4)],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _AnimatedBar(
                          fraction: pct,
                          colors: barGrads[i.clamp(0, 4)],
                          delay: 300 + i * 80,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '฿${c.formatNumber(item.totalSales)}',
                          style: const TextStyle(fontSize: 12, color: _kInk4),
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

  // ─── Aging Report ─────────────────────────────────────────────────────────────
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
              const Color(0xFFF4F5FA),
              _kInk2,
            ),
            title: 'รายงานอายุหนี้',
            sub: 'Aging Report',
          ),
          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                if (data.safe > 0)
                  Expanded(
                    flex: data.safe.toInt(),
                    child: Container(height: 8, color: _kGreen),
                  ),
                if (data.warning > 0)
                  Expanded(
                    flex: data.warning.toInt(),
                    child: Container(
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      color: _kAmber,
                    ),
                  ),
                if (data.danger > 0)
                  Expanded(
                    flex: data.danger.toInt(),
                    child: Container(height: 8, color: const Color(0xFFFF5A6A)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _agingRow(
            '1–15 วัน',
            'ปลอดภัย',
            data.safe,
            _kGreen,
            const Color(0xFFE8FDF5),
            const Color(0xFF0F6E56),
          ),
          const SizedBox(height: 7),
          _agingRow(
            '16–30 วัน',
            'ทวงถาม',
            data.warning,
            _kAmber,
            _kAmberBg,
            const Color(0xFF854F0B),
          ),
          const SizedBox(height: 7),
          _agingRow(
            '> 30 วัน',
            'อันตราย',
            data.danger,
            const Color(0xFFFF5A6A),
            const Color(0xFFFFF0F0),
            const Color(0xFFA32D2D),
          ),
        ],
      ),
    );
  }

  Widget _agingRow(
    String period,
    String badge,
    double value,
    Color dotColor,
    Color badgeBg,
    Color badgeFg,
  ) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: dotColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(period, style: const TextStyle(fontSize: 13, color: _kInk2)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            badge,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: badgeFg,
            ),
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            '฿${c.formatNumber(value)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: dotColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─── Top Debtors ──────────────────────────────────────────────────────────────
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
            icon: _iconBox(
              Icons.people_alt_rounded,
              const Color(0xFFFFF0F0),
              _kRed,
            ),
            title: '5 อันดับลูกหนี้ค้างสูงสุด',
            sub: 'ยอดค้างชำระปัจจุบัน',
          ),
          ...debtors.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final barPct = item.currentDebt / maxDebt;
            return Padding(
              padding: EdgeInsets.only(bottom: i < debtors.length - 1 ? 6 : 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _kRedBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFE0E0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: _kRedLight,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _kRed,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _kInk,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          _AnimatedBar(
                            fraction: barPct,
                            colors: [
                              const Color(0xFFFF6B7A),
                              const Color(0xFFFF9EAA),
                            ],
                            delay: 400 + i * 70,
                            height: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // FittedBox prevents debt amount from overflowing
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '฿${c.formatNumber(item.currentDebt)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kRed,
                        ),
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

  // ─── Cash Flow ────────────────────────────────────────────────────────────────
  Widget _buildCashFlowCard(DebtCollection data) {
    final net = data.collectedDebt - data.newDebt;
    final isPos = net >= 0;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: _iconBox(
              Icons.swap_horiz_rounded,
              const Color(0xFFE8FDF9),
              const Color(0xFF0F6E56),
            ),
            title: 'กระแสเงินสดลูกหนี้',
            sub: 'ตามช่วงเวลาที่เลือก',
          ),
          Row(
            children: [
              Expanded(
                child: _cfTile(
                  label: '↑ บิลค้างเพิ่ม',
                  value: '฿${c.formatNumber(data.newDebt)}',
                  labelColor: const Color(0xFFC0392B),
                  valueColor: _kRed,
                  bg: _kRedBg,
                  border: const Color(0xFFFFCDD2),
                  barColor: const Color(0xFFFF6B7A),
                  barFraction:
                      data.newDebt / (data.newDebt + data.collectedDebt + .001),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _cfTile(
                  label: '↓ เก็บหนี้คืนได้',
                  value: '฿${c.formatNumber(data.collectedDebt)}',
                  labelColor: const Color(0xFF0D7A5A),
                  valueColor: _kGreenDark,
                  bg: const Color(0xFFF0FBF6),
                  border: const Color(0xFFB2E8D0),
                  barColor: _kGreen,
                  barFraction: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ── Net summary row — fixed overflow with Flexible ────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isPos ? const Color(0xFFF0FBF6) : _kRedBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isPos
                    ? const Color(0xFFB2E8D0)
                    : const Color(0xFFFFCDD2),
              ),
            ),
            child: Row(
              children: [
                const Flexible(
                  child: Text(
                    'ยอดสุทธิ (เก็บได้ vs ค้างเพิ่ม)',
                    style: TextStyle(
                      fontSize: 13,
                      color: _kInk2,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${isPos ? '+' : ''}฿${c.formatNumber(net.abs())}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isPos ? _kGreenDark : _kRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cfTile({
    required String label,
    required String value,
    required Color labelColor,
    required Color valueColor,
    required Color bg,
    required Color border,
    required Color barColor,
    required double barFraction,
  }) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          // FittedBox prevents large amount from overflowing tile
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: valueColor,
                letterSpacing: -.3,
              ),
            ),
          ),
          const SizedBox(height: 6),
          _AnimatedBar(
            fraction: barFraction,
            colors: [barColor, barColor.withValues(alpha: .2)],
            delay: 400,
            height: 3,
          ),
        ],
      ),
    );
  }
}

// ─── Animated Bar ─────────────────────────────────────────────────────────────
class _AnimatedBar extends StatefulWidget {
  final double fraction;
  final List<Color> colors;
  final int delay;
  final double height;
  const _AnimatedBar({
    required this.fraction,
    required this.colors,
    this.delay = 0,
    this.height = 5,
  });
  @override
  State<_AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<_AnimatedBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        return AnimatedBuilder(
          animation: _anim,
          builder: (_, __) {
            return Stack(
              children: [
                Container(
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F8),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Container(
                  height: widget.height,
                  width:
                      constraints.maxWidth *
                      widget.fraction.clamp(0.0, 1.0) *
                      _anim.value,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: widget.colors),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ─── KPI Card ─────────────────────────────────────────────────────────────────
class _KpiCard extends StatefulWidget {
  final String label, value, trend;
  final IconData icon;
  final Color iconBg,
      iconFg,
      valueFg,
      trendBg,
      trendFg,
      cardBg,
      border,
      barColor;
  final double barFraction;
  const _KpiCard({
    required this.label,
    required this.value,
    required this.trend,
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.valueFg,
    required this.trendBg,
    required this.trendFg,
    required this.cardBg,
    required this.border,
    required this.barColor,
    required this.barFraction,
  });
  @override
  State<_KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<_KpiCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: widget.cardBg,
        borderRadius: BorderRadius.circular(_kR16),
        border: Border.all(color: widget.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: widget.iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(widget.icon, color: widget.iconFg, size: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.trendBg,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  widget.trend,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: widget.trendFg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 12,
              color: _kInk3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          // FittedBox prevents value overflow on small cards
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              widget.value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: widget.valueFg,
                letterSpacing: -.4,
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) {
              return LayoutBuilder(
                builder: (_, c) {
                  return Stack(
                    children: [
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .5),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      Container(
                        height: 3,
                        width: c.maxWidth * widget.barFraction * _anim.value,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.barColor,
                              widget.barColor.withValues(alpha: .2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PayItem {
  final String label;
  final IconData icon;
  final double value;
  final Color color;
  final Color bg;
  const _PayItem(this.label, this.icon, this.value, this.color, this.bg);
}
