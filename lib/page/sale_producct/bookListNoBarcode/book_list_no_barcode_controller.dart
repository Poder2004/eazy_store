import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/model/response/product_response.dart';
import 'package:eazy_store/page/sale_producct/sale/checkout_controller.dart';
import 'package:eazy_store/page/sale_producct/sale/checkout_page.dart';

// 🛒 Import ตัว Model กลางมาใช้ เพื่อให้เป็น Type เดียวกับในตะกร้า
import 'package:eazy_store/model/request/baskets_model.dart';

class ManualListController extends GetxController {
  var isLoading = true.obs;

  // แยกเป็น 2 ชุดตามแท็บ: ไม่มีบาร์โค้ด / มีบาร์โค้ด
  var allNoBarcode = <ProductItem>[].obs;
  var allHasBarcode = <ProductItem>[].obs;
  var filteredNoBarcode = <ProductItem>[].obs;
  var filteredHasBarcode = <ProductItem>[].obs;

  // 0 = ไม่มีบาร์โค้ด (ดีฟอลต์), 1 = มีบาร์โค้ด
  var activeTab = 0.obs;

  List<ProductItem> get currentFilteredList =>
      activeTab.value == 0 ? filteredNoBarcode : filteredHasBarcode;

  // เก็บสถานะการเลือกแยกไว้ (เพราะ ProductItem ใน basket ไม่มี isSelected)
  var selectedIds = <String>{}.obs;

