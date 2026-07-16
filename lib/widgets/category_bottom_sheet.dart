import 'package:eazy_store/model/request/category_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _kPrimaryColor = Color(0xFF6B8E23);

class CategoryBottomSheet {
  static void show({
    required BuildContext context,
    required List<CategoryModel> categories,
    required Rx<CategoryModel?> selectedCategory,
    required Function(CategoryModel) onCategorySelected,
    VoidCallback? onAddCategory,
    Function(CategoryModel)? onEditCategory,
    Function(CategoryModel)? onDisableCategory,
    VoidCallback? onManageInactiveCategories,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final RxString searchQuery = "".obs;
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
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
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "เลือกหมวดหมู่",
                            style: GoogleFonts.prompt(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (onManageInactiveCategories != null)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            tooltip: "จัดการหมวดหมู่",
                            onSelected: (value) {
                              if (value == 'inactive') {
                                Navigator.pop(context);
                                onManageInactiveCategories();
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'inactive',
                                child: Text(
                                  "จัดการหมวดหมู่ที่ปิดใช้งาน",
                                  style: GoogleFonts.prompt(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        onChanged: (val) {
                          searchQuery.value = val.trim();
                        },
                        style: GoogleFonts.prompt(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "ค้นหาหมวดหมู่...",
                          hintStyle: GoogleFonts.prompt(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Obx(() {
                      final query = searchQuery.value.toLowerCase();
                      final filteredList = categories.where((cat) {
                        return cat.name.toLowerCase().contains(query);
                      }).toList();

                      if (filteredList.isEmpty && onAddCategory == null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.category_outlined,
                                size: 48,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "ไม่พบหมวดหมู่",
                                style: GoogleFonts.prompt(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        itemCount: filteredList.length +
                            (onAddCategory != null ? 1 : 0),
                        itemBuilder: (context, index) {
                          // ปุ่มเพิ่มหมวดหมู่อยู่ท้ายรายการหมวดหมู่ที่แสดง
                          if (onAddCategory != null &&
                              index == filteredList.length) {
                            return InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                onAddCategory();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey[100]!,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.add_circle_outline,
                                          color: _kPrimaryColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          "เพิ่มหมวดหมู่",
                                          style: GoogleFonts.prompt(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: _kPrimaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      color: _kPrimaryColor,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          // ✅ ปรับ index สำหรับหมวดหมู่จริง
                          if (index >= filteredList.length) {
                            return const SizedBox.shrink();
                          }

                          final cat = filteredList[index];
                          final isSelected =
                              selectedCategory.value?.categoryId ==
                              cat.categoryId;

                          return InkWell(
                            onTap: () {
                              selectedCategory.value = cat;
                              onCategorySelected(cat);
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom:
                                      BorderSide(color: Colors.grey[100]!),
                                ),
                                color: isSelected
                                    ? _kPrimaryColor.withOpacity(0.05)
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            cat.name,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.prompt(
                                              fontSize: 15,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? _kPrimaryColor
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: _kPrimaryColor,
                                            size: 20,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      if (onEditCategory != null)
                                        Tooltip(
                                          message: "แก้ไขหมวดหมู่",
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.pop(context);
                                              onEditCategory(cat);
                                            },
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Container(
                                              width: 40,
                                              height: 40,
                                              margin: const EdgeInsets.only(
                                                left: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEAF4FF),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color:
                                                      const Color(0xFF90CAF9),
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.edit_rounded,
                                                color: Color(0xFF1E88E5),
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (onDisableCategory != null)
                                        Tooltip(
                                          message: "ปิดใช้งานหมวดหมู่",
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.pop(context);
                                              onDisableCategory(cat);
                                            },
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Container(
                                              width: 40,
                                              height: 40,
                                              margin: const EdgeInsets.only(
                                                left: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFEBEE),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color:
                                                      const Color(0xFFEF9A9A),
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.delete_outline_rounded,
                                                color: Color(0xFFE53935),
                                                size: 21,
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
}
