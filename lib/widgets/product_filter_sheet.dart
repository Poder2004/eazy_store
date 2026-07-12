import 'package:eazy_store/model/request/category_model.dart';
import 'package:flutter/material.dart';

class ProductSortOption {
  final String label;
  final String value;

  const ProductSortOption({required this.label, required this.value});
}

/// Shared sort options so every screen that filters products shows the
/// same order and wording in "จัดเรียงตาม".
const List<ProductSortOption> defaultProductSortOptions = [
  ProductSortOption(label: 'ชื่อสินค้า (ก – ฮ)', value: 'name_asc'),
  ProductSortOption(label: 'ชื่อสินค้า (ฮ – ก)', value: 'name_desc'),
  ProductSortOption(label: 'สต็อกคงเหลือ (น้อย ไป มาก)', value: 'stock_asc'),
  ProductSortOption(label: 'สต็อกคงเหลือ (มาก ไป น้อย)', value: 'stock_desc'),
];

/// Filter icon button that opens the shared category + sort bottom sheet.
/// Used by both the check-stock screen and the buy-products screen so the
/// two keep the exact same filter UI/behavior.
class ProductFilterButton extends StatelessWidget {
  final List<CategoryModel> categories;
  final int selectedCategoryId;
  final List<ProductSortOption> sortOptions;
  final String selectedSortValue;
  final String defaultSortValue;
  final void Function(int categoryId, String sortValue) onApply;
  final VoidCallback onClear;

  const ProductFilterButton({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.sortOptions,
    required this.selectedSortValue,
    required this.defaultSortValue,
    required this.onApply,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isActive =
        selectedCategoryId != 0 || selectedSortValue != defaultSortValue;

    return GestureDetector(
      onTap: () => _showProductFilterSheet(
        context,
        categories: categories,
        selectedCategoryId: selectedCategoryId,
        sortOptions: sortOptions,
        selectedSortValue: selectedSortValue,
        onApply: onApply,
        onClear: onClear,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(
              Icons.tune_rounded,
              color: isActive ? Colors.white : Colors.grey.shade700,
              size: 22,
            ),
          ),
          if (isActive)
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void _showProductFilterSheet(
  BuildContext context, {
  required List<CategoryModel> categories,
  required int selectedCategoryId,
  required List<ProductSortOption> sortOptions,
  required String selectedSortValue,
  required void Function(int categoryId, String sortValue) onApply,
  required VoidCallback onClear,
}) {
  int tempCategoryId = selectedCategoryId;
  String tempSortValue = selectedSortValue;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModalState) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.9,
          ),
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 16,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ตัวกรอง',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Scrollable middle section (category + sort) so it never
                // overflows on short screens or when the list grows.
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category section
                        const Text(
                          'หมวดหมู่สินค้า',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _FilterChip(
                              label: 'ทั้งหมด',
                              isSelected: tempCategoryId == 0,
                              onTap: () =>
                                  setModalState(() => tempCategoryId = 0),
                            ),
                            ...categories.map(
                              (cat) => _FilterChip(
                                label: cat.name,
                                isSelected: tempCategoryId == cat.categoryId,
                                onTap: () => setModalState(
                                  () => tempCategoryId = cat.categoryId,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        // Sort section
                        const Text(
                          'จัดเรียงตาม',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...sortOptions.map(
                          (opt) => _SortOptionTile(
                            label: opt.label,
                            isSelected: tempSortValue == opt.value,
                            onTap: () => setModalState(
                              () => tempSortValue = opt.value,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          onClear();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: const Text(
                          'ล้างตัวกรอง',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          onApply(tempCategoryId, tempSortValue);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1A1A),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'แสดงผล',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A1A1A) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _SortOptionTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortOptionTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A1A1A) : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1A1A1A)
                      : Colors.grey.shade400,
                  width: 1.5,
                ),
                color: isSelected
                    ? const Color(0xFF1A1A1A)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
