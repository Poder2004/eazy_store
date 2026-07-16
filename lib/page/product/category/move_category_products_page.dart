import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/model/request/category_model.dart';
import 'package:eazy_store/model/response/product_response.dart';
import 'package:eazy_store/utils/thai_sort.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color _kPrimaryColor = Color(0xFF6B8E23);

class MoveCategoryProductsPage extends StatefulWidget {
  final CategoryModel sourceCategory;
  final int productCount;

  const MoveCategoryProductsPage({
    super.key,
    required this.sourceCategory,
    required this.productCount,
  });

  @override
  State<MoveCategoryProductsPage> createState() =>
      _MoveCategoryProductsPageState();
}

class _MoveCategoryProductsPageState extends State<MoveCategoryProductsPage> {
  final RxList<CategoryModel> _categories = <CategoryModel>[].obs;
  final RxList<ProductResponse> _products = <ProductResponse>[].obs;
  final RxSet<int> _selectedProductIds = <int>{}.obs;
  final Rxn<CategoryModel> _selectedCategory = Rxn<CategoryModel>();
  final RxBool _isLoading = true.obs;
  final RxBool _isSaving = false.obs;
  int _shopId = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _isLoading.value = true;
    final prefs = await SharedPreferences.getInstance();
    _shopId = prefs.getInt('shopId') ?? widget.sourceCategory.shopId;

    final categoriesFuture = ApiProduct.getCategories(_shopId);
    final productsFuture = ApiProduct.getProductsByShop(
      _shopId,
      page: 1,
      limit: widget.productCount > 0 ? widget.productCount : 500,
      categoryId: widget.sourceCategory.categoryId,
      sort: 'name_asc',
    );

    final results = await Future.wait([categoriesFuture, productsFuture]);
    final categoryList = results[0] as List<CategoryModel>;
    final available = categoryList
        .where((cat) => cat.categoryId != widget.sourceCategory.categoryId)
        .toList()
      ..sort((a, b) => thaiSortKey(a.name).compareTo(thaiSortKey(b.name)));
    _categories.assignAll(available);

    final productResult = results[1];
    final loadedProducts = <ProductResponse>[];
    if (productResult is ProductPagedResponse) {
      loadedProducts.addAll(productResult.items);
    } else if (productResult is List<ProductResponse>) {
      loadedProducts.addAll(productResult);
    }
    loadedProducts.sort(
      (a, b) => thaiSortKey(a.name).compareTo(thaiSortKey(b.name)),
    );
    _products.assignAll(loadedProducts);
    _selectedProductIds.addAll(
      loadedProducts
          .where((p) => p.productId != null)
          .map((p) => p.productId!),
    );

    _isLoading.value = false;
  }

  void _toggleSelectAll(bool selectAll) {
    if (selectAll) {
      _selectedProductIds.addAll(
        _products
            .where((p) => p.productId != null)
            .map((p) => p.productId!),
      );
    } else {
      _selectedProductIds.clear();
    }
  }

  Future<void> _moveProducts() async {
    final destination = _selectedCategory.value;
    if (destination == null) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณาเลือกหมวดหมู่ปลายทาง",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    if (_selectedProductIds.isEmpty) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณาเลือกสินค้าที่ต้องการย้าย",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    _isSaving.value = true;
    try {
      final moveResult = await ApiProduct.moveCategoryProducts(
        fromCategoryId: widget.sourceCategory.categoryId,
        toCategoryId: destination.categoryId,
        shopId: _shopId,
        productIds: _selectedProductIds.toList(),
      );
      if (moveResult['success'] != true) {
        throw Exception(moveResult['error'] ?? "ย้ายสินค้าไม่สำเร็จ");
      }

      final movedCount =
          moveResult['data']?['moved_count'] ?? _selectedProductIds.length;
      final shouldDisable = await _showPostMoveDialog(movedCount);
      if (shouldDisable == true) {
        final disableResult = await ApiProduct.deleteCategory(
          categoryId: widget.sourceCategory.categoryId,
          shopId: _shopId,
        );
        if (disableResult['success'] != true) {
          throw Exception(
            disableResult['error'] ?? "ปิดใช้งานหมวดหมู่ไม่สำเร็จ",
          );
        }
        Get.back(result: true);
        Get.snackbar(
          "ย้ายและปิดใช้งานแล้ว",
          "ย้ายสินค้าไปที่ ${destination.name} และปิดใช้งานหมวดหมู่เดิมแล้ว",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      } else {
        Get.back(result: true);
        Get.snackbar(
          "ย้ายสินค้าสำเร็จ",
          "ย้ายสินค้า $movedCount รายการไปที่ ${destination.name} แล้ว",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      Get.snackbar(
        "ผิดพลาด",
        "$e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isSaving.value = false;
    }
  }

  Future<bool?> _showPostMoveDialog(int movedCount) {
    return Get.dialog<bool>(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "ย้ายสินค้าสำเร็จ",
                style: GoogleFonts.prompt(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "ย้ายสินค้า $movedCount รายการแล้ว\nต้องการปิดใช้งานหมวดหมู่นี้เลยไหม?",
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
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: Text("ยังไม่ปิด", style: GoogleFonts.prompt()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: true),
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
                        "ปิดใช้งานเลย",
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
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: Text(
          "ย้ายสินค้าออกจากหมวดหมู่",
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Obx(() {
        if (_isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: _kPrimaryColor),
          );
        }

        final allSelected = _products.isNotEmpty &&
            _selectedProductIds.length ==
                _products.where((p) => p.productId != null).length;

        return Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "จาก: ${widget.sourceCategory.name}",
                    style: GoogleFonts.prompt(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "ย้ายไปที่:",
                    style: GoogleFonts.prompt(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<CategoryModel>(
                    value: _selectedCategory.value,
                    decoration: InputDecoration(
                      hintText: "เลือกหมวดหมู่",
                      hintStyle: GoogleFonts.prompt(color: Colors.grey[500]),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    isExpanded: true,
                    items: _categories
                        .map(
                          (cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(
                              cat.name,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.prompt(),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _categories.isEmpty
                        ? null
                        : (value) => _selectedCategory.value = value,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Text(
                    "สินค้าในหมวดนี้",
                    style: GoogleFonts.prompt(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _products.isEmpty
                        ? null
                        : () => _toggleSelectAll(!allSelected),
                    child: Text(
                      allSelected ? "ยกเลิกทั้งหมด" : "เลือกทั้งหมด",
                      style: GoogleFonts.prompt(
                        color: _kPrimaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _products.isEmpty
                  ? Center(
                      child: Text(
                        "ไม่พบสินค้าในหมวดหมู่นี้",
                        style: GoogleFonts.prompt(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        final productId = product.productId;
                        if (productId == null) return const SizedBox.shrink();
                        final isSelected =
                            _selectedProductIds.contains(productId);

                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          child: CheckboxListTile(
                            value: isSelected,
                            activeColor: _kPrimaryColor,
                            onChanged: (checked) {
                              if (checked == true) {
                                _selectedProductIds.add(productId);
                              } else {
                                _selectedProductIds.remove(productId);
                              }
                            },
                            title: Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.prompt(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: product.barcode != null &&
                                    product.barcode!.isNotEmpty
                                ? Text(
                                    product.barcode!,
                                    style: GoogleFonts.prompt(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  )
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving.value ||
                            _categories.isEmpty ||
                            _selectedProductIds.isEmpty
                        ? null
                        : _moveProducts,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSaving.value
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            "ย้ายสินค้า ${_selectedProductIds.length} รายการ",
                            style: GoogleFonts.prompt(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
