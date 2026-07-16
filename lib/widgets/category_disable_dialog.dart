import 'package:eazy_store/model/request/category_model.dart';
import 'package:eazy_store/page/product/category/move_category_products_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryDisableDialog {
  static Future<void> show({
    required BuildContext context,
    required CategoryModel category,
    required int productCount,
    required Future<bool> Function() onDisable,
    required Future<void> Function() onRefreshCategories,
    required VoidCallback onReopenBottomSheet,
  }) async {
    if (productCount > 0) {
      await _showWithProductsDialog(
        context: context,
        category: category,
        productCount: productCount,
        onDisable: onDisable,
        onRefreshCategories: onRefreshCategories,
        onReopenBottomSheet: onReopenBottomSheet,
      );
    } else {
      await _showEmptyDialog(
        context: context,
        category: category,
        onDisable: onDisable,
        onRefreshCategories: onRefreshCategories,
        onReopenBottomSheet: onReopenBottomSheet,
      );
    }
  }

  static Future<void> _showEmptyDialog({
    required BuildContext context,
    required CategoryModel category,
    required Future<bool> Function() onDisable,
    required Future<void> Function() onRefreshCategories,
    required VoidCallback onReopenBottomSheet,
  }) async {
    await Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _iconHeader(),
              const SizedBox(height: 16),
              Text(
                "ปิดใช้งานหมวดหมู่?",
                textAlign: TextAlign.center,
                style: GoogleFonts.prompt(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "หมวดหมู่นี้จะไม่แสดงให้เลือกอีก แต่สามารถกู้คืนได้ภายหลัง",
                textAlign: TextAlign.center,
                style: GoogleFonts.prompt(
                  color: Colors.grey[700],
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: _cancelButton(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleDisable(
                        context: context,
                        onDisable: onDisable,
                        onRefreshCategories: onRefreshCategories,
                        onReopenBottomSheet: onReopenBottomSheet,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text(
                        "ปิดใช้งาน",
                        style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _showWithProductsDialog({
    required BuildContext context,
    required CategoryModel category,
    required int productCount,
    required Future<bool> Function() onDisable,
    required Future<void> Function() onRefreshCategories,
    required VoidCallback onReopenBottomSheet,
  }) async {
    await Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _iconHeader(),
              const SizedBox(height: 16),
              Text(
                "หมวดหมู่นี้มีสินค้า $productCount รายการ",
                textAlign: TextAlign.center,
                style: GoogleFonts.prompt(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "คุณต้องการทำอย่างไร?",
                textAlign: TextAlign.center,
                style: GoogleFonts.prompt(
                  color: Colors.grey[700],
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: Text("ยกเลิก", style: GoogleFonts.prompt()),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _handleDisable(
                    context: context,
                    onDisable: onDisable,
                    onRefreshCategories: onRefreshCategories,
                    onReopenBottomSheet: onReopenBottomSheet,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: Text(
                    "ปิดไว้ก่อน",
                    style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context, rootNavigator: true).pop();
                    final result = await Get.to<bool>(
                      () => MoveCategoryProductsPage(
                        sourceCategory: category,
                        productCount: productCount,
                      ),
                    );
                    if (result == true) {
                      await onRefreshCategories();
                      onReopenBottomSheet();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B8E23),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: Text(
                    "ย้ายสินค้าไปหมวดอื่น",
                    style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _iconHeader() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.block_rounded,
        color: Colors.redAccent,
        size: 34,
      ),
    );
  }

  static Widget _cancelButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.grey[700],
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 13),
      ),
      child: Text("ยกเลิก", style: GoogleFonts.prompt()),
    );
  }

  static Future<void> _handleDisable({
    required BuildContext context,
    required Future<bool> Function() onDisable,
    required Future<void> Function() onRefreshCategories,
    required VoidCallback onReopenBottomSheet,
  }) async {
    final ok = await onDisable();
    if (!ok) return;
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    await Future.delayed(const Duration(milliseconds: 180));
    await onRefreshCategories();
    onReopenBottomSheet();
  }
}
