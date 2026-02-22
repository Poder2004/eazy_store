// ไฟล์: lib/sale_producct/checkout_controller.dart
import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/api/api_shop.dart';
import 'package:eazy_store/api/api_sale.dart';
import 'package:eazy_store/model/request/baskets_model.dart';
import 'package:eazy_store/model/request/product_model.dart';
import 'package:eazy_store/model/request/sales_model_request.dart';
import 'package:eazy_store/model/request/shop_model.dart';
import 'package:eazy_store/page/debt/debtRegister/debt_register.dart';
import 'package:eazy_store/page/debt/debt_sale.dart';
import 'package:eazy_store/sale_producct/scan_barcode.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckoutController extends GetxController {
  // 🛒 ตะกร้าสินค้า
  var cartItems = <ProductItem>[].obs;

  // 🔍 คลังสินค้า
  var allProducts = <Product>[];
  var searchResults = <Product>[].obs;
  var isSearching = false.obs;

  // 💰 การชำระเงิน
  var isDebtMode = false.obs;
  var paymentMethod = "จ่ายเงินสด".obs;
  final receivedAmountController = TextEditingController();
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
      if (received >= totalPrice) {
        changeAmount.value = received - totalPrice;
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

  Future<void> fetchFreshProducts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;

      if (shopId != 0) {
        // ดึงข้อมูลใหม่จาก API
        List<Product> list = await ApiProduct.getProductsByShop(shopId);

        // กรองเอาเฉพาะสินค้าที่ไม่ได้ถูกซ่อน (status == true) มาใส่ในหน่วยความจำใหม่
        allProducts = list.where((p) => p.status == true).toList();

        // ถ้าผู้ใช้พิมพ์ข้อความค้นหาค้างไว้ ให้มันอัปเดตผลลัพธ์ด้วย
        if (searchController.text.isNotEmpty) {
          onSearchChanged(searchController.text);
        }
      }
    } catch (e) {
      print("Error fetching fresh products: $e");
    }
  }

  Future<void> _loadAllProducts() async {
    try {
      if (loadedShopId != null && loadedShopId != 0) {
        List<Product> list = await ApiProduct.getProductsByShop(loadedShopId!);
        // 🔥 แก้ไขตรงนี้: กรองเอาเฉพาะสินค้าที่ status == true (ไม่ได้ถูกซ่อน) มาแสดงเท่านั้น
        allProducts = list.where((p) => p.status == true).toList();
      }
    } catch (e) {
      print("Error loading products: $e");
    }
  }

  Future<void> _fetchShopData() async {
    try {
      ShopModel? shop = await ApiShop.getCurrentShop();
      if (shop != null && shop.imgQrcode.isNotEmpty) {
        shopQrCodeUrl.value = shop.imgQrcode;
      }
    } catch (e) {
      print("Error loading shop data: $e");
    }
  }

  void onSearchChanged(String query) {
    if (query.isEmpty) {
      isSearching.value = false;
      searchResults.clear();
      return;
    }
    isSearching.value = true;
    searchResults.value = allProducts.where((p) {
      String name = p.name.toLowerCase();
      String barcode = (p.barcode ?? "").toLowerCase();
      String input = query.toLowerCase();
      return name.contains(input) || barcode.contains(input);
    }).toList();
  }

  void selectProductToAdd(Product product) {
    _addToCart(product);
    searchController.clear();
    isSearching.value = false;
    searchResults.clear();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> openInternalScanner() async {
    var result = await Get.to(() => const ScanBarcodePage());
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

        Product? product = await ApiProduct.searchProduct(
          barcode,
          currentShopId,
        );

        Get.back();

        if (product != null) {
          _addToCart(product);
          allProducts.add(product);
        } else {
          Get.snackbar(
            "ไม่พบสินค้า",
            "รหัส $barcode ไม่มีในร้านนี้",
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        }
      } catch (e) {
        Get.back();
      }
    }
  }

  Future<void> addItemsByIds(List<String> productIds) async {
    if (allProducts.isEmpty) {
      await _loadAllProducts();
    }

    for (var id in productIds) {
      var match = allProducts.firstWhereOrNull(
        (p) => p.productId.toString() == id,
      );
      if (match != null) {
        _addToCart(match);
      }
    }
    update();
  }

  void _addToCart(Product product) {
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
        ),
      );
    } else {
      Get.snackbar(
        "สินค้าหมด",
        "คงเหลือ ${product.stock} ชิ้น",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        duration: const Duration(seconds: 1),
      );
    }
  }

  void increaseItem(ProductItem item) {
    int currentQty = cartItems.where((i) => i.id == item.id).length;
    if (currentQty < item.maxStock) {
      cartItems.add(
        ProductItem(
          id: item.id,
          name: item.name,
          price: item.price,
          category: item.category,
          imagePath: item.imagePath,
          maxStock: item.maxStock,
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

  void removeItem(ProductItem item) =>
      cartItems.removeWhere((e) => e.id == item.id);

  void toggleDelete(ProductItem item) {
    for (var i in cartItems) i.showDelete.value = false;
    item.showDelete.value = !item.showDelete.value;
  }

  void clearAll() => cartItems.clear();

  double get totalPrice => cartItems.fold(0, (sum, item) => sum + item.price);

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
      builder: (context) => paymentSheet, // รับ Widget จาก View มาแสดง
    );
  }

  void goToDebtPaymentPage() {
    Get.to(() => const DebtSalePage());
  }

  // ✅ ฟังก์ชันแสดง Popup ยืนยันการชำระเงิน (ก่อนเรียก API)
  void confirmPayment(VoidCallback processPayment) {
    if (cartItems.isEmpty) return;

    double received = double.tryParse(receivedAmountController.text) ?? 0;

    // เช็คยอดเงินรับมาเฉพาะเงินสด
    if (paymentMethod.value == "จ่ายเงินสด" && received < totalPrice) {
      Get.snackbar(
        "แจ้งเตือน",
        "ยอดเงินที่รับมาไม่เพียงพอ",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // เปิด Dialog แบบสวยงาม
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
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
            mainAxisSize: MainAxisSize.min, // ทำให้กล่องพอดีกับเนื้อหา
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "จำนวนรายการ:",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        Text(
                          "${cartItems.length} ชิ้น",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "วิธีชำระเงิน:",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        Text(
                          paymentMethod.value,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20, thickness: 1),
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
                        Text(
                          "${totalPrice.toInt()} ฿",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
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
                      onPressed: () => Get.back(), // ปิด Dialog
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "กลับไปแก้ไข",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back(); // ปิด Dialog
                        processPayment(); // เรียก callback ฟังก์ชันบันทึก API
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C853),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "ยืนยัน",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
      barrierDismissible: false, // ห้ามกดคลิกพื้นที่ว่างเพื่อปิด
    );
  }

  // ✅ ฟังก์ชันยิง API บันทึกการขาย (ทำงานหลังจากกดยืนยันใน Popup)
  Future<void> processPaymentAPI() async {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;
      double received = double.tryParse(receivedAmountController.text) ?? 0;

      String userName =
          prefs.getString('name') ??
          prefs.getString('username') ??
          "พนักงานขาย";

      final Map<int, SaleItemRequest> groupedItems = {};
      for (var item in cartItems) {
        int productId = int.parse(item.id);
        if (groupedItems.containsKey(productId)) {
          var existingItem = groupedItems[productId]!;
          groupedItems[productId] = SaleItemRequest(
            productId: productId,
            amount: existingItem.amount + 1,
            pricePerUnit: item.price,
            totalPrice: (existingItem.amount + 1) * item.price,
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
      Get.back(); // ปิด Loading

      if (result != null) {
        Get.back(); // ปิดหน้าต่าง BottomSheet ลงไป
        Get.snackbar(
          "สำเร็จ",
          "บันทึกการขายเรียบร้อย",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
        clearAll();
        noteController.clear();
        receivedAmountController.clear();
        // 🔥 เพิ่มบรรทัดนี้: โหลดสินค้าใหม่จาก API เพื่ออัปเดตตัวเลขสต็อกบนหน้าจอทันที
        await _loadAllProducts();
      } else {
        Get.snackbar(
          "ผิดพลาด",
          "ไม่สามารถบันทึกข้อมูลการขายได้ กรุณาลองใหม่",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back();
      print("Process Payment Exception: $e");
    }
  }

  void registerNewDebtor() => Get.to(() => DebtRegisterScreen());

  @override
  void onClose() {
    receivedAmountController.dispose();
    searchController.dispose();
    noteController.dispose();
    super.onClose();
  }
}
