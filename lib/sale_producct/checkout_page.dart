import 'package:eazy_store/api/api_product.dart';
import 'package:eazy_store/api/api_shop.dart';
import 'package:eazy_store/model/request/baskets_model.dart';
import 'package:eazy_store/model/request/product_model.dart';
import 'package:eazy_store/model/request/shop_model.dart';
import 'package:eazy_store/sale_producct/scan_barcode.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../menu_bar/bottom_navbar.dart';
import '../page/debt.dart';

class CheckoutController extends GetxController {
  // 🛒 ตะกร้าสินค้า
  var cartItems = <ProductItem>[].obs;

  // 🔍 คลังสินค้า & ค้นหา
  var allProducts = <Product>[];
  var searchResults = <Product>[].obs;
  var isSearching = false.obs;

  // 💰 การชำระเงินสด
  final receivedAmountController = TextEditingController();
  var changeAmount = 0.0.obs;
  var shopQrCodeUrl = "".obs;

  // 📝 ส่วนของการค้างชำระ (Debt) - ย้ายมาประกาศตรงนี้เพื่อให้หน้าอื่นเรียกใช้ได้
  final debtorNameController = TextEditingController(); // ชื่อคนเซ็น
  final payAmountController = TextEditingController();  // จำนวนเงินที่จ่าย (บางส่วน)
  final debtRemarkController = TextEditingController(); // หมายเหตุ
  final debtorPhoneController = TextEditingController(); // เบอร์โทร

  final searchController = TextEditingController();
  var currentNavIndex = 2.obs;

