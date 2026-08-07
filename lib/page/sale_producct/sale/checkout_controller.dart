// ไฟล์: lib/sale_producct/checkout_controller.dart
import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/api/api_shop.dart';
import 'package:eazy_store/api/api_sale.dart';
import 'package:eazy_store/model/request/baskets_model.dart';
import 'package:eazy_store/model/response/debtor_response.dart';
import 'package:eazy_store/model/response/product_response.dart';
import 'package:eazy_store/model/request/sales_model_request.dart';
import 'package:eazy_store/page/debt/debtRegister/debt_register.dart';
import 'package:eazy_store/page/debt/debtSale/debt_sale.dart';
import 'package:eazy_store/page/sale_producct/sale/park_order_controller.dart';
import 'package:eazy_store/page/sale_producct/scanBarcode/scan_barcode.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eazy_store/model/response/shop_response.dart';

class CheckoutController extends GetxController {
  // 🛒 ตะกร้าสินค้า
  var cartItems = <ProductItem>[].obs;

  // 🔍 คลังสินค้า
  var allProducts = <ProductResponse>[];
  var searchResults = <ProductResponse>[].obs;
  // isSearching = มีคำค้นหาอยู่ในช่องไหม (คุมว่าจะโชว์หน้าค้นหาหรือหน้าตะกร้า)
  // isSearchLoading = กำลังยิง request ค้นหาอยู่ไหม (คุมแค่ spinner)
  // ต้องแยกกันเพราะเดิมใช้ตัวเดียวกัน พอค้นหาเสร็จ (ไม่ว่าจะเจอหรือไม่เจอ) จะถูกเซ็ตเป็น
  // false ทันที ทำให้หน้าค้นหาหลุดกลับไปเป็นหน้าตะกร้าทั้งที่ยังมีคำค้นหาค้างอยู่ในช่อง
  var isSearching = false.obs;
  var isSearchLoading = false.obs;

  // 💰 การชำระเงิน
  var isDebtMode = false.obs;
  var isProcessingPayment = false.obs;
  var paymentMethod = "จ่ายเงินสด".obs;
  final receivedAmountController = TextEditingController();

  /// หน้า CheckoutPage เป็นคนกำหนดให้ ใช้เปิดแผ่นจ่ายเงินสดจากหน้าอื่น
  void Function(BuildContext context)? openCashPaymentSheet;
  final noteController = TextEditingController();
  var changeAmount = 0.0.obs;
  var shopQrCodeUrl = "".obs;

  // 📝 ข้อมูลอื่นๆ
  final debtorNameController = TextEditingController();
  final payAmountController = TextEditingController(text: "0");
  final debtRemarkController = TextEditingController();
  final searchController = TextEditingController();
  var currentNavIndex = 2.obs;

  int? loadedShopId;

