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

  static const double _controlHeight = 32;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          _buildLimitSelector(),
          const Spacer(),
          _buildPageNavigation(),
        ],
      ),
    );
  }

  Widget _buildLimitSelector() {
    return Obx(
      () => Material(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
        child: PopupMenuButton<int>(
          padding: EdgeInsets.zero,
          offset: const Offset(0, -160),
          initialValue: controller.itemsPerPage.value,
          onSelected: controller.updateLimit,
          itemBuilder: (BuildContext context) => [
            _buildPopupItem(10),
            _buildPopupItem(20),
            _buildPopupItem(30),
            _buildPopupItem(50),
          ],
          child: Container(
            height: _controlHeight,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'แสดง  ${controller.itemsPerPage.value}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(Icons.expand_more, size: 16, color: Colors.grey.shade700),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageNavigation() {
    return Obx(
      () {
        final canPrev = controller.currentPage.value > 1;
        final canNext =
            controller.currentPage.value < controller.totalPages.value;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNavButton(
              icon: Icons.chevron_left,
              onPressed: canPrev
                  ? () =>
                      controller.changePage(controller.currentPage.value - 1)
                  : null,
              isEnabled: canPrev,
            ),
            const SizedBox(width: 6),
            Container(
              height: _controlHeight,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                '${controller.currentPage.value} / ${controller.totalPages.value}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            _buildNavButton(
              icon: Icons.chevron_right,
              onPressed: canNext
                  ? () =>
                      controller.changePage(controller.currentPage.value + 1)
                  : null,
              isEnabled: canNext,
            ),
          ],
        );
      },
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isEnabled,
  }) {
    return Material(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: _controlHeight,
          height: _controlHeight,
          child: Icon(
            icon,
            size: 18,
            color: isEnabled ? primaryColor : Colors.grey.shade400,
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