  var categories = <String>["หมวดหมู่"].obs;
  var searchQuery = "".obs;
  var selectedCategory = "หมวดหมู่".obs;
  var categoryMap = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchInitialData();
    ever(selectedCategory, (String categoryName) {
      int? categoryId = categoryMap[categoryName];
      refreshProducts(categoryId);
    });
    // ค้นหาใช้ค่าเดียวกัน กรองทั้ง 2 แท็บพร้อมกัน สลับแท็บแล้วคำค้นหาเดิมยังอยู่
    debounce(searchQuery, (_) => filterProducts(), time: 300.milliseconds);
  }

  Future<void> fetchInitialData() async {
    try {
      isLoading(true);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? storedShopId = prefs.getInt('shopId');
      await Future.wait([fetchCategories(), fetchProducts(storedShopId ?? 1)]);
    } catch (e) {
      print("Initial Data Error: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchCategories() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;
      var categoryData = await ApiProduct.getCategories(shopId);
      // Remove duplicates by categoryId
      final seen = <int>{};
      final uniqueList = categoryData.where((cat) => seen.add(cat.categoryId)).toList();
      if (uniqueList.isNotEmpty) {
        categoryMap.clear();
        categories.value = ["หมวดหมู่"];
        for (var c in uniqueList) {
          final name = c.name.toString().trim();
          categories.add(name);
          categoryMap[name] = c.categoryId;
        }
      }
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  // ดึงสินค้าทั้ง 2 แท็บพร้อมกัน (ไม่มีบาร์โค้ด + มีบาร์โค้ด) ตามหมวดหมู่ที่เลือก
  Future<void> fetchProducts(int shopId, {int? categoryId}) async {
    try {
      final noBarcodeData = await ApiProduct.getNullBarcodeProducts(
        shopId,
        categoryId: categoryId,
      );
      allNoBarcode.assignAll(_mapRawToProducts(noBarcodeData));

      var result = await ApiProduct.getProductsByShop(
        shopId,
        categoryId: categoryId,
        limit: 100000,
      );
      List<ProductResponse> list = [];
      if (result is ProductPagedResponse) {
        list = result.items;
      } else if (result is List<ProductResponse>) {
        list = result;
      }
      allHasBarcode.assignAll(_mapResponsesToProducts(list));

      filterProducts();
    } catch (e) {
      print("Fetch Products Error: $e");
    }
  }

  Future<void> refreshProducts(int? categoryId) async {
    try {
      isLoading(true);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 1;
      await fetchProducts(shopId, categoryId: categoryId);
    } catch (e) {
      print("Refresh Products Error: $e");
    } finally {
      isLoading(false);
    }
  }

  List<ProductItem> _mapRawToProducts(List<dynamic> data) {
    return data.where((item) => item['status'] == true).map((item) {
      return ProductItem(
        id: (item['product_id'] ?? item['id'] ?? "").toString(),
        name: item['name'] ?? "ไม่มีชื่อสินค้า",
        price: double.tryParse(item['sell_price']?.toString() ?? "0") ?? 0.0,
        category: (item['category_name'] ?? "อื่นๆ").toString().trim(),
        imagePath: item['img_product'] ?? item['image'] ?? "",
        maxStock: item['stock'] ?? 999,
      );
    }).toList();
  }

  List<ProductItem> _mapResponsesToProducts(List<ProductResponse> list) {
    return list
        .where((p) => p.status == true && (p.barcode?.isNotEmpty ?? false))
        .map(
          (p) => ProductItem(
            id: (p.productId ?? 0).toString(),
            name: p.name,
            price: p.sellPrice,
            category: (p.categoryName ?? "อื่นๆ").trim(),
            imagePath: p.imgProduct,
            maxStock: p.stock,
            barcode: p.barcode,
          ),
        )
        .toList();
  }

  void filterProducts() {
    final q = searchQuery.value.trim().toLowerCase();
    filteredNoBarcode.assignAll(
      allNoBarcode.where((p) => p.name.toLowerCase().contains(q)).toList(),
    );
    filteredHasBarcode.assignAll(
      allHasBarcode.where((p) {
        return p.name.toLowerCase().contains(q) ||
            (p.barcode?.toLowerCase().contains(q) ?? false);
      }).toList(),
    );
  }

  // ปรับการ Toggle โดยเช็คจาก ID
  void toggleSelection(String id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }
  }

  Future<void> goToCheckout() async {
    if (selectedIds.isEmpty) {
      Get.snackbar(
        "แจ้งเตือน",
        "กรุณาเลือกสินค้าอย่างน้อย 1 ชิ้น",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final List<String> idsToSend = selectedIds.toList();

    if (Get.isRegistered<CheckoutController>()) {
      final checkoutCtrl = Get.find<CheckoutController>();

      // ✅ await เพื่อรอให้เพิ่มสินค้าลงตะกร้าจริงๆ ก่อนแสดง snackbar
      final int addedCount = await checkoutCtrl.addItemsByIds(idsToSend);

      // อัปเดต Nav Index เพื่อให้ Tab Bar แสดงสีแดงที่เมนูขาย (Index 2)
      checkoutCtrl.currentNavIndex.value = 2;

      // ล้างค่าที่เลือกไว้เพื่อให้กลับมาเลือกใหม่ได้สะอาดๆ
      selectedIds.clear();

      if (addedCount > 0) {
        Get.snackbar(
          "สำเร็จ",
          "เพิ่มสินค้า $addedCount รายการลงตะกร้าแล้ว",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 1),
        );
      } else {
        Get.snackbar(
          "ไม่สามารถเพิ่มได้",
          "สินค้าที่เลือกอาจหมดสต็อก หรือไม่พบในระบบ",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        return; // ไม่เปลี่ยนหน้าถ้าไม่มีสินค้าถูกเพิ่มเลย
      }

      // จัดการหน้าจอ
      if (Get.previousRoute.contains('CheckoutPage')) {
        Get.back();
      } else {
        Get.to(() => const CheckoutPage());
      }
    } else {
      // กรณีเปิดแอปมาแล้วเข้าหน้านี้เลยโดยไม่มี CheckoutController (กันพลาด)
      selectedIds.clear();
      Get.offAll(
        () => const CheckoutPage(),
        arguments: {'selectedIds': idsToSend},
      );
    }
  }
}
