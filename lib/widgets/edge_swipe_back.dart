import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EdgeSwipeBack extends StatefulWidget {
  const EdgeSwipeBack({required this.child, super.key});

  final Widget child;

  @override
  State<EdgeSwipeBack> createState() => _EdgeSwipeBackState();
}

class _EdgeSwipeBackState extends State<EdgeSwipeBack> {
  static const double _edgeWidth = 32;
  static const double _minimumSwipeDistance = 90;

  final Map<int, Offset> _dragStarts = {};

  void _onPointerDown(PointerDownEvent event) {
    if (event.position.dx <= _edgeWidth) {
      _dragStarts[event.pointer] = event.position;
    }
  }

  void _onPointerUp(PointerEvent event) {
    final start = _dragStarts.remove(event.pointer);
    if (start == null) return;

    final delta = event.position - start;
    if (delta.dx < _minimumSwipeDistance || delta.dx <= delta.dy.abs() * 1.5) {
      return;
    }
    if (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) return;
    if (Get.key.currentState?.canPop() != true) return;

    Get.back<void>();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _dragStarts.remove(event.pointer);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: widget.child,
    );
  }
}
