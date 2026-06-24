import 'package:eazy_store/page/menu_bar/bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:eazy_store/page/my_blank/advanced_report_page.dart';
import 'sales_account_controller.dart';
import 'package:eazy_store/model/response/dashboard_detail_response.dart';

// ─── Light Theme Tokens ───────────────────────────────────────────────────────
const _kBg       = Color(0xFFEDEEF2);
const _kCard     = Colors.white;
const _kCard2    = Color(0xFFF5F6FA);
const _kBorder   = Color(0xFFE8EAF0);

const _kGreen    = Color(0xFF00A86B);
const _kGreenDim = Color(0xFFE8FDF5);
const _kBlue     = Color(0xFF4A7EFF);
const _kBlueDim  = Color(0xFFEBF3FF);
const _kOrange   = Color(0xFFFFB340);
const _kOrangeDim= Color(0xFFFFF8EC);
const _kRed      = Color(0xFFD93F4C);
const _kPurple   = Color(0xFF8B5CF6);
const _kPurpleDim= Color(0xFFF3F0FF);

const _kInk      = Color(0xFF0D1730);
const _kSub      = Color(0xFF6B7A99);
const _kMuted    = Color(0xFF9AA4BF);

const _kMaxTextScale = 1.25;

class SalesAccountScreen extends StatelessWidget {
  const SalesAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(SalesAccountController());
    WidgetsBinding.instance.addPostFrameCallback((_) => c.fetchSummaryData());

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
                  backgroundColor: _kCard,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    child: Column(
                      children: [
                        _buildPeriodNav(context, c),
                        const SizedBox(height: 14),
                        Obx(() {
                          if (c.isLoading.value) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 70),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: _kBlue,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            );
                          }
                          return _buildKpiLayout(context, c);
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
      color: _kCard,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                            letterSpacing: -.4,
                            height: 1.1,
                          ),
                        ),
                       
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.to(() => const AdvancedReportPage()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kBlue, Color(0xFF185FA5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bar_chart_rounded,
                              size: 14, color: Colors.white),
                          const SizedBox(width: 5),
                          const Text(
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
        color: _kBg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _kBorder),
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
                  color: on ? Colors.white : Colors.transparent,
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
                    color: on ? _kBlue : _kMuted,
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
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
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
                        fontSize: 16,
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
                        Icon(Icons.touch_app_rounded,
                            size: 10,
                            color: _kBlue.withValues(alpha: .6)),
                        const SizedBox(width: 3),
                        const Text(
                          'แตะเพื่อเลือกช่วงเวลา',
                          style: TextStyle(fontSize: 11, color: _kSub),
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
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _kCard2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder),
        ),
        child: Icon(icon, color: _kBlue, size: 22),
      ),
    );
  }

  // ─── KPI Layout ──────────────────────────────────────────────────────────────
  Widget _buildKpiLayout(BuildContext context, SalesAccountController c) {
    // ปีนี้ → ไม่มีข้อมูล detail จาก API ไม่ให้กดดูรายละเอียด
    final canDrill = c.selectedView.value != 'ปีนี้';
    final trendLabel = c.getTrendTextLabel();
    return Column(
      children: [
        // ─── Hero: กำไรสุทธิ ───────────────────────────────────────────────
        _HeroCard(
          label: 'กำไรสุทธิ',
          amount: '฿${c.formatNumber(c.netProfit.value)}',
          trend: c.profitTrend.value,
          trendLabel: trendLabel,
          iconData: Icons.account_balance_wallet_rounded,
          iconBg: _kGreenDim,
          iconFg: _kGreen,
          onTap: canDrill
              ? () => _showAllProductStats(context, c)
              : null,
        ),
        const SizedBox(height: 12),
        // ─── Row: ยอดขายรวม + ต้นทุนรวม ──────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _CompactCard(
                label: 'ยอดขายรวม',
                amount: '฿${c.formatNumber(c.totalSales.value)}',
                trend: c.salesTrend.value,
                iconData: Icons.attach_money_rounded,
                iconBg: _kBlueDim,
                iconFg: _kBlue,
                onTap: canDrill
                    ? () => _showAllProductStats(context, c)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CompactCard(
                label: 'ต้นทุนรวม',
                amount: '฿${c.formatNumber(c.totalCost.value)}',
                trend: c.costTrend.value,
                iconData: Icons.shopping_bag_rounded,
                iconBg: _kOrangeDim,
                iconFg: _kOrange,
                isCost: true,
                onTap: canDrill
                    ? () => _showAllProductStats(context, c)
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // ─── Full-width: จำนวนรายการ ──────────────────────────────────────
        _TransactionCard(
          count: c.formatNumber(c.totalTransactions.value.toDouble()),
          trend: c.transTrend.value,
          trendLabel: trendLabel,
          selectedView: c.selectedView.value,
          onTap: canDrill ? () => _showTransactionsDetail(context, c) : null,
        ),
      ],
    );
  }

  // ─── Bottom Sheet: รายการบิล ─────────────────────────────────────────────────
  void _showTransactionsDetail(
      BuildContext context, SalesAccountController c) {
    c.fetchTransactionsDetail();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(
        title: 'รายการบิลทั้งหมด',
        icon: Icons.receipt_long_rounded,
        iconColor: _kPurple,
        contentBuilder: (scrollCtrl) => Obx(() {
          if (c.isDetailLoading.value) {
            return const Center(
                child: Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: CircularProgressIndicator(
                  color: _kBlue, strokeWidth: 2.5),
            ));
          }
          if (c.transactionsList.isEmpty) {
            return _emptyState('ไม่มีรายการขายในช่วงเวลานี้');
          }
          return ListView.builder(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            itemCount: c.transactionsList.length,
            itemBuilder: (_, i) {
              final item = c.transactionsList[i];
              Color mColor;
              IconData mIcon;
              if (item.paymentMethod == 'จ่ายเงินสด') {
                mColor = _kGreen;
                mIcon = Icons.payments_rounded;
              } else if (item.paymentMethod == 'โอนจ่าย') {
                mColor = _kBlue;
                mIcon = Icons.account_balance_rounded;
              } else {
                mColor = _kOrange;
                mIcon = Icons.pending_actions_rounded;
              }
              return GestureDetector(
                onTap: () => _showSaleItemsSheet(context, c, item),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kCard2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: mColor.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(mIcon, color: mColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                              _formatThaiDate(item.createdAt, item.createdTime),
                              style: const TextStyle(
                                  fontSize: 12, color: _kSub),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
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
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: mColor.withValues(alpha: .15),
                                  borderRadius: BorderRadius.circular(6),
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
                              const SizedBox(width: 6),
                              const Icon(Icons.chevron_right_rounded,
                                  size: 16, color: _kMuted),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  // ─── Bottom Sheet: รายการสินค้าในบิล ────────────────────────────────────────
  void _showSaleItemsSheet(
    BuildContext context,
    SalesAccountController c,
    TransactionDetailModel bill,
  ) {
    c.fetchSaleItems(bill.saleId);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(
        title: 'บิล #${bill.saleId}',
        icon: Icons.receipt_long_rounded,
        iconColor: _kPurple,
        contentBuilder: (scrollCtrl) => Obx(() {
          if (c.isSaleItemsLoading.value) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: CircularProgressIndicator(
                    color: _kBlue, strokeWidth: 2.5),
              ),
            );
          }
          final detail = c.currentSaleDetail.value;
          if (detail == null) {
            return _emptyState('ไม่สามารถโหลดข้อมูลบิลได้');
          }
          return ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            children: [
              // ─── Bill summary header ─────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _kPurple.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _kPurple.withValues(alpha: .2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date + payment method badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatThaiDate(
                                detail.createdAt, detail.createdTime),
                            style: const TextStyle(
                                fontSize: 12, color: _kSub),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _kPurple.withValues(alpha: .15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            detail.paymentMethod,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _kPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 3 financial columns
                    Row(
                      children: [
                        Expanded(
                          child: _BillSummaryCol(
                            label: 'ยอดรวม',
                            value: '฿${c.formatNumber(detail.netPrice)}',
                            valueColor: _kInk,
                            isLarge: true,
                          ),
                        ),
                        Container(width: 1, height: 36, color: _kPurple.withValues(alpha: .2)),
                        Expanded(
                          child: _BillSummaryCol(
                            label: 'รับเงิน',
                            value: '฿${c.formatNumber(detail.pay)}',
                            valueColor: _kBlue,
                          ),
                        ),
                        Container(width: 1, height: 36, color: _kPurple.withValues(alpha: .2)),
                        Expanded(
                          child: _BillSummaryCol(
                            label: 'ทอนเงิน',
                            value: detail.change > 0
                                ? '฿${c.formatNumber(detail.change)}'
                                : '-',
                            valueColor: _kGreen,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // ─── Item list ───────────────────────────────────────────
              ...detail.items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return Container(
                  margin: EdgeInsets.only(
                      bottom: idx < detail.items.length - 1 ? 8 : 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _kCard2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: _kCard,
                          border: Border.all(color: _kBorder),
                          image: item.imgProduct.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(item.imgProduct),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: item.imgProduct.isEmpty
                            ? const Icon(Icons.inventory_2_rounded,
                                color: _kMuted, size: 20)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: _kInk,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '฿${c.formatNumber(item.unitPrice)} × ${item.qty} ชิ้น',
                              style: const TextStyle(
                                  fontSize: 12, color: _kSub),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '฿${c.formatNumber(item.subtotal)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: _kInk,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        }),
      ),
    );
  }

  // ─── Bottom Sheet: สรุปยอดขายแยกรายสินค้า (ยอดขาย + ต้นทุน + กำไร) ─────────
  void _showAllProductStats(BuildContext context, SalesAccountController c) {
    c.fetchProductSalesDetail();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(
        title: 'ยอดขายแยกรายสินค้า',
        icon: Icons.inventory_2_rounded,
        iconColor: _kBlue,
        contentBuilder: (scrollCtrl) => Obx(() {
          if (c.isDetailLoading.value) {
            return const Center(
                child: Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: CircularProgressIndicator(
                  color: _kBlue, strokeWidth: 2.5),
            ));
          }
          if (c.productSalesList.isEmpty) {
            return _emptyState('ไม่มีข้อมูลสินค้าในช่วงเวลานี้');
          }
          return ListView.builder(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            itemCount: c.productSalesList.length,
            itemBuilder: (_, i) {
              final item = c.productSalesList[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _kCard2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: _kCard,
                        border: Border.all(color: _kBorder),
                        image: item.imgProduct.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(item.imgProduct),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: item.imgProduct.isEmpty
                          ? const Icon(Icons.inventory_2_rounded,
                              color: _kMuted, size: 22)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product name + qty
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
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.shopping_cart_rounded,
                                  size: 13, color: _kMuted),
                              const SizedBox(width: 4),
                              Text(
                                'ขายได้ ${item.totalQty} ชิ้น',
                                style: const TextStyle(
                                    fontSize: 12, color: _kSub),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // 3 metrics row
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 10),
                            decoration: BoxDecoration(
                              color: _kCard,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _kBorder),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _MetricCol(
                                    label: 'ยอดขาย',
                                    value:
                                        '฿${c.formatNumber(item.totalSales)}',
                                    color: _kBlue,
                                  ),
                                ),
                                Container(
                                    width: 1,
                                    height: 28,
                                    color: _kBorder),
                                Expanded(
                                  child: _MetricCol(
                                    label: 'ต้นทุน',
                                    value:
                                        '฿${c.formatNumber(item.totalCost)}',
                                    color: _kOrange,
                                  ),
                                ),
                                Container(
                                    width: 1,
                                    height: 28,
                                    color: _kBorder),
                                Expanded(
                                  child: _MetricCol(
                                    label: 'กำไร',
                                    value:
                                        '฿${c.formatNumber(item.profit)}',
                                    color: _kGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }

  // ─── Thai date helper ────────────────────────────────────────────────────────
  static String _formatThaiDate(String isoDate, String? time) {
    const months = [
      '', 'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    try {
      final d = DateTime.parse(isoDate);
      final t = (time != null && time.length >= 5)
          ? ' ${time.substring(0, 5)} น.'
          : '';
      return '${d.day} ${months[d.month]} ${d.year + 543}$t';
    } catch (_) {
      return '$isoDate ${time ?? ''}';
    }
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 56, color: _kMuted),
            const SizedBox(height: 12),
            Text(msg,
                style: const TextStyle(color: _kSub, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

// ─── Metric Column (used in product stats sheet) ──────────────────────────────
class _MetricCol extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricCol({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: _kMuted),
        ),
      ],
    );
  }
}

// ─── Bill Summary Column (used in bill detail header) ─────────────────────────
class _BillSummaryCol extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool isLarge;

  const _BillSummaryCol({
    required this.label,
    required this.value,
    required this.valueColor,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: _kMuted),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: isLarge ? 18 : 15,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Detail Sheet ─────────────────────────────────────────────────────────────
class _DetailSheet extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget Function(ScrollController) contentBuilder;

  const _DetailSheet({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.contentBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: MediaQuery.of(context).textScaler
            .clamp(maxScaleFactor: _kMaxTextScale),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: _kCard,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _kBorder,
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
                        color: iconColor.withValues(alpha: .15),
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
                      onTap: Get.back,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _kCard2,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: _kBorder),
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: _kSub),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: _kBorder),
              Expanded(child: contentBuilder(scrollCtrl)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hero Card: กำไรสุทธิ ──────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final String label, amount;
  final double trend;
  final String trendLabel;
  final IconData iconData;
  final Color iconBg, iconFg;
  final VoidCallback? onTap;

  const _HeroCard({
    required this.label,
    required this.amount,
    required this.trend,
    required this.trendLabel,
    required this.iconData,
    required this.iconBg,
    required this.iconFg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPos = trend >= 0;
    final trendColor =
        trend == 0 ? _kSub : (isPos ? _kGreen : _kRed);
    final trendText =
        '${isPos && trend != 0 ? '+' : ''}${trend.toStringAsFixed(1)}%';
    final trendIcon = trend == 0
        ? Icons.remove
        : (isPos
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: iconFg, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kInk,
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: trendColor.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: trendColor.withValues(alpha: .4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(trendIcon, size: 13, color: trendColor),
                          const SizedBox(width: 4),
                          Text(
                            trendText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: trendColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trendLabel,
                      style: const TextStyle(fontSize: 11, color: _kSub),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                amount,
                style: const TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w800,
                  color: _kInk,
                  letterSpacing: -1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Dashed divider
            LayoutBuilder(builder: (_, cons) {
              const dw = 6.0, dh = 1.5, gap = 4.0;
              final n = (cons.maxWidth / (dw + gap)).floor();
              return Row(
                children: List.generate(
                  n,
                  (_) => Container(
                    width: dw,
                    height: dh,
                    margin: const EdgeInsets.only(right: gap),
                    color: _kBorder,
                  ),
                ),
              );
            }),
            if (onTap != null) ...[
              const SizedBox(height: 10),
              Row(
                children: const [
                  Icon(Icons.touch_app_rounded,
                      size: 11, color: _kMuted),
                  SizedBox(width: 4),
                  Text(
                    'แตะเพื่อดูรายละเอียดแยกรายสินค้า',
                    style: TextStyle(fontSize: 11, color: _kMuted),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Compact Card: ยอดขายรวม / ต้นทุนรวม ─────────────────────────────────────
class _CompactCard extends StatelessWidget {
  final String label, amount;
  final double trend;
  final IconData iconData;
  final Color iconBg, iconFg;
  final bool isCost;
  final VoidCallback? onTap;

  const _CompactCard({
    required this.label,
    required this.amount,
    required this.trend,
    required this.iconData,
    required this.iconBg,
    required this.iconFg,
    this.isCost = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPos = trend >= 0;
    Color trendColor;
    if (trend == 0) {
      trendColor = _kSub;
    } else if (isCost) {
      trendColor = isPos ? _kRed : _kGreen;
    } else {
      trendColor = isPos ? _kGreen : _kRed;
    }
    final trendText =
        '${isPos && trend != 0 ? '+' : ''}${trend.toStringAsFixed(1)}%';
    final trendIcon = trend == 0
        ? Icons.remove
        : (isPos
            ? Icons.north_east_rounded
            : Icons.south_east_rounded);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: iconFg, size: 20),
                ),
                const Spacer(),
                if (onTap != null)
                  const Icon(Icons.chevron_right_rounded,
                      size: 16, color: _kMuted),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _kSub,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                amount,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _kInk,
                  letterSpacing: -.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(trendIcon, size: 14, color: trendColor),
                const SizedBox(width: 4),
                Text(
                  trendText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: trendColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Transaction Card: จำนวนรายการ ───────────────────────────────────────────
class _TransactionCard extends StatelessWidget {
  final String count, trendLabel, selectedView;
  final double trend;
  final VoidCallback? onTap;

  const _TransactionCard({
    required this.count,
    required this.trend,
    required this.trendLabel,
    required this.selectedView,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPos = trend >= 0;
    final trendColor =
        trend == 0 ? _kSub : (isPos ? _kGreen : _kRed);
    final trendText =
        '${isPos && trend != 0 ? '+' : ''}${trend.toStringAsFixed(1)}%';
    final trendIcon = trend == 0
        ? Icons.remove
        : (isPos
            ? Icons.north_east_rounded
            : Icons.south_east_rounded);

    final String subtitle;
    if (selectedView == 'วันนี้') {
      subtitle = 'จำนวนรายการวันนี้';
    } else if (selectedView == 'เดือนนี้') {
      subtitle = 'จำนวนรายการเดือนนี้';
    } else {
      subtitle = 'จำนวนรายการปีนี้';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: _kPurpleDim,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_rounded,
                  color: _kPurple, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count รายการ',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _kInk,
                      letterSpacing: -.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: _kSub),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: trendColor.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: trendColor.withValues(alpha: .35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    trendText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: trendColor,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(trendIcon, size: 14, color: trendColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
