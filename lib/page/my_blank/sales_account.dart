import 'package:eazy_store/page/menu_bar/bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eazy_store/page/my_blank/advanced_report_page.dart';

// ✅ สำคัญ: อย่าลืม Import ไฟล์ Controller ให้ตรงกับ Path ของคุณ
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
    final SalesAccountController controller = Get.put(SalesAccountController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchSummaryData();
    });

    return Scaffold(
      backgroundColor: _kBackgroundColor,
      // ✨ คุมฟอนต์สูงสุด 1.2 เท่า เพื่อรักษาความสวยงามของกล่อง Layout
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: MediaQuery.textScalerOf(
            context,
          ).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.2),
        ),
        child: SafeArea(
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
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
                            const Text(
                              'ตรวจสอบยอดขายแบบเรียลไทม์',
                              style: TextStyle(
                                fontSize: 14,
                                color: _kTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => Get.to(() => AdvancedReportPage()),
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
                          child: CircularProgressIndicator(
                            color: _kPrimaryBlue,
                          ),
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
                                onTap: controller.selectedView.value == 'ปีนี้'
                                    ? null
                                    : () => _showProductSalesDetail(context, controller, 'รายละเอียด: ยอดขายรวม', false),
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
                                onTap: controller.selectedView.value == 'ปีนี้'
                                    ? null
                                    : () => _showProductSalesDetail(context, controller, 'รายละเอียด: ต้นทุนรวม', true),
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
                                onTap: controller.selectedView.value == 'ปีนี้'
                                    ? null
                                    : () => _showProductSalesDetail(context, controller, 'รายละเอียด: กำไรสุทธิ', false),
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
                                onTap: controller.selectedView.value == 'ปีนี้'
                                    ? null
                                    : () => _showTransactionsDetail(context, controller),
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
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1, // ล็อคให้เป็นสีแดงที่หน้าหลักเสมอเมื่ออยู่หน้านี้
        onTap: (index) {
          controller.changeTab(index);
        },
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
                const Icon(
                  Icons.calendar_month,
                  size: 18,
                  color: _kPrimaryBlue,
                ),
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
    VoidCallback? onTap,
  }) {
    bool isPositive = trend >= 0;
    Color trendColor;
    if (isCost) {
      trendColor = isPositive ? _kDangerRed : _kSuccessGreen;
    } else {
      trendColor = isPositive ? _kSuccessGreen : _kDangerRed;
    }
    if (trend == 0) trendColor = Colors.grey;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: _kTextMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                      ),
                    ),
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
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: _kTextDark,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Row(
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
                    Text(
                      trendLabel,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // Popups รายละเอียด (Transactions & Product Sales)
  // ----------------------------------------------------------------------

  void _showTransactionsDetail(BuildContext context, SalesAccountController controller) {
    controller.fetchTransactionsDetail();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  _buildBottomSheetHeader('รายการบิลทั้งหมด', context, Icons.receipt_long, Colors.purple.shade600),
                  Expanded(
                    child: Obx(() {
                      if (controller.isDetailLoading.value) {
                        return const Center(child: CircularProgressIndicator(color: _kPrimaryBlue));
                      }
                      if (controller.transactionsList.isEmpty) {
                        return _buildEmptyState('ไม่มีรายการขายในช่วงเวลานี้');
                      }
                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: controller.transactionsList.length,
                        itemBuilder: (context, index) {
                          final item = controller.transactionsList[index];
                          
                          // กำหนดสีและไอคอนตามวิธีการชำระเงิน
                          Color methodColor;
                          IconData methodIcon;
                          if (item.paymentMethod == 'จ่ายเงินสด') {
                            methodColor = _kSuccessGreen;
                            methodIcon = Icons.payments;
                          } else if (item.paymentMethod == 'โอนจ่าย') {
                            methodColor = _kPrimaryBlue;
                            methodIcon = Icons.account_balance;
                          } else { // ค้างชำระ หรืออื่นๆ
                            methodColor = Colors.orange.shade700;
                            methodIcon = Icons.pending_actions;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: methodColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    methodIcon,
                                    color: methodColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'บิล #${item.saleId}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _kTextDark),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item.createdAt} ${item.createdTime ?? ''}',
                                        style: const TextStyle(fontSize: 12, color: _kTextMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '฿${controller.formatNumber(item.netPrice)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _kTextDark),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: methodColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        item.paymentMethod,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: methodColor,
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
            );
          },
        );
      },
    );
  }

  void _showProductSalesDetail(BuildContext context, SalesAccountController controller, String title, bool isCost) {
    controller.fetchProductSalesDetail();
    IconData headerIcon = Icons.inventory_2;
    Color headerIconColor = _kPrimaryBlue;
    if (title.contains('กำไร')) {
      headerIcon = Icons.account_balance_wallet;
      headerIconColor = _kSuccessGreen;
    } else if (title.contains('ต้นทุน')) {
      headerIcon = Icons.shopping_bag_outlined;
      headerIconColor = Colors.orange.shade700;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  _buildBottomSheetHeader(title, context, headerIcon, headerIconColor),
                  Expanded(
                    child: Obx(() {
                      if (controller.isDetailLoading.value) {
                        return const Center(child: CircularProgressIndicator(color: _kPrimaryBlue));
                      }
                      if (controller.productSalesList.isEmpty) {
                        return _buildEmptyState('ไม่มีข้อมูลสินค้าในช่วงเวลานี้');
                      }
                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: controller.productSalesList.length,
                        itemBuilder: (context, index) {
                          final item = controller.productSalesList[index];
                          
                          double mainAmount = item.profit;
                          Color mainColor = _kSuccessGreen;
                          if (title.contains('ยอดขาย')) {
                            mainAmount = item.totalSales;
                            mainColor = _kPrimaryBlue;
                          } else if (title.contains('ต้นทุน')) {
                            mainAmount = item.totalCost;
                            mainColor = Colors.orange.shade700;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 55,
                                  height: 55,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: Colors.grey.shade100,
                                    border: Border.all(color: Colors.black.withOpacity(0.05)),
                                    image: item.imgProduct.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(item.imgProduct),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: item.imgProduct.isEmpty ? const Icon(Icons.inventory_2, color: Colors.grey) : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _kTextDark),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.shopping_cart, size: 14, color: Colors.grey.shade400),
                                          const SizedBox(width: 4),
                                          Text(
                                            'ขายได้ ${item.totalQty} ชิ้น',
                                            style: const TextStyle(fontSize: 13, color: _kTextMuted),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: mainColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '฿${controller.formatNumber(mainAmount)}',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: mainColor),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      title.contains('กำไร') ? 'ขาย: ฿${controller.formatNumber(item.totalSales)}' : 'กำไร: ฿${controller.formatNumber(item.profit)}',
                                      style: const TextStyle(fontSize: 11, color: _kTextMuted),
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
            );
          },
        );
      },
    );
  }

  Widget _buildBottomSheetHeader(String title, BuildContext context, IconData icon, Color iconColor) {
    return Column(
      children: [
        const SizedBox(height: 12),
        // Pill handle
        Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kTextDark),
                  ),
                ],
              ),
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 20, color: _kTextMuted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: _kTextMuted, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
