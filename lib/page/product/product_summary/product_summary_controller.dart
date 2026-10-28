import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/model/response/product_response.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductSummaryController extends GetxController {
  final products = <ProductResponse>[].obs;
  final isLoading = true.obs;
  final errorMessage = RxnString();

  int get totalProducts => products.length;

  int get lowStockCount => products
      .where(
        (product) =>
            product.stock > 0 && product.stock <= product.lowStockThreshold,
      )
      .length;

  int get outOfStockCount =>
      products.where((product) => product.stock <= 0).length;

  List<ProductResponse> get lowStockProducts =>
      products
          .where(
            (product) =>
                product.stock > 0 && product.stock <= product.lowStockThreshold,
          )
          .toList()
        ..sort((a, b) => a.stock.compareTo(b.stock));

  List<ProductResponse> get outOfStockProducts =>
      products.where((product) => product.stock <= 0).toList();

  List<ProductResponse> productsInCategory(String categoryName) {
    return products.where((product) {
      final name = product.categoryName?.trim();
      final displayName = name == null || name.isEmpty
          ? 'ไม่ระบุหมวดหมู่'
          : name;
      return displayName == categoryName;
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  List<MapEntry<String, int>> get categoryCounts {
    final counts = <String, int>{};
    for (final product in products) {
      final categoryName = product.categoryName?.trim();
      final name = categoryName == null || categoryName.isEmpty
          ? 'ไม่ระบุหมวดหมู่'
          : categoryName;
      counts.update(name, (count) => count + 1, ifAbsent: () => 1);
    }

    return counts.entries.toList()..sort((a, b) {
      final countComparison = b.value.compareTo(a.value);
      return countComparison != 0 ? countComparison : a.key.compareTo(b.key);
    });
  }

  List<ProductResponse> get highestStockProducts {
    final stockedProducts =
        products.where((product) => product.stock > 0).toList()
          ..sort((a, b) => b.stock.compareTo(a.stock));
    return stockedProducts.take(5).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadSummary();
  }

  Future<void> loadSummary() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final shopId = prefs.getInt('shopId') ?? 0;
      if (shopId == 0) {
        throw Exception('ไม่พบร้านค้า กรุณาเลือกร้านค้าก่อน');
      }

      final result = await ApiProduct.getProductsByShop(
        shopId,
        page: 1,
        limit: 100,
      );

      final allProducts = <ProductResponse>[];
      if (result is ProductPagedResponse) {
        allProducts.addAll(result.items);
        for (var page = 2; page <= result.totalPages; page++) {
          final pageResult = await ApiProduct.getProductsByShop(
            shopId,
            page: page,
            limit: 100,
          );
          if (pageResult is! ProductPagedResponse) {
            throw Exception('ไม่สามารถโหลดข้อมูลสินค้าทั้งหมดได้');
          }
          allProducts.addAll(pageResult.items);
        }
      } else if (result is List<ProductResponse>) {
        allProducts.addAll(result);
      } else {
        throw Exception('ไม่สามารถโหลดข้อมูลสินค้าได้ กรุณาลองอีกครั้ง');
      }

      products.assignAll(
        allProducts.where((product) => product.status).toList(),
      );
    } catch (error) {
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }
}
