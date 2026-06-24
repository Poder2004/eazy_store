import 'package:eazy_store/page/menu_bar/bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:eazy_store/page/my_blank/advanced_report_page.dart';
import 'sales_account_controller.dart';

// ─── Design Tokens (aligned with AdvancedReportPage) ──────────────────────────
const _kBg = Color(0xFFEDEEF2);
const _kSurface = Colors.white;
const _kSurface2 = Color(0xFFF5F6FA);
const _kBorder = Color(0xFFE8EAF0);
const _kBlue = Color(0xFF4A7EFF);
const _kBlueBg = Color(0xFFEBF3FF);
const _kBlue2 = Color(0xFF185FA5);
const _kGreenDark = Color(0xFF00A86B);
const _kGreenBg = Color(0xFFE8FDF5);
const _kAmber = Color(0xFFFFB340);
const _kRed = Color(0xFFD93F4C);
const _kPurple = Color(0xFF8B5CF6);
const _kPurpleBg = Color(0xFFF3F0FF);
const _kInk = Color(0xFF0D1730);
const _kInk2 = Color(0xFF6B7A99);
const _kInk3 = Color(0xFF9AA4BF);
const _kInk4 = Color(0xFFC0C8DC);
const _kMaxTextScale = 1.25;

class SalesAccountScreen extends StatelessWidget {
  const SalesAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(SalesAccountController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      c.fetchSummaryData();
    });

    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(
        textScaler: mq.textScaler
            .clamp(minScaleFactor: 1.0, maxScaleFactor: _kMaxTextScale),
      ),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: _kBg,
          body: Column(
            children: [
              _buildHeader(c),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: c.fetchSummaryData,
                  color: _kBlue,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                    child: Column(
                      children: [
                        _buildPeriodNav(context, c),
                        const SizedBox(height: 12),
                        Obx(() {
                          if (c.isLoading.value) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 60),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: _kBlue,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            );
                          }
                          return _buildKpiGrid(context, c);
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavBar(
            currentIndex: 1,
            onTap: (index) => c.changeTab(index),
          ),
        ),
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(SalesAccountController c) {
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'ภาพรวมบัญชี',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _kInk,
                            letterSpacing: -.5,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'SALES OVERVIEW',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _kBlue,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.to(() => const AdvancedReportPage()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kBlue, _kBlue2],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bar_chart_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'รายงานเชิงลึก',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Obx(() => _buildToggle(c)),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(SalesAccountController c) {
    const views = ['วันนี้', 'เดือนนี้', 'ปีนี้'];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F8),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: views.map((v) {
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
                    fontSize: 14,
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
  Widget _buildPeriodNav(BuildContext context, SalesAccountController c) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
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

  // ─── KPI 2×2 Grid ────────────────────────────────────────────────────────────
  Widget _buildKpiGrid(BuildContext context, SalesAccountController c) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'ยอดขายรวม',
                amount: '฿${c.formatNumber(c.totalSales.value)}',
                trend: c.salesTrend.value,
                trendLabel: c.getTrendTextLabel(),
                icon: Icons.attach_money_rounded,
                iconBg: _kBlueBg,
                iconFg: _kBlue,
                valueFg: _kInk,
                onTap: c.selectedView.value == 'ปีนี้'
                    ? null
                    : () => _showProductSalesDetail(
                          context,
                          c,
                          'รายละเอียด: ยอดขายรวม',
                          false,
                        ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                title: 'ต้นทุนรวม',
                amount: '฿${c.formatNumber(c.totalCost.value)}',
                trend: c.costTrend.value,
                trendLabel: c.getTrendTextLabel(),
                icon: Icons.shopping_bag_rounded,
                iconBg: const Color(0xFFF4F5FA),
                iconFg: _kInk2,
                valueFg: _kInk,
                isCost: true,
                onTap: c.selectedView.value == 'ปีนี้'
                    ? null
                    : () => _showProductSalesDetail(
                          context,
                          c,
                          'รายละเอียด: ต้นทุนรวม',
                          true,
                        ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'กำไรสุทธิ',
                amount: '฿${c.formatNumber(c.netProfit.value)}',
                trend: c.profitTrend.value,
                trendLabel: c.getTrendTextLabel(),
                icon: Icons.account_balance_wallet_rounded,
                iconBg: _kGreenBg,
                iconFg: _kGreenDark,
                valueFg: _kGreenDark,
                onTap: c.selectedView.value == 'ปีนี้'
                    ? null
                    : () => _showProductSalesDetail(
                          context,
                          c,
                          'รายละเอียด: กำไรสุทธิ',
                          false,
                        ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                title: 'จำนวนรายการ',
                amount: c.formatNumber(c.totalTransactions.value.toDouble()),
                trend: c.transTrend.value,
                trendLabel: c.getTrendTextLabel(),
                icon: Icons.receipt_long_rounded,
                iconBg: _kPurpleBg,
                iconFg: _kPurple,
                valueFg: _kInk,
                onTap: c.selectedView.value == 'ปีนี้'
                    ? null
                    : () => _showTransactionsDetail(context, c),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Bottom Sheet: Transactions ──────────────────────────────────────────────
  void _showTransactionsDetail(
      BuildContext context, SalesAccountController c) {
    c.fetchTransactionsDetail();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(
          textScaler: MediaQuery.of(ctx).textScaler
              .clamp(maxScaleFactor: _kMaxTextScale),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (ctx2, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: _kBg,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                _sheetHeader(
                  'รายการบิลทั้งหมด',
                  ctx2,
                  Icons.receipt_long_rounded,
                  _kPurple,
                ),
                Expanded(
                  child: Obx(() {
                    if (c.isDetailLoading.value) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: _kBlue, strokeWidth: 2.5),
                      );
                    }
                    if (c.transactionsList.isEmpty) {
                      return _emptyState('ไม่มีรายการขายในช่วงเวลานี้');
                    }
                    return ListView.builder(
                      controller: scrollCtrl,
                      padding:
                          const EdgeInsets.fromLTRB(14, 8, 14, 24),
                      itemCount: c.transactionsList.length,
                      itemBuilder: (_, i) {
                        final item = c.transactionsList[i];
                        Color mColor;
                        IconData mIcon;
                        if (item.paymentMethod == 'จ่ายเงินสด') {
                          mColor = _kGreenDark;
                          mIcon = Icons.payments_rounded;
                        } else if (item.paymentMethod == 'โอนจ่าย') {
                          mColor = _kBlue;
                          mIcon = Icons.account_balance_rounded;
                        } else {
                          mColor = _kAmber;
                          mIcon = Icons.pending_actions_rounded;
                        }
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: _kSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _kBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      mColor.withValues(alpha: .1),
                                  borderRadius:
                                      BorderRadius.circular(11),
                                ),
                                child: Icon(mIcon,
                                    color: mColor, size: 19),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'บิล #${item.saleId}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: _kInk,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${item.createdAt} ${item.createdTime ?? ''}',
                                      style: const TextStyle(
                                          fontSize: 12, color: _kInk3),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '฿${c.formatNumber(item.netPrice)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: _kInk,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color:
                                          mColor.withValues(alpha: .1),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.paymentMethod,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: mColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Bottom Sheet: Product Sales ─────────────────────────────────────────────
  void _showProductSalesDetail(
    BuildContext context,
    SalesAccountController c,
    String title,
    bool isCost,
  ) {
    c.fetchProductSalesDetail();

    IconData headerIcon;
    Color headerColor;
    if (title.contains('กำไร')) {
      headerIcon = Icons.account_balance_wallet_rounded;
      headerColor = _kGreenDark;
    } else if (title.contains('ต้นทุน')) {
      headerIcon = Icons.shopping_bag_rounded;
      headerColor = _kAmber;
    } else {
      headerIcon = Icons.inventory_2_rounded;
      headerColor = _kBlue;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(
          textScaler: MediaQuery.of(ctx).textScaler
              .clamp(maxScaleFactor: _kMaxTextScale),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (ctx2, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: _kBg,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                _sheetHeader(title, ctx2, headerIcon, headerColor),
                Expanded(
                  child: Obx(() {
                    if (c.isDetailLoading.value) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: _kBlue, strokeWidth: 2.5),
                      );
                    }
                    if (c.productSalesList.isEmpty) {
                      return _emptyState(
                          'ไม่มีข้อมูลสินค้าในช่วงเวลานี้');
                    }
                    return ListView.builder(
                      controller: scrollCtrl,
                      padding:
                          const EdgeInsets.fromLTRB(14, 8, 14, 24),
                      itemCount: c.productSalesList.length,
                      itemBuilder: (_, i) {
                        final item = c.productSalesList[i];
                        double mainAmt;
                        Color mainColor;
                        if (title.contains('ยอดขาย')) {
                          mainAmt = item.totalSales;
                          mainColor = _kBlue;
                        } else if (title.contains('ต้นทุน')) {
                          mainAmt = item.totalCost;
                          mainColor = _kAmber;
                        } else {
                          mainAmt = item.profit;
                          mainColor = _kGreenDark;
                        }
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: _kSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _kBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  color: _kSurface2,
                                  border:
                                      Border.all(color: _kBorder),
                                  image: item.imgProduct.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(
                                              item.imgProduct),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: item.imgProduct.isEmpty
                                    ? const Icon(
                                        Icons.inventory_2_rounded,
                                        color: _kInk3,
                                        size: 22,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: _kInk,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.shopping_cart_rounded,
                                          size: 13,
                                          color: _kInk4,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'ขายได้ ${item.totalQty} ชิ้น',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: _kInk3),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: mainColor
                                          .withValues(alpha: .1),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '฿${c.formatNumber(mainAmt)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: mainColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    title.contains('กำไร')
                                        ? 'ขาย: ฿${c.formatNumber(item.totalSales)}'
                                        : 'กำไร: ฿${c.formatNumber(item.profit)}',
                                    style: const TextStyle(
                                        fontSize: 11, color: _kInk3),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Sheet helpers ───────────────────────────────────────────────────────────
  Widget _sheetHeader(
    String title,
    BuildContext ctx,
    IconData icon,
    Color iconColor,
  ) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: _kInk4,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _kInk,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _kSurface2,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: _kBorder),
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: _kInk2),
                ),
              ),
            ],
          ),
        ),
        Container(height: 1, color: _kBorder),
      ],
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 56, color: _kInk4),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: _kInk3, fontSize: 15)),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String title;
  final String amount;
  final double trend;
  final String trendLabel;
  final IconData icon;
  final Color iconBg, iconFg, valueFg;
  final bool isCost;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.amount,
    required this.trend,
    required this.trendLabel,
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.valueFg,
    this.isCost = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPos = trend >= 0;
    Color trendColor;
    if (trend == 0) {
      trendColor = _kInk3;
    } else if (isCost) {
      trendColor = isPos ? _kRed : _kGreenDark;
    } else {
      trendColor = isPos ? _kGreenDark : _kRed;
    }

    final trendIcon = trend == 0
        ? Icons.remove
        : (isPos
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded);
    final trendText =
        '${isPos && trend != 0 ? '+' : ''}${trend.toStringAsFixed(1)}%';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconFg, size: 17),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kInk2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: _kInk4,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                amount,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: valueFg,
                  letterSpacing: -.4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: trendColor.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(trendIcon, size: 12, color: trendColor),
                  const SizedBox(width: 3),
                  Text(
                    trendText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: trendColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              trendLabel,
              style: const TextStyle(fontSize: 10, color: _kInk4),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