  @override
  void onInit() {
    super.onInit();
    _loadAllProducts();
    _fetchShopData();

    // Listener สำหรับคำนวณเงินทอน (หน้าจ่ายสด)
    receivedAmountController.addListener(() {
      double received = double.tryParse(receivedAmountController.text) ?? 0;
      if (received >= totalPrice) {
        changeAmount.value = received - totalPrice;
      } else {
        changeAmount.value = 0.0;
      }
    });

    // Listener สำหรับหน้า Debt (เพื่อให้ UI อัปเดตยอด "จำนวนที่เซ็น" แบบ Real-time)
    payAmountController.addListener(() {
      update(); // สั่งให้ GetBuilder ในหน้า Debt ทำงาน
    });

    // รับบาร์โค้ดจากหน้าอื่น
    if (Get.arguments != null && Get.arguments is Map) {
      String? barcode = Get.arguments['barcode'];
      if (barcode != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          addProductByBarcode(barcode);
        });
      }
    }
  }

  // --- โหลดข้อมูล ---
  Future<void> _loadAllProducts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;
      if (shopId != 0) {
        List<Product> list = await ApiProduct.getProductsByShop(shopId);
        allProducts = list;
      }
    } catch (e) {
      debugPrint("Error loading products: $e");
    }
  }

  Future<void> _fetchShopData() async {
    try {
      ShopModel? shop = await ApiShop.getCurrentShop();
      if (shop != null && shop.imgQrcode.isNotEmpty) {
        shopQrCodeUrl.value = shop.imgQrcode;
      }
    } catch (e) {
      debugPrint("Error loading shop data: $e");
    }
  }

  // --- ระบบค้นหา ---
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

  // --- สแกนบาร์โค้ด ---
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
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;

      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      try {
        Product? product = await ApiProduct.searchProduct(barcode, shopId);
        Get.back();
        if (product != null) {
          _addToCart(product);
          allProducts.add(product);
        } else {
          Get.snackbar("ไม่พบสินค้า", "รหัส $barcode ไม่มีในระบบ",
              backgroundColor: Colors.orange, colorText: Colors.white);
        }
      } catch (e) {
        Get.back();
      }
    }
  }

  // --- จัดการตะกร้า ---
  void _addToCart(Product product) {
    int currentQty = cartItems.where((item) => item.id == product.productId.toString()).length;
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
      Get.snackbar("สินค้าหมด", "คงเหลือ ${product.stock} ชิ้น",
          backgroundColor: Colors.redAccent, colorText: Colors.white, duration: const Duration(seconds: 1));
    }
  }

  void increaseItem(ProductItem item) {
    int currentQty = cartItems.where((i) => i.id == item.id).length;
    if (currentQty < item.maxStock) {
      cartItems.add(ProductItem(
        id: item.id,
        name: item.name,
        price: item.price,
        category: item.category,
        imagePath: item.imagePath,
        maxStock: item.maxStock,
      ));
    } else {
      Get.snackbar("แจ้งเตือน", "สินค้ามีจำกัด", backgroundColor: Colors.orange, colorText: Colors.white);
    }
  }

  void decreaseItem(ProductItem item) {
    int index = cartItems.indexWhere((e) => e.id == item.id);
    if (index != -1) cartItems.removeAt(index);
  }

  void removeItem(ProductItem item) => cartItems.removeWhere((e) => e.id == item.id);

  void toggleDelete(ProductItem item) {
    for (var i in cartItems) {
      if (i.id != item.id) i.showDelete.value = false;
    }
    item.showDelete.value = !item.showDelete.value;
  }

  void clearAll() {
    cartItems.clear();
    debtorNameController.clear();
    payAmountController.clear();
    debtRemarkController.clear();
    debtorPhoneController.clear();
  }

  double get totalPrice => cartItems.fold(0, (sum, item) => sum + item.price);

  // --- การยืนยันชำระเงิน ---
  void openPaymentSheet(BuildContext context) {
    receivedAmountController.clear();
    changeAmount.value = 0.0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PaymentBottomSheet(controller: this),
    );
  }

  void confirmPayment() {
    if (cartItems.isEmpty) {
      Get.snackbar("ผิดพลาด", "กรุณาเลือกสินค้าก่อนชำระเงิน", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    Get.back();
    Get.snackbar("สำเร็จ", "บันทึกรายการเรียบร้อย", backgroundColor: Colors.green, colorText: Colors.white);
    clearAll();
  }

  @override
  void onClose() {
    receivedAmountController.dispose();
    searchController.dispose();
    debtorNameController.dispose();
    payAmountController.dispose();
    debtRemarkController.dispose();
    debtorPhoneController.dispose();
    super.onClose();
  }
}

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
                      // Search Bar
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
                              prefixIcon: const Icon(Icons.search, color: Colors.grey),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.qr_code_scanner, color: Colors.black87),
                                onPressed: controller.openInternalScanner,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      // List Area
                      Expanded(
                        child: Obx(() {
                          if (controller.isSearching.value) return _buildSearchResults(controller);
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
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey),
          SizedBox(height: 10),
          Text("ไม่พบสินค้า", style: TextStyle(color: Colors.grey)),
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
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              product.imgProduct,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(width: 50, height: 50, color: Colors.grey[200], child: const Icon(Icons.image)),
            ),
          ),
          title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("฿${product.sellPrice.toStringAsFixed(0)} | คงเหลือ: ${product.stock}"),
          trailing: const Icon(Icons.add_circle, color: Color(0xFF6B8E23), size: 32),
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
          child: Text("รายการในตะกร้า", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const Divider(height: 1),
        Expanded(
          child: Obx(() {
            if (controller.cartItems.isEmpty) {
              return Center(child: Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.grey[300]));
            }
            final groupedItems = <String, List<ProductItem>>{};
            for (var item in controller.cartItems) {
              groupedItems.putIfAbsent(item.id, () => []).add(item);
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: groupedItems.keys.length,
              separatorBuilder: (c, i) => const Divider(height: 1),
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

  Widget _buildProductRow(ProductItem item, int qty, CheckoutController controller) {
    return GestureDetector(
      onTap: () => controller.toggleDelete(item),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        color: Colors.transparent,
        child: Row(
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
                  Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("$qty ${item.category == 'เครื่องดื่ม' ? 'ขวด' : 'ชิ้น'}", style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            Text("${(item.price * qty).toInt()} บาท", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Obx(() => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: item.showDelete.value ? 50 : 0,
                  child: item.showDelete.value
                      ? IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => controller.removeItem(item))
                      : const SizedBox(),
                )),
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
        decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 20),
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context, CheckoutController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, offset: const Offset(0, -4), blurRadius: 10)]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("รวมทั้งหมด", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Obx(() => Text("${controller.totalPrice.toInt()} บาท", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            ],
          ),
          const Divider(height: 30),
          Row(
            children: [
              Expanded(child: _actionButton("จ่ายสด", const Color(0xFF00C853), () => controller.openPaymentSheet(context))),
              const SizedBox(width: 20),
              Expanded(child: _actionButton("ค้างชำระ", const Color(0xFF03A9F4), () => Get.to(() => const DebtPage()))),
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
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _PaymentBottomSheet extends StatelessWidget {
  final CheckoutController controller;
  const _PaymentBottomSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            const Center(child: Text("ชำระเงิน", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            const SizedBox(height: 30),
            Obx(() => Center(child: Text("${controller.totalPrice.toInt()} บาท", style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)))),
            const SizedBox(height: 30),
            TextField(
              controller: controller.receivedAmountController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(labelText: "รับเงิน", suffixText: " ฿", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("เงินทอน", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("${controller.changeAmount.value.toInt()} บาท", style: const TextStyle(fontSize: 24, color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            )),
            const SizedBox(height: 30),
            Obx(() => controller.shopQrCodeUrl.value.isNotEmpty
                ? Center(child: Image.network(controller.shopQrCodeUrl.value, height: 200))
                : const Center(child: Text("ไม่มี QR Code ร้านค้า"))),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => controller.confirmPayment(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, minimumSize: const Size(double.infinity, 50)),
              child: const Text("ยืนยันการชำระเงิน", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}