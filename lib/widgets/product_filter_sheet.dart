import 'package:eazy_store/model/request/category_model.dart';
import 'package:flutter/material.dart';

const Color _accentOlive = Color(0xFF6B8E23);
const Color _accentOliveDark = Color(0xFF4E6B19);
const Color _accentOliveSoft = Color(0xFFEAF1DC);

class ProductSortOption {
  final String label;
  final String value;

  const ProductSortOption({required this.label, required this.value});
}

/// A sortable field (e.g. "ชื่อสินค้า") paired with its two directions.
/// Lets the filter sheet show one row per field instead of one row per
/// field+direction combination, with the direction picked inline.
class ProductSortField {
  final String label;
  final IconData icon;
  final ProductSortOption asc;
  final ProductSortOption desc;

  const ProductSortField({
    required this.label,
    required this.icon,
    required this.asc,
    required this.desc,
  });
}

/// Shared sort fields so every screen that filters products shows the
/// same order and wording in "จัดเรียงตาม".
const List<ProductSortField> defaultProductSortFields = [
  ProductSortField(
    label: 'ชื่อสินค้า',
    icon: Icons.sort_by_alpha_rounded,
    asc: ProductSortOption(label: 'ก → ฮ', value: 'name_asc'),
    desc: ProductSortOption(label: 'ฮ → ก', value: 'name_desc'),
  ),
  ProductSortField(
    label: 'สต็อกคงเหลือ',
    icon: Icons.inventory_2_rounded,
    asc: ProductSortOption(label: 'น้อย → มาก', value: 'stock_asc'),
    desc: ProductSortOption(label: 'มาก → น้อย', value: 'stock_desc'),
  ),
];

ProductSortField? _fieldOf(List<ProductSortField> fields, String value) {
  for (final field in fields) {
    if (field.asc.value == value || field.desc.value == value) return field;
  }
  return null;
}

/// Filter icon button that opens the shared category + sort bottom sheet.
/// Used by both the check-stock screen and the buy-products screen so the
/// two keep the exact same filter UI/behavior.
class ProductFilterButton extends StatelessWidget {
  final List<CategoryModel> categories;
  final int selectedCategoryId;
  final List<ProductSortField> sortFields;
  final String selectedSortValue;
  final String defaultSortValue;
  final void Function(int categoryId, String sortValue) onApply;
  final VoidCallback onClear;

  const ProductFilterButton({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.sortFields,
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
        sortFields: sortFields,
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
  required List<ProductSortField> sortFields,
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
        final activeField = _fieldOf(sortFields, tempSortValue);
        final activeOption = activeField == null
            ? null
            : (activeField.asc.value == tempSortValue
                  ? activeField.asc
                  : activeField.desc);

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
                        const SizedBox(height: 10),
                        if (activeField != null && activeOption != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: _accentOliveSoft,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.swap_vert_rounded,
                                  size: 14,
                                  color: _accentOliveDark,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'เรียงตาม ${activeField.label} · ${activeOption.label}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: _accentOliveDark,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ...sortFields.map(
                          (field) => _SortFieldTile(
                            field: field,
                            selectedValue: tempSortValue,
                            onSelect: (value) =>
                                setModalState(() => tempSortValue = value),
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

/// One row per sortable field. Tapping the header selects the field
/// (defaulting to ascending); the direction toggle only appears once the
/// field is selected, so a 4-way choice fits in 2 compact rows instead of 4.
class _SortFieldTile extends StatelessWidget {
  final ProductSortField field;
  final String selectedValue;
  final ValueChanged<String> onSelect;

  const _SortFieldTile({
    required this.field,
    required this.selectedValue,
    required this.onSelect,
  });

  bool get _isSelected =>
      selectedValue == field.asc.value || selectedValue == field.desc.value;

  bool get _isDesc => selectedValue == field.desc.value;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _isSelected ? Colors.white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: _isSelected ? const Color(0xFF1A1A1A) : Colors.grey.shade200,
          width: _isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () =>
                onSelect(_isSelected ? selectedValue : field.asc.value),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(field.icon, size: 15, color: Colors.black87),
                    const SizedBox(width: 8),
                    Text(
                      field.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (!_isSelected)
                  Text(
                    field.asc.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: !_isSelected
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 9),
                    child: Row(
                      children: [
                        Expanded(
                          child: _DirButton(
                            label: field.asc.label,
                            isDesc: false,
                            isActive: !_isDesc,
                            onTap: () => onSelect(field.asc.value),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _DirButton(
                            label: field.desc.label,
                            isDesc: true,
                            isActive: _isDesc,
                            onTap: () => onSelect(field.desc.value),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DirButton extends StatelessWidget {
  final String label;
  final bool isDesc;
  final bool isActive;
  final VoidCallback onTap;

  const _DirButton({
    required this.label,
    required this.isDesc,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _accentOliveSoft : Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isActive ? _accentOlive : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDesc
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 13,
              color: isActive ? _accentOliveDark : Colors.black54,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isActive ? _accentOliveDark : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
