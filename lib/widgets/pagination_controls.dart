import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:eazy_store/page/product/checkStock/check_stock_controller.dart';

class PaginationControls extends StatelessWidget {
  final CheckStockController controller;
  final Color primaryColor;

  const PaginationControls({
    super.key,
    required this.controller,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(child: _buildLimitSelector()),
            const SizedBox(width: 12),
            Expanded(child: _buildPageNavigation()),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitSelector() {
    return Obx(
      () => Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryColor.withOpacity(0.18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'แสดง',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            PopupMenuButton<int>(
              initialValue: controller.itemsPerPage.value,
              onSelected: controller.updateLimit,
              itemBuilder: (BuildContext context) => [
                _buildPopupItem(10),
                _buildPopupItem(20),
                _buildPopupItem(30),
                _buildPopupItem(50),
              ],
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: primaryColor.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.itemsPerPage.value.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.expand_more,
                      size: 18,
                      color: primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageNavigation() {
    return Obx(
      () => Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryColor.withOpacity(0.18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavButton(
              icon: Icons.chevron_left,
              onPressed: controller.currentPage.value > 1
                  ? () => controller.changePage(controller.currentPage.value - 1)
                  : null,
              isEnabled: controller.currentPage.value > 1,
            ),
            Text(
              '${controller.currentPage.value}/${controller.totalPages.value}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            _buildNavButton(
              icon: Icons.chevron_right,
              onPressed:
                  controller.currentPage.value < controller.totalPages.value
                      ? () => controller
                          .changePage(controller.currentPage.value + 1)
                      : null,
              isEnabled:
                  controller.currentPage.value < controller.totalPages.value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isEnabled,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isEnabled ? Colors.white : Colors.grey[150],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isEnabled ? primaryColor : Colors.grey[400],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<int> _buildPopupItem(int value) {
    return PopupMenuItem<int>(
      value: value,
      child: Text(
        value.toString(),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}
