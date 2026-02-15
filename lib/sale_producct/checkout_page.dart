import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/api/api_shop.dart';
import 'package:eazy_store/api/api_sale.dart';
import 'package:eazy_store/model/request/baskets_model.dart';
import 'package:eazy_store/model/request/product_model.dart';
import 'package:eazy_store/model/request/sales_model_request.dart';
import 'package:eazy_store/model/request/shop_model.dart';
import 'package:eazy_store/page/debt_register.dart';
import 'package:eazy_store/sale_producct/scan_barcode.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../menu_bar/bottom_navbar.dart';
import '../page/debt.dart';

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

  Future<void> _loadAllProducts() async {
    try {
      if (loadedShopId != null && loadedShopId != 0) {
        List<Product> list = await ApiProduct.getProductsByShop(loadedShopId!);
        allProducts = list;
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

  void openPaymentSheet(BuildContext context, bool initialDebtMode) {
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
      builder: (context) => _PaymentBottomSheet(controller: this),
    );
  }

  void goToDebtPaymentPage() {
    Get.to(() => const DebtPage());
  }

  // ✅ ฟังก์ชันแสดง Popup ยืนยันการชำระเงิน (ก่อนเรียก API)
  void confirmPayment() {
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
                        _processPayment(); // ไปยังฟังก์ชันบันทึก API
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
  Future<void> _processPayment() async {
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

  void registerNewDebtor() => Get.to(() => const DebtRegisterScreen());

  @override
  void onClose() {
    receivedAmountController.dispose();
    searchController.dispose();
    noteController.dispose();
    super.onClose();
  }
}

// ----------------------------------------------------------------------
// View: Checkout Page
// ----------------------------------------------------------------------
class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final CheckoutController controller = Get.put(CheckoutController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: controller.searchController,
                            onChanged: controller.onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'พิมพ์ชื่อสินค้า หรือ สแกน...',
                              hintStyle: const TextStyle(color: Colors.grey),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.grey,
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(
                                  Icons.qr_code_scanner,
                                  color: Colors.black87,
                                ),
                                onPressed: controller.openInternalScanner,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Obx(() {
                          if (controller.isSearching.value) {
                            return _buildSearchResults(controller);
                          }
                          return _buildCartList(context, controller);
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () => BottomNavBar(
          currentIndex: controller.currentNavIndex.value,
          onTap: (index) => controller.currentNavIndex.value = index,
        ),
      ),
    );
  }

  Widget _buildSearchResults(CheckoutController controller) {
    if (controller.searchResults.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 60, color: Colors.grey),
          const SizedBox(height: 10),
          const Text("ไม่พบสินค้า", style: TextStyle(color: Colors.grey)),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: controller.searchResults.length,
      separatorBuilder: (c, i) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final product = controller.searchResults[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 5,
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              product.imgProduct,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                width: 50,
                height: 50,
                color: Colors.grey[200],
                child: const Icon(Icons.image, color: Colors.grey),
              ),
            ),
          ),
          title: Text(
            product.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            "฿${product.sellPrice.toStringAsFixed(0)} | คงเหลือ: ${product.stock}",
          ),
          trailing: IconButton(
            icon: const Icon(
              Icons.add_circle,
              color: Color(0xFF6B8E23),
              size: 32,
            ),
            onPressed: () => controller.selectProductToAdd(product),
          ),
          onTap: () => controller.selectProductToAdd(product),
        );
      },
    );
  }

  Widget _buildCartList(BuildContext context, CheckoutController controller) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Align(
            alignment: Alignment.center,
            child: Text(
              "รายการในตะกร้า",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
        Expanded(
          child: Obx(() {
            if (controller.cartItems.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_basket_outlined,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "ตะกร้าว่างเปล่า",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }
            final groupedItems = <String, List<ProductItem>>{};
            for (var item in controller.cartItems) {
              if (!groupedItems.containsKey(item.id)) {
                groupedItems[item.id] = [];
              }
              groupedItems[item.id]!.add(item);
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: groupedItems.keys.length,
              separatorBuilder: (c, i) =>
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
              itemBuilder: (context, index) {
                String key = groupedItems.keys.elementAt(index);
                List<ProductItem> items = groupedItems[key]!;
                return _buildProductRow(items.first, items.length, controller);
              },
            );
          }),
        ),
        _buildBottomPanel(context, controller),
      ],
    );
  }

  Widget _buildProductRow(
    ProductItem item,
    int qty,
    CheckoutController controller,
  ) {
    double totalItemPrice = item.price * qty;
    return GestureDetector(
      onTap: () => controller.toggleDelete(item),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                _squareBtn(Icons.add, () => controller.increaseItem(item)),
                const SizedBox(height: 8),
                _squareBtn(Icons.remove, () => controller.decreaseItem(item)),
              ],
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$qty ${item.category == 'เครื่องดื่ม' ? 'ขวด' : 'ชิ้น'}",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 5),
                Text(
                  "${totalItemPrice.toInt()} บาท",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "ต่อหน่วย ${item.price.toInt()}",
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ],
            ),
            Obx(
              () => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: item.showDelete.value ? 50 : 0,
                margin: EdgeInsets.only(left: item.showDelete.value ? 15 : 0),
                child: item.showDelete.value
                    ? Center(
                        child: GestureDetector(
                          onTap: () => controller.removeItem(item),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _squareBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 20, color: Colors.black87),
      ),
    );
  }

  Widget _buildBottomPanel(
    BuildContext context,
    CheckoutController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "รวมทั้งหมด",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Obx(
                () => Text(
                  "${controller.totalPrice.toInt()} บาท",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 30, color: Color(0xFFEEEEEE)),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  "ชำระเงิน",
                  const Color(0xFF00C853),
                  () => controller.openPaymentSheet(context, false),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _actionButton(
                  "ค้างชำระ",
                  const Color(0xFF03A9F4),
                  controller.goToDebtPaymentPage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 3. Payment Sheet
// ----------------------------------------------------------------------
class _PaymentBottomSheet extends StatelessWidget {
  final CheckoutController controller;
  const _PaymentBottomSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () => Get.back(),
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: Colors.transparent,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                child: DraggableScrollableSheet(
                  initialChildSize: 0.85,
                  minChildSize: 0.5,
                  maxChildSize: 0.95,
                  expand: false,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          Center(
                            child: Container(
                              margin: const EdgeInsets.only(
                                top: 12,
                                bottom: 20,
                              ),
                              width: 50,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: Text(
                              "ชำระเงิน",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFEEEEEE)),
                          Expanded(
                            child: SingleChildScrollView(
                              controller: scrollController,
                              padding: const EdgeInsets.all(20),
                              child: _buildCashForm(),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCashForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                const Text(
                  "ยอดรวมที่ต้องชำระ",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                Obx(
                  () => Text(
                    "${controller.totalPrice.toInt()} บาท",
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 25),

        // ✅ ส่วนเลือกวิธีชำระเงิน
        const Text(
          "เลือกวิธีชำระเงิน",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Obx(
          () => Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text("จ่ายเงินสด")),
                  selectedColor: Colors.green.shade100,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: controller.paymentMethod.value == "จ่ายเงินสด"
                        ? Colors.green.shade700
                        : Colors.black87,
                  ),
                  selected: controller.paymentMethod.value == "จ่ายเงินสด",
                  onSelected: (_) =>
                      controller.paymentMethod.value = "จ่ายเงินสด",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text("โอนจ่าย")),
                  selectedColor: Colors.blue.shade100,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: controller.paymentMethod.value == "โอนจ่าย"
                        ? Colors.blue.shade700
                        : Colors.black87,
                  ),
                  selected: controller.paymentMethod.value == "โอนจ่าย",
                  onSelected: (_) => controller.paymentMethod.value = "โอนจ่าย",
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 25),

        // ✅ ฟอร์มสลับตามวิธีชำระเงิน
        Obx(
          () => controller.paymentMethod.value == "จ่ายเงินสด"
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _rowInput(
                      "รับเงินมา",
                      controller.receivedAmountController,
                      true,
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "เงินทอน",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Obx(
                            () => Text(
                              "${controller.changeAmount.value.toInt()} ฿",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Center(
                      child: Container(
                        height: 220,
                        width: 220,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Obx(
                          () => controller.shopQrCodeUrl.value.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    controller.shopQrCodeUrl.value,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(
                                      Icons.broken_image,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.qr_code_2,
                                      size: 80,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      "ไม่มี QR Code",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "📱 ให้ลูกค้าสแกนจ่ายผ่านแอปธนาคาร",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
        ),

        const SizedBox(height: 30),

        // ✅ ฟิลด์เก็บข้อมูลหมายเหตุเพิ่มเติม
        const Text(
          "หมายเหตุ (ถ้ามี)",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller.noteController,
          decoration: InputDecoration(
            hintText: 'ใส่ข้อมูลเพิ่มเติม หรือเลขอ้างอิงสลิป...',
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 15,
            ),
          ),
        ),

        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () => controller
                .confirmPayment(), // ✅ เรียกฟังก์ชันที่โชว์ Popup ก่อน
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
              shadowColor: Colors.black45,
            ),
            child: const Text(
              "ยืนยันการทำรายการ",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _rowInput(String label, TextEditingController ctrl, bool isEditable) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(
          width: 160,
          height: 50,
          child: TextField(
            controller: ctrl,
            readOnly: !isEditable,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            decoration: InputDecoration(
              suffixText: " ฿",
              contentPadding: const EdgeInsets.symmetric(horizontal: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black87, width: 2),
              ),
              filled: !isEditable,
              fillColor: isEditable ? Colors.white : Colors.grey[100],
            ),
          ),
        ),
      ],
    );
  }
}
