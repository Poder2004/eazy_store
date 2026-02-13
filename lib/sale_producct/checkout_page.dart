import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/api/api_shop.dart'; // ✅ Import
import 'package:eazy_store/model/request/baskets_model.dart';
import 'package:eazy_store/model/request/product_model.dart';
import 'package:eazy_store/model/request/shop_model.dart'; // ✅ Import
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
  final receivedAmountController = TextEditingController();
  var changeAmount = 0.0.obs;
  var shopQrCodeUrl = "".obs; // เก็บ URL รูป QR Code ร้านค้า

  // 📝 ข้อมูลอื่นๆ
  final debtorNameController = TextEditingController();
  final payAmountController = TextEditingController(text: "0");
  final debtRemarkController = TextEditingController();
  final searchController = TextEditingController();
  var currentNavIndex = 2.obs;

  // ✅ ตัวแปรจำ Shop ID ล่าสุด (เพื่อป้องกันข้อมูลร้านเก่าค้าง)
  int? loadedShopId;

  @override
  void onInit() {
    super.onInit();
    // เรียกเช็คข้อมูลครั้งแรก
    checkShopAndLoadData();

    // Listener คำนวณเงินทอน
    receivedAmountController.addListener(() {
      double received = double.tryParse(receivedAmountController.text) ?? 0;
      // ✅ เช็คว่าจ่ายพอไหม ถ้าไม่พอให้เงินทอนเป็น 0
      if (received >= totalPrice) {
        changeAmount.value = received - totalPrice;
      } else {
        changeAmount.value = 0.0;
      }
    });

    if (Get.arguments != null && Get.arguments is Map) {
      String? barcode = Get.arguments['barcode'];
      if (barcode != null) {
        // ใช้ addPostFrameCallback เพื่อรอให้หน้าจอสร้างเสร็จก่อนค่อยทำงาน
        WidgetsBinding.instance.addPostFrameCallback((_) {
          addProductByBarcode(barcode);
        });
      }
    }
  }

  @override
  void onReady() {
    super.onReady();
    // ✅ เช็คทุกครั้งที่หน้าจอพร้อมใช้งาน (เผื่อสลับมาจากหน้าอื่นแล้วร้านเปลี่ยน)
    checkShopAndLoadData();
  }

  // ✅ ฟังก์ชันตรวจสอบและโหลดข้อมูล (หัวใจหลักแก้ Data Leakage)
  Future<void> checkShopAndLoadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int currentShopId = prefs.getInt('shopId') ?? 0;

    // ถ้าร้านเปลี่ยน หรือ ยังไม่เคยโหลด
    if (loadedShopId != currentShopId) {
      print(
        "♻️ ร้านค้าเปลี่ยน ($loadedShopId -> $currentShopId) กำลังรีเซ็ตข้อมูล...",
      );

      // 1. เคลียร์ข้อมูลเก่าทิ้งให้หมด
      allProducts.clear();
      cartItems.clear();
      searchResults.clear();
      receivedAmountController.clear();
      changeAmount.value = 0.0;
      shopQrCodeUrl.value = "";

      // 2. อัปเดต ID ปัจจุบัน
      loadedShopId = currentShopId;

      // 3. โหลดข้อมูลใหม่ของร้านนี้
      await _loadAllProducts();
      await _fetchShopData();
    }
  }

  // โหลดสินค้าทั้งหมด
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

  // ✅ ดึงข้อมูลร้านค้า (เพื่อเอา QR Code)
  Future<void> _fetchShopData() async {
    try {
      ShopModel? shop = await ApiShop.getCurrentShop();
      if (shop != null && shop.imgQrcode.isNotEmpty) {
        shopQrCodeUrl.value = shop.imgQrcode;
        print("QR Code Loaded: ${shop.imgQrcode}");
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

  // 🔥 แก้ไขฟังก์ชันนี้: เพิ่มการตรวจสอบ Shop ID ก่อนค้นหาเสมอ!
  Future<void> addProductByBarcode(String barcode) async {
    // 🛡️ STEP 1: เช็คความปลอดภัยก่อน! ร้านเปลี่ยนไหม?
    // ถ้าเปลี่ยน ฟังก์ชันนี้จะล้าง allProducts เก่าทิ้งทันที
    await checkShopAndLoadData();

    // 🛡️ STEP 2: ตรวจสอบว่าโหลดสินค้าเสร็จหรือยัง
    if (allProducts.isEmpty) {
      await _loadAllProducts();
    }

    // 🔍 STEP 3: ค้นหาในเครื่อง (ตอนนี้ allProducts เป็นของร้านปัจจุบันแน่นอนแล้ว)
    var match = allProducts.firstWhereOrNull((p) => p.barcode == barcode);

    if (match != null) {
      // เจอในเครื่อง (แปลว่าเป็นสินค้าของร้านนี้จริงๆ)
      _addToCart(match);
    } else {
      // ไม่เจอในเครื่อง -> ยิง API ไปเช็คที่ Server
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        int currentShopId = prefs.getInt('shopId') ?? 0;

        // ✅ ส่ง currentShopId ไปด้วย เพื่อให้ Server กรองสินค้าเฉพาะร้านนี้
        Product? product = await ApiProduct.searchProduct(
          barcode,
          currentShopId,
        ); // แก้ไขให้ส่ง shopId ด้วย

        Get.back(); // ปิด Loading

        if (product != null) {
          // ถ้า Server ส่งกลับมา แสดงว่าเป็นของร้านนี้จริงๆ
          _addToCart(product);
          allProducts.add(product);
        } else {
          // ถ้า Server ไม่ส่งกลับมา แสดงว่าไม่มีในร้านนี้ (แม้ว่าร้านอื่นจะมีบาร์โค้ดนี้ก็ตาม)
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

  // เพิ่มใน CheckoutController (checkout_page.dart)
  void addItemsByIds(List<String> productIds) {
    for (var id in productIds) {
      // หาข้อมูลสินค้าจากลิสต์ allProducts ที่โหลดไว้แล้ว
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
    isDebtMode.value = initialDebtMode;
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

  void confirmPayment() {
    Get.back();
    Get.snackbar(
      "สำเร็จ",
      "บันทึกรายการเรียบร้อย",
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
    clearAll();
  }

  void registerNewDebtor() => Get.to(() => const DebtRegisterScreen());

  @override
  void onClose() {
    receivedAmountController.dispose();
    searchController.dispose();
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
                          if (controller.isSearching.value)
                            return _buildSearchResults(controller);
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
            if (controller.cartItems.isEmpty)
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
            final groupedItems = <String, List<ProductItem>>{};
            for (var item in controller.cartItems) {
              if (!groupedItems.containsKey(item.id))
                groupedItems[item.id] = [];
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
                  "จ่ายสด",
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
        const SizedBox(height: 30),
        const Text(
          "รับเงิน",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _rowInput("จำนวนเงิน", controller.receivedAmountController, true),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "เงินทอน",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Obx(
              () => Text(
                "${controller.changeAmount.value.toInt()} บาท",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 35),
        Center(
          child: Column(
            children: [
              Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(10),
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
                            Icon(Icons.qr_code_2, size: 100),
                            Text("ไม่มี QR Code ร้านค้า"),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "สแกนเพื่อจ่าย (PromptPay)",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        _buildActionButtons(Colors.black87, "ยืนยันการชำระเงิน"),
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
          width: 150,
          height: 45,
          child: TextField(
            controller: ctrl,
            readOnly: !isEditable,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            decoration: InputDecoration(
              suffixText: " ฿",
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              filled: !isEditable,
              fillColor: isEditable ? Colors.white : Colors.grey[100],
            ),
          ),
        ),
      ],
    );
  }

  //test
  Widget _buildActionButtons(Color color, String text) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: () => controller.confirmPayment(),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
