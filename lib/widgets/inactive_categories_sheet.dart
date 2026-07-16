import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/model/request/category_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color _kPrimaryColor = Color(0xFF6B8E23);

class InactiveCategoriesSheet {
  static Future<void> show({
    required BuildContext context,
    required Future<void> Function() onCategoriesChanged,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return _InactiveCategoriesContent(
              scrollController: scrollController,
              onCategoriesChanged: onCategoriesChanged,
            );
          },
        );
      },
    );
  }
}

class _InactiveCategoriesContent extends StatefulWidget {
  final ScrollController scrollController;
  final Future<void> Function() onCategoriesChanged;

  const _InactiveCategoriesContent({
    required this.scrollController,
    required this.onCategoriesChanged,
  });

  @override
  State<_InactiveCategoriesContent> createState() =>
      _InactiveCategoriesContentState();
}

class _InactiveCategoriesContentState extends State<_InactiveCategoriesContent> {
  final RxList<CategoryModel> _categories = <CategoryModel>[].obs;
  final RxBool _isLoading = true.obs;
  final RxInt _restoringId = 0.obs;
  int _shopId = 0;

  @override
  void initState() {
    super.initState();
    _loadInactiveCategories();
  }

  Future<void> _loadInactiveCategories() async {
    _isLoading.value = true;
    final prefs = await SharedPreferences.getInstance();
    _shopId = prefs.getInt('shopId') ?? 0;
    if (_shopId == 0) {
      _categories.clear();
      _isLoading.value = false;
      return;
    }
    final list = await ApiProduct.getInactiveCategories(_shopId);
    _categories.assignAll(list);
    _isLoading.value = false;
  }

  Future<void> _restoreCategory(CategoryModel category) async {
    _restoringId.value = category.categoryId;
    try {
      final result = await ApiProduct.restoreCategory(
        categoryId: category.categoryId,
        shopId: _shopId,
      );
      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'กู้คืนหมวดหมู่ไม่สำเร็จ');
      }

      _categories.removeWhere(
        (item) => item.categoryId == category.categoryId,
      );

      Get.snackbar(
        "กู้คืนสำเร็จ",
        "หมวดหมู่ ${category.name} กลับมาใช้งานแล้ว",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );

      await widget.onCategoriesChanged();
    } catch (e) {
      Get.snackbar(
        "ผิดพลาด",
        "$e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _restoringId.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "หมวดหมู่ที่ปิดใช้งาน",
                    style: GoogleFonts.prompt(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (_isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: _kPrimaryColor),
                );
              }

              if (_categories.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "ยังไม่มีหมวดหมู่ที่ปิดใช้งาน",
                          style: GoogleFonts.prompt(
                            color: Colors.grey[500],
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                controller: widget.scrollController,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isRestoring =
                      _restoringId.value == category.categoryId;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            category.name,
                            style: GoogleFonts.prompt(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: isRestoring
                              ? null
                              : () => _restoreCategory(category),
                          style: TextButton.styleFrom(
                            foregroundColor: _kPrimaryColor,
                          ),
                          child: isRestoring
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _kPrimaryColor,
                                  ),
                                )
                              : Text(
                                  "กู้คืน",
                                  style: GoogleFonts.prompt(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
  }
}