  @override
  void onInit() {
    super.onInit();
    checkShopAndLoadData();

    receivedAmountController.addListener(() {
      double received = double.tryParse(receivedAmountController.text) ?? 0;
      if (received >= totalPriceRounded) {
        changeAmount.value = received - totalPriceRounded;
      } else {
        changeAmount.value = 0.0;
      }
    });

    if (Get.arguments != null && Get.arguments is Map) {
      String? barcode = Get.arguments['barcode'];
      if (barcode != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          addProductByBarcode(barcode);
        });
      }
    }
    if (Get.arguments != null && Get.arguments is Map) {
      var ids = Get.arguments['selectedIds'];
      if (ids != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (allProducts.isEmpty) {
            await _loadAllProducts();
          }
          addItemsByIds(List<String>.from(ids));
        });
      }
    }
  }

  @override
  void onReady() {
    super.onReady();
    checkShopAndLoadData();
  }

  Future<void> checkShopAndLoadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int currentShopId = prefs.getInt('shopId') ?? 0;

    // ✅ ซิงค์ร้านปัจจุบันให้ ParkOrderController เสมอ (คอนโทรลเลอร์นี้เป็น permanent
    // singleton อยู่ข้ามการสลับร้าน) กันออเดอร์ที่พักไว้ของร้านอื่นรั่วมาโชว์/กู้คืนข้ามร้าน
    _parkCtrl.currentShopId.value = currentShopId;

    if (loadedShopId != currentShopId) {
      print(
        "♻️ ร้านค้าเปลี่ยน ($loadedShopId -> $currentShopId) กำลังรีเซ็ตข้อมูล...",
      );

      allProducts.clear();
      cartItems.clear();
      searchResults.clear();
      receivedAmountController.clear();
      changeAmount.value = 0.0;
      shopQrCodeUrl.value = "";

      loadedShopId = currentShopId;

      await _loadAllProducts();
      await _fetchShopData();
    }
  }

  Future<List<ProductResponse>> _fetchProductsFromApi(int shopId) async {
    List<ProductResponse> allFetched = [];
    try {
      var response = await ApiProduct.getProductsByShop(shopId, limit: 1000);
      List<ProductResponse> list = [];
      if (response is List<ProductResponse>) {
        list = response;
      } else if (response is ProductPagedResponse) {
        list = response.items;
      }
      allFetched.addAll(list.where((p) => p.status == true));
    } catch (e) {
      print("❌ Error loading products by shop: $e");
    }

    try {
      final nullBarcodeData = await ApiProduct.getNullBarcodeProducts(shopId);
      final List<ProductResponse> nullBarcodeList = nullBarcodeData.map((item) {
        return ProductResponse(
          productId: int.tryParse(item['product_id']?.toString() ?? item['id']?.toString() ?? ""),
          shopId: shopId,
          categoryId: int.tryParse(item['category_id']?.toString() ?? "") ?? 0,
          productCode: item['product_code']?.toString(),
          name: item['name'] ?? '',
          barcode: item['barcode']?.toString(),
          imgProduct: item['img_product'] ?? item['image'] ?? '',
          sellPrice: double.tryParse(item['sell_price']?.toString() ?? "0") ?? 0.0,
          costPrice: double.tryParse(item['cost_price']?.toString() ?? "0") ?? 0.0,
          stock: int.tryParse(item['stock']?.toString() ?? "") ?? 999,
          unit: item['unit'] ?? '',
          status: item['status'] == true || item['status'] == 1 || item['status']?.toString().toLowerCase() == 'true',
          categoryName: item['category_name']?.toString().trim(),
        );
      }).toList();

      for (var p in nullBarcodeList) {
        if (p.status == true && !allFetched.any((existing) => existing.productId == p.productId)) {
          allFetched.add(p);
        }
      }
    } catch (e) {
      print("❌ Error loading null barcode products: $e");
    }

    return allFetched;
  }

  Future<void> fetchFreshProducts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;

      if (shopId != 0) {
        allProducts = await _fetchProductsFromApi(shopId);
        if (searchController.text.isNotEmpty) {
          onSearchChanged(searchController.text);
        }
        await _fetchShopData(); // ✅ รีเฟรช QR Code ทุกครั้งที่เปิดหน้า
      }
    } catch (e) {
      print("❌ Error fetching fresh products: $e");
    }
  }

  Future<void> _loadAllProducts() async {
    try {
      if (loadedShopId != null && loadedShopId != 0) {
        allProducts = await _fetchProductsFromApi(loadedShopId!);
        print("✅ โหลดสินค้าสำเร็จทั้งหมด: ${allProducts.length} รายการ (รวมไม่มีบาร์โค้ด)");
      }
    } catch (e) {
      print("❌ Error loading products: $e");
    }
  }

  Future<void> _fetchShopData() async {
    try {
      ShopResponse? shop = await ApiShop().getCurrentShop();
      if (shop != null && shop.imgQrcode.isNotEmpty) {
        // ✅ แนบ timestamp เพื่อล้างแคชรูปภาพเก่า (Prevent caching)
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final url = shop.imgQrcode;
        shopQrCodeUrl.value = url + (url.contains('?') ? '&' : '?') + 't=$timestamp';
      }
    } catch (e) {
      print("Error loading shop data: $e");
    }
  }

  // ป้องกัน race condition: ทุกครั้งที่พิมพ์จะยิง onSearchChanged ใหม่แบบ async
  // ถ้าคำค้นหาเก่า (เช่น "a") ยิง API ช้ากว่าคำค้นหาใหม่ (เช่น "ab") ที่หาเจอจาก local
  // cache แล้วเสร็จก่อน ผลลัพธ์เก่าที่มาทีหลังจะทับผลลัพธ์ใหม่ทำให้รายการที่เพิ่งขึ้น
  // หายไปเฉยๆ (ยิ่งตะกร้าใหญ่ยิ่ง jank ทำให้พิมพ์ติดกันถี่ๆ จนโดนชนกันง่ายขึ้น)
  // แก้โดยให้ทุก request มีเลขกำกับ (_searchRequestId) แล้วเช็คก่อน apply ผลทุกจุดว่า
  // ยังเป็น request ล่าสุดอยู่ไหม ถ้าไม่ใช่ (มี request ใหม่กว่าแซงไปแล้ว) ก็ทิ้งผลนั้น
  int _searchRequestId = 0;

  void onSearchChanged(String query) async {
    if (query.isEmpty) {
      _searchRequestId++;
      isSearching.value = false;
      isSearchLoading.value = false;
      searchResults.clear();
      return;
    }

    final int requestId = ++_searchRequestId;
    isSearching.value = true;
    isSearchLoading.value = true;

    // ✅ ครอบทั้งฟังก์ชันด้วย try/finally กัน isSearchLoading ค้างเป็น true ตลอดกาล
    // (เดิมถ้าเจอใน local cache หรือค้นหาไม่เจอเลย จะไม่มีจุดไหนตั้งกลับเป็น false
    // ทำให้จอค้างเป็น spinner ไม่มีทางรู้ว่าค้นหาจบแล้ว)
    try {
      // 🔍 ค้นหาจาก local cache ก่อนเสมอ เพื่อแสดงผลหลายรายการทันที
      final localMatches = allProducts.where((p) {
        return p.name.toLowerCase().contains(query.toLowerCase()) ||
            (p.barcode != null &&
                p.barcode!.toLowerCase().contains(query.toLowerCase()));
      }).toList();

      if (localMatches.isNotEmpty) {
        if (requestId != _searchRequestId) return; // มี request ใหม่กว่าแซงไปแล้ว
        searchResults.assignAll(localMatches);
        return;
      }

      // 🌐 ไม่พบใน local → fallback ไป API (เช่น สแกนบาร์โค้ดสินค้าใหม่)
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int currentShopId = prefs.getInt('shopId') ?? 0;

      ProductResponse? product = await ApiProduct.searchProduct(
        query,
        currentShopId,
      );

      if (requestId != _searchRequestId) return; // มี request ใหม่กว่าแซงไปแล้ว

      if (product != null && product.status == true) {
        searchResults.assignAll([product]);
      } else {
        searchResults.clear();
      }
    } catch (e) {
      print("Search API Error: $e");
      if (requestId == _searchRequestId) searchResults.clear();
    } finally {
      if (requestId == _searchRequestId) isSearchLoading.value = false;
    }
  }

  void selectProductToAdd(ProductResponse product) {
    _addToCart(product);
    searchController.clear();
    isSearching.value = false;
    searchResults.clear();
    FocusManager.instance.primaryFocus?.unfocus();
    fetchFreshProducts();
  }

  Future<void> openInternalScanner() async {
    var result = await Get.to(() => const ScanBarcodePage(showBookButton: true));
    if (result != null && result is String) {
      await addProductByBarcode(result);
    }
  }

  Future<void> addProductByBarcode(String barcode) async {
    await checkShopAndLoadData();
    if (allProducts.isEmpty) {
      await _loadAllProducts();
    }
    var match = allProducts.firstWhereOrNull((p) => p.barcode == barcode);
    if (match != null) {
      _addToCart(match);
    } else {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        int currentShopId = prefs.getInt('shopId') ?? 0;
        ProductResponse? product = await ApiProduct.searchProduct(
          barcode,
          currentShopId,
        );
        Get.back();
        if (product != null) {
          _addToCart(product);
          allProducts.add(product);
        } else {
          _showWarningDialog(
            "ไม่พบสินค้า",
            "รหัสบาร์โค้ดนี้ไม่มีในระบบของร้านค้า",
          );
        }
      } catch (e) {
        Get.back();
        _showWarningDialog("เกิดข้อผิดพลาด", "ไม่สามารถค้นหาสินค้าได้ กรุณาลองใหม่");
      }
    }
  }

  Future<int> addItemsByIds(List<String> productIds) async {
    if (allProducts.isEmpty) {
      await _loadAllProducts();
    }

    int addedCount = 0;
    for (var id in productIds) {
      var match = allProducts.firstWhereOrNull(
        (p) => p.productId.toString() == id,
      );
      if (match != null) {
        final beforeCount = cartItems.length;
        _addToCart(match);
        // นับเฉพาะที่เพิ่มสำเร็จจริงๆ (stock ไม่หมด)
        if (cartItems.length > beforeCount) addedCount++;
      }
    }
    return addedCount;
  }

  void _addToCart(ProductResponse product) {
    int currentQty = cartItems
        .where((item) => item.id == product.productId.toString())
        .length;
    if (currentQty < product.stock) {
      cartItems.add(
        ProductItem(
          id: product.productId.toString(),
          name: product.name,
          price: product.sellPrice,
          category: product.categoryName ?? 'ทั่วไป',
          imagePath: product.imgProduct,
          maxStock: product.stock,
          unit: product.unit.isNotEmpty ? product.unit : 'ชิ้น',
        ),
      );
    } else {
      Get.snackbar(
        "ถึงจำนวนสูงสุดแล้ว",
        "สินค้านี้มีในสต็อก ${product.stock} ชิ้น ไม่สามารถเพิ่มได้อีก",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  // เอาสต็อกปัจจุบันจาก allProducts (รีเฟรชแล้วตอนเปิดหน้า) แทนค่า snapshot เดิม
  // ที่ติดมากับตะกร้า กันขายเกินสต็อกจริงถ้าสต็อกลดลงหลังหยิบใส่ตะกร้าไปแล้ว
  int _currentMaxStock(ProductItem item) {
    final match = allProducts.firstWhereOrNull(
      (p) => p.productId.toString() == item.id,
    );
    return match?.stock ?? item.maxStock;
  }

  void increaseItem(ProductItem item) {
    final int maxStock = _currentMaxStock(item);
    int currentQty = cartItems.where((i) => i.id == item.id).length;
    if (currentQty < maxStock) {
      cartItems.add(
        ProductItem(
          id: item.id,
          name: item.name,
          price: item.price,
          category: item.category,
          imagePath: item.imagePath,
          maxStock: maxStock,
          unit: item.unit,
        ),
      );
    } else {
      Get.snackbar(
        "แจ้งเตือน",
        "สินค้ามีจำกัด",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 1),
      );
    }
  }

  void decreaseItem(ProductItem item) {
    int index = cartItems.indexWhere((e) => e.id == item.id);
    if (index != -1) cartItems.removeAt(index);
  }

  // ✨ ตั้งจำนวนสินค้าโดยตรง (ใช้ตอนพิมพ์จำนวนเอง แทนการกด +/- ทีละครั้ง)
  void setItemQuantity(ProductItem item, int newQty) {
    final int maxStock = _currentMaxStock(item);
    final clamped = newQty.clamp(0, maxStock);
    final currentQty = cartItems.where((i) => i.id == item.id).length;

    if (clamped == currentQty) return;

    if (clamped == 0) {
      cartItems.removeWhere((i) => i.id == item.id);
      return;
    }

    if (clamped > currentQty) {
      final toAdd = clamped - currentQty;
      cartItems.addAll(
        List.generate(
          toAdd,
          (_) => ProductItem(
            id: item.id,
            name: item.name,
            price: item.price,
            category: item.category,
            imagePath: item.imagePath,
            maxStock: maxStock,
            unit: item.unit,
          ),
        ),
      );
    } else {
      var toRemove = currentQty - clamped;
      for (int i = cartItems.length - 1; i >= 0 && toRemove > 0; i--) {
        if (cartItems[i].id == item.id) {
          cartItems.removeAt(i);
          toRemove--;
        }
      }
    }
  }

  void removeItem(ProductItem item) =>
      cartItems.removeWhere((e) => e.id == item.id);

  void toggleDelete(ProductItem item) {
    for (var i in cartItems) i.showDelete.value = false;
    item.showDelete.value = !item.showDelete.value;
  }

  void clearAll() => cartItems.clear();

  ParkOrderController get _parkCtrl => Get.find<ParkOrderController>();

  void parkOrder() {
    if (cartItems.isEmpty) {
      Get.snackbar(
        'แจ้งเตือน',
        'ตะกร้าว่างเปล่า ไม่มีออเดอร์ที่จะพัก',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    _parkCtrl.parkCurrentOrder(cartItems.toList());
    clearAll();
    noteController.clear();
    receivedAmountController.clear();
    Get.snackbar(
      'พักออเดอร์แล้ว',
      'เริ่มออเดอร์ใหม่ได้เลย',
      backgroundColor: const Color(0xFFF59E0B),
      colorText: Colors.white,
      duration: const Duration(seconds: 1),
    );
  }

  Future<void> resumeOrder(String parkId) async {
    // ✅ เช็คว่าเจอออเดอร์ที่พักไว้จริงก่อน ค่อยล้างตะกร้าปัจจุบัน
    // (เดิมล้างตะกร้าไปก่อนแล้วค่อยเช็ค ถ้าไม่เจอออเดอร์ที่พักไว้จะเสียของในตะกร้าปัจจุบันไปฟรีๆ)
    final parked = _parkCtrl.retrieveOrder(parkId);
    if (parked == null) return;

    if (cartItems.isNotEmpty) {
      _parkCtrl.parkCurrentOrder(cartItems.toList());
    }
    clearAll();
    noteController.clear();
    receivedAmountController.clear();
    changeAmount.value = 0.0;

    if (allProducts.isEmpty) await _loadAllProducts();

    bool stockReduced = false;
    for (final pi in parked.items) {
      final match = allProducts.firstWhereOrNull(
        (p) => p.productId.toString() == pi.id,
      );
      final effectiveMaxStock = match?.stock ?? pi.maxStock;
      final qty = pi.quantity.clamp(0, effectiveMaxStock);
      if (qty < pi.quantity) stockReduced = true;
      for (int i = 0; i < qty; i++) {
        cartItems.add(ProductItem(
          id: pi.id,
          name: pi.name,
          price: pi.price,
          category: pi.category,
          imagePath: pi.imagePath,
          maxStock: effectiveMaxStock,
          unit: pi.unit,
        ));
      }
    }

    // ✅ แจ้งเตือนถ้าสต็อกลดลงระหว่างที่พักออเดอร์ไว้ จนต้องปรับจำนวนลง
    // (เดิมปรับลดเงียบๆ แคชเชียร์ไม่รู้ว่าจำนวนที่กู้กลับมาน้อยกว่าที่พักไว้จริง)
    if (stockReduced) {
      Get.snackbar(
        'สต็อกไม่พอ',
        'สินค้าบางรายการมีสต็อกลดลงตั้งแต่พักออเดอร์ไว้ ระบบปรับจำนวนในตะกร้าให้อัตโนมัติแล้ว กรุณาตรวจสอบก่อนขาย',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  double get totalPrice => cartItems.fold(0, (sum, item) => sum + item.price);

  // ยอดที่ปัดเป็นจำนวนเต็มบาท ใช้แสดงผลและเช็คยอดเงินรับมา
  // ให้ตรงกับตัวเลขที่แคชเชียร์เห็นบนจอ (ไม่ตัดเศษทิ้งแบบ .toInt() ที่ทำให้เช็คยอดผิด)
  int get totalPriceRounded => totalPrice.round();

  void openPaymentSheet(
    BuildContext context,
    bool initialDebtMode,
    Widget paymentSheet,
  ) {
    if (cartItems.isEmpty) {
      Get.snackbar(
        "แจ้งเตือน",
        "ตะกร้าว่างเปล่า กรุณาเพิ่มสินค้า",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    isDebtMode.value = initialDebtMode;
    paymentMethod.value = "จ่ายเงินสด";
    if (!initialDebtMode) {
      receivedAmountController.clear();
      changeAmount.value = 0.0;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => paymentSheet,
    );
  }

  void goToDebtPaymentPage() {
    Get.to(() => DebtSalePage());
  }

  // ✅ ฟังก์ชันแสดง Popup ยืนยันการชำระเงินที่แก้ UI ให้ยืดหยุ่นรองรับฟอนต์ใหญ่แล้ว
  void confirmPayment(VoidCallback processPaymentFunc) {
    if (cartItems.isEmpty) {
      _showWarningDialog("ตะกร้าว่าง", "กรุณาเลือกสินค้าก่อนทำรายการ");
      return;
    }

    double received = double.tryParse(receivedAmountController.text) ?? 0;

    // เช็คยอดเงินรับมาเฉพาะเงินสด (เทียบกับยอดปัดเต็มบาทที่แสดงบนจอ ไม่ใช่ค่าทศนิยมเป๊ะๆ)
    if (paymentMethod.value == "จ่ายเงินสด" && received < totalPriceRounded) {
      _showWarningDialog(
        "ยอดเงินไม่พอ",
        "จำนวนเงินที่รับมาน้อยกว่าราคาสินค้ารวม",
      );
      return;
    }

    Get.dialog(
      // ✨ 1. คุม Font Scale ให้ใหญ่สุด 1.2 ไม่ให้ทะลุกรอบป๊อปอัป
      MediaQuery(
        data: MediaQuery.of(Get.context!).copyWith(
          textScaler: MediaQuery.textScalerOf(
            Get.context!,
          ).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.2),
        ),
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400), // จำกัดความกว้าง
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // ทำให้กล่องพอดีเนื้อหา
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: Colors.blue,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "ยืนยันการทำรายการ",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      // ✨ 2. ใช้ Expanded เพื่อให้ข้อความตัดขึ้นบรรทัดใหม่ได้ถ้าฟอนต์ใหญ่
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "จำนวนรายการ:",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "${cartItems.length} ชิ้น",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "วิธีชำระเงิน:",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              paymentMethod.value,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 25, thickness: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "ยอดสุทธิ:",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // ✨ 3. หุ้มด้วย FittedBox ป้องกันตัวเลขยอดเงินแหว่งทะลุจอ
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "$totalPriceRounded ฿",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        // ✨ 4. หุ้มด้วย FittedBox ป้องกันปุ่มเบียดกัน
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "กลับไปแก้ไข",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                          processPaymentFunc(); // เรียกใช้ฟังก์ชันจ่ายเงิน
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C853),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "ยืนยัน",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // ✅ ฟังก์ชันยิง API บันทึกการขาย
  Future<void> processPayment() async {
    if (isProcessingPayment.value) return;
    isProcessingPayment.value = true;

    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;

      if (shopId == 0) {
        Get.back();
        _showErrorDialog("ผิดพลาด", "ไม่พบข้อมูลร้านค้า กรุณาล็อกอินใหม่");
        return;
      }

      double received = double.tryParse(receivedAmountController.text) ?? 0;

      String userName = prefs.getString('username') ?? "พนักงานขาย";

      final Map<int, SaleItemRequest> groupedItems = {};
      for (var item in cartItems) {
        int productId = int.parse(item.id);
        if (groupedItems.containsKey(productId)) {
          var existingItem = groupedItems[productId]!;
          // รวมราคาจริงของทุกชิ้น ไม่ใช้ราคาชิ้นล่าสุดคูณจำนวน เผื่อราคาสินค้าเดียวกัน
          // เปลี่ยนกลางทางขณะที่ตะกร้ายังมีของราคาเก่าค้างอยู่
          final int newAmount = existingItem.amount + 1;
          final double newTotal = existingItem.totalPrice + item.price;
          groupedItems[productId] = SaleItemRequest(
            productId: productId,
            amount: newAmount,
            pricePerUnit: newTotal / newAmount,
            totalPrice: newTotal,
          );
        } else {
          groupedItems[productId] = SaleItemRequest(
            productId: productId,
            amount: 1,
            pricePerUnit: item.price,
            totalPrice: item.price,
          );
        }
      }

      SaleRequest saleRequest = SaleRequest(
        shopId: shopId,
        debtorId: null,
        netPrice: totalPrice,
        pay: paymentMethod.value == "โอนจ่าย" ? totalPrice : received,
        paymentMethod: paymentMethod.value,
        note: noteController.text.isEmpty ? null : noteController.text,
        createdBuy: userName,
        saleItems: groupedItems.values.toList(),
      );

      final result = await ApiSale.createSale(saleRequest);
      Get.back();

      if (result != null && result.containsKey('sale_id')) {
        Get.back(); // ปิดหน้าชำระเงิน
        _showSuccessDialog("ชำระเงินสำเร็จ", "บันทึกข้อมูลการขายเรียบร้อยแล้ว");

        clearAll();
        noteController.clear();
        receivedAmountController.clear();
        await _loadAllProducts();
      } else {
        final errorMsg = result?['error'] ?? "ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ในขณะนี้";
        _showErrorDialog("เกิดข้อผิดพลาด", errorMsg);
      }
    } catch (e) {
      Get.back();
      _showErrorDialog("ข้อผิดพลาดระบบ", "พบปัญหา: ${e.toString()}");
    } finally {
      isProcessingPayment.value = false;
    }
  }

  /// เปิดหน้าสมัครบัญชีลูกหนี้ และคืนข้อมูลลูกหนี้ที่เพิ่งสมัคร (null = ยกเลิก/ไม่สำเร็จ)
  Future<DebtorResponse?> registerNewDebtor() async {
    final result = await Get.to(() => DebtRegisterScreen());
    return result is DebtorResponse ? result : null;
  }

  @override
  void onClose() {
    receivedAmountController.dispose();
    searchController.dispose();
    noteController.dispose();
    super.onClose();
  }

  void _showWarningDialog(String title, String message) {
    _buildStatusDialog(
      title,
      message,
      Colors.orange,
      Icons.warning_amber_rounded,
    );
  }

  void _showErrorDialog(String title, String message) {
    _buildStatusDialog(title, message, Colors.red, Icons.error_outline_rounded);
  }

  void _showSuccessDialog(String title, String message) {
    _buildStatusDialog(
      title,
      message,
      const Color(0xFF00C853),
      Icons.check_circle_outline_rounded,
    );
  }

  // ✨ จัดการ Dialog สถานะ (สำเร็จ/ผิดพลาด) ให้รองรับฟอนต์ใหญ่ด้วย
  void _buildStatusDialog(
    String title,
    String message,
    Color color,
    IconData icon,
  ) {
    Get.dialog(
      MediaQuery(
        data: MediaQuery.of(Get.context!).copyWith(
          textScaler: MediaQuery.textScalerOf(
            Get.context!,
          ).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.2),
        ),
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 60),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Get.back(),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "ตกลง",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
