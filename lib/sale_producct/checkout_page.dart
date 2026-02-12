import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/api/api_shop.dart'; // ✅ อย่าลืม Import ไฟล์นี้
import 'package:eazy_store/model/request/product_model.dart';
import 'package:eazy_store/model/request/shop_model.dart';
import 'package:eazy_store/page/debt_register.dart';
import 'package:eazy_store/sale_producct/scan_barcode.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../menu_bar/bottom_navbar.dart';

// ----------------------------------------------------------------------
// Model: Product Item (UI)
// ----------------------------------------------------------------------
class ProductItem {
  final String id;
  final String name;
  final double price;
  final String category;
  final String imagePath;
  final int maxStock;
  RxBool showDelete;

  ProductItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.imagePath,
    required this.maxStock,
  }) : showDelete = false.obs;
}

// ----------------------------------------------------------------------
// Controller
// ----------------------------------------------------------------------
class CheckoutController extends GetxController {
  var cartItems = <ProductItem>[].obs;

  var allProducts = <Product>[];
  var searchResults = <Product>[].obs;
  var isSearching = false.obs;

  var isDebtMode = false.obs;
  final receivedAmountController = TextEditingController();
  var changeAmount = 0.0.obs;
  var shopQrCodeUrl = "".obs; // เก็บ URL รูป QR Code

  final debtorNameController = TextEditingController();
  final payAmountController = TextEditingController(text: "0");
  final debtRemarkController = TextEditingController();
  final searchController = TextEditingController();
  var currentNavIndex = 2.obs;

  @override
  void onInit() {
    super.onInit();
    _loadAllProducts();
    _fetchShopData(); // ดึงข้อมูลร้านค้า (QR Code)

    // คำนวณเงินทอน
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
      if (barcode != null) addProductByBarcode(barcode);
    }
  }

  // โหลดสินค้าทั้งหมด
  Future<void> _loadAllProducts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;
      if (shopId != 0) {
        List<Product> list = await ApiProduct.getProductsByShop(shopId);
        allProducts = list;
      }
    } catch (e) {
      // Handle Error
    }
  }

  // ดึงข้อมูลร้านค้า (เพื่อเอา QR Code)
  Future<void> _fetchShopData() async {
    try {
      ShopModel? shop = await ApiShop.getCurrentShop();
      if (shop != null && shop.imgQrcode.isNotEmpty) {
        shopQrCodeUrl.value = shop.imgQrcode;
      }
    } catch (e) {
      // Handle Error
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
    var match = allProducts.firstWhereOrNull((p) => p.barcode == barcode);
    if (match != null) {
      _addToCart(match);
    } else {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      try {
        Product? product = await ApiProduct.searchProduct(barcode);
        Get.back();
        if (product != null) {
          _addToCart(product);
          allProducts.add(product);
        } else {
          Get.snackbar(
            "ไม่พบสินค้า",
            "รหัส $barcode ไม่มีในระบบ",
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        }
      } catch (e) {
        Get.back();
      }
    }
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

  void removeItem(ProductItem item) {
    cartItems.removeWhere((e) => e.id == item.id);
  }

  void toggleDelete(ProductItem item) {
    for (var i in cartItems) i.showDelete.value = false;
    item.showDelete.value = !item.showDelete.value;
  }

  void clearAll() => cartItems.clear();

  double get totalPrice => cartItems.fold(0, (sum, item) => sum + item.price);

  void openPaymentSheet(BuildContext context, bool initialDebtMode) {
    isDebtMode.value = initialDebtMode;
    // Reset ค่าเมื่อเปิดหน้าจ่ายเงินใหม่
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
          Text(
            "ไม่พบสินค้า '${controller.searchController.text}'",
            style: const TextStyle(color: Colors.grey),
          ),
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
                  " ${item.price.toInt()}",
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
                  () => controller.openPaymentSheet(context, true),
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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Center(
                              child: Container(
                                width: 250,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Obx(
                                  () => Row(
                                    children: [
                                      _toggleBtn(
                                        "จ่าย",
                                        !controller.isDebtMode.value,
                                        const Color(0xFF00C853),
                                        () =>
                                            controller.isDebtMode.value = false,
                                      ),
                                      _toggleBtn(
                                        "ค้างชำระ",
                                        controller.isDebtMode.value,
                                        const Color(0xFF03A9F4),
                                        () =>
                                            controller.isDebtMode.value = true,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Divider(height: 1, color: Color(0xFFEEEEEE)),
                          Expanded(
                            child: Obx(
                              () => SingleChildScrollView(
                                controller: scrollController,
                                padding: const EdgeInsets.all(20),
                                child: controller.isDebtMode.value
                                    ? _buildDebtForm()
                                    : _buildCashForm(),
                              ),
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

  Widget _toggleBtn(
    String text,
    bool isActive,
    Color activeColor,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  // ✅ ฟอร์มจ่ายสด (ปรับปรุงตามที่ขอ)
  Widget _buildCashForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // แสดงราคารวมชัดเจน
        Center(
          child: Column(
            children: [
              const Text(
                "ยอดรวมที่ต้องชำระ",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              Text(
                "${controller.totalPrice.toInt()} บาท",
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
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
        const SizedBox(height: 30),

        // ส่วนแสดง QR Code จากร้านค้า
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
                child: controller.shopQrCodeUrl.value.isNotEmpty
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

  Widget _buildDebtForm() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "ชื่อลูกหนี้",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            TextButton.icon(
              onPressed: controller.registerNewDebtor,
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text(
                "สมัครใหม่",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
        TextField(
          controller: controller.debtorNameController,
          decoration: _inputDeco("ค้นหาชื่อ หรือ เบอร์โทร"),
        ),
        const SizedBox(height: 20),
        _rowInput("จ่ายบางส่วน", controller.payAmountController, true),
        const SizedBox(height: 15),
        _rowDisplay("ยอดค้างชำระ", controller.totalPrice.toInt().toString()),
        const SizedBox(height: 15),
        _textFieldInput("หมายเหตุ", controller.debtRemarkController),
        const SizedBox(height: 40),
        _buildActionButtons(Colors.black87, "บันทึกยอดค้าง"),
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

  Widget _rowDisplay(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 5),
            const Text(
              "฿",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
      ],
    );
  }

  Widget _textFieldInput(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          decoration: _inputDeco("ระบุรายละเอียดเพิ่มเติม"),
        ),
      ],
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
    );
  }

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
