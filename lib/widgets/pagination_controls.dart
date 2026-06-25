import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaginationControls extends StatefulWidget {
  final RxInt currentPage;
  final RxInt totalPages;
  final RxInt itemsPerPage;
  final void Function(int) updateLimit;
  final void Function(int) changePage;
  final Color primaryColor;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.itemsPerPage,
    required this.updateLimit,
    required this.changePage,
    required this.primaryColor,
  });

  @override
  State<PaginationControls> createState() => _PaginationControlsState();
}

class _PaginationControlsState extends State<PaginationControls> {
  static const double _controlHeight = 32;
  late final TextEditingController _limitController;

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController(
      text: widget.itemsPerPage.value.toString(),
    );
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

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
      () {
        final limit = widget.itemsPerPage.value;
        _limitController.text = limit.toString();

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: _controlHeight,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.primaryColor.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'แสดง',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 52,
                  height: _controlHeight - 4,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: widget.primaryColor.withOpacity(0.35)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: TextFormField(
                    controller: _limitController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                      border: InputBorder.none,
                    ),
                    onFieldSubmitted: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        widget.updateLimit(parsed);
                      } else {
                        _limitController.text = limit.toString();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<int>(
                  padding: EdgeInsets.zero,
                  offset: const Offset(0, -160),
                  initialValue: limit,
                  onSelected: (value) {
                    widget.updateLimit(value);
                  },
                  itemBuilder: (BuildContext context) => [
                    _buildPopupItem(10, limit == 10),
                    _buildPopupItem(20, limit == 20),
                    _buildPopupItem(30, limit == 30),
                    _buildPopupItem(50, limit == 50),
                  ],
                  child: Icon(Icons.expand_more, size: 18, color: widget.primaryColor),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageNavigation() {
    return Obx(
      () {
        final canPrev = widget.currentPage.value > 1;
        final canNext = widget.currentPage.value < widget.totalPages.value;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNavButton(
              icon: Icons.chevron_left,
              onPressed: canPrev
                  ? () => widget.changePage(widget.currentPage.value - 1)
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
                '${widget.currentPage.value} / ${widget.totalPages.value}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            _buildNavButton(
              icon: Icons.chevron_right,
              onPressed: canNext
                  ? () => widget.changePage(widget.currentPage.value + 1)
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
            color: isEnabled ? widget.primaryColor : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  PopupMenuItem<int> _buildPopupItem(int value, bool isSelected) {
    return PopupMenuItem<int>(
      value: value,
      child: Row(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 14,
              color: isSelected ? widget.primaryColor : Colors.black87,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const Spacer(),
          if (isSelected)
            Icon(Icons.check, size: 16, color: widget.primaryColor),
        ],
      ),
    );
  }
}
