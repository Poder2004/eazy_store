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

<<<<<<< HEAD
  // 💰 การชำระเงินสด
=======
  // 💰 การชำระเงิน
  var isDebtMode = false.obs;
>>>>>>> 23113f551ccd8b376f95675ca848842eae757c59
  final receivedAmountController = TextEditingController();
  var changeAmount = 0.0.obs;
  var shopQrCodeUrl = "".obs; // เก็บ URL รูป QR Code ร้านค้า

<<<<<<< HEAD
  // 📝 ส่วนของการค้างชำระ (Debt) - ย้ายมาประกาศตรงนี้เพื่อให้หน้าอื่นเรียกใช้ได้
  final debtorNameController = TextEditingController(); // ชื่อคนเซ็น
  final payAmountController = TextEditingController();  // จำนวนเงินที่จ่าย (บางส่วน)
  final debtRemarkController = TextEditingController(); // หมายเหตุ
  final debtorPhoneController = TextEditingController(); // เบอร์โทร

=======
  // 📝 ข้อมูลอื่นๆ
  final debtorNameController = TextEditingController();
  final payAmountController = TextEditingController(text: "0");
  final debtRemarkController = TextEditingController();
>>>>>>> 23113f551ccd8b376f95675ca848842eae757c59
  final searchController = TextEditingController();
  var currentNavIndex = 2.obs;

  // ✅ ตัวแปรจำ Shop ID ล่าสุด (เพื่อป้องกันข้อมูลร้านเก่าค้าง)
  int? loadedShopId;

  @override
  void onInit() {
    super.onInit();
    // เรียกเช็คข้อมูลครั้งแรก
    checkShopAndLoadData();

<<<<<<< HEAD
    // Listener สำหรับคำนวณเงินทอน (หน้าจ่ายสด)
=======
    // Listener คำนวณเงินทอน
>>>>>>> 23113f551ccd8b376f95675ca848842eae757c59
    receivedAmountController.addListener(() {
      double received = double.tryParse(receivedAmountController.text) ?? 0;
      // ✅ เช็คว่าจ่ายพอไหม ถ้าไม่พอให้เงินทอนเป็น 0
      if (received >= totalPrice) {
        changeAmount.value = received - totalPrice;
      } else {
        changeAmount.value = 0.0;
      }
    });

<<<<<<< HEAD
    // Listener สำหรับหน้า Debt (เพื่อให้ UI อัปเดตยอด "จำนวนที่เซ็น" แบบ Real-time)
    payAmountController.addListener(() {
      update(); // สั่งให้ GetBuilder ในหน้า Debt ทำงาน
    });

    // รับบาร์โค้ดจากหน้าอื่น
    if (Get.arguments != null && Get.arguments is Map) {
      String? barcode = Get.arguments['barcode'];
      if (barcode != null) {
=======
    if (Get.arguments != null && Get.arguments is Map) {
      String? barcode = Get.arguments['barcode'];
      if (barcode != null) {
        // ใช้ addPostFrameCallback เพื่อรอให้หน้าจอสร้างเสร็จก่อนค่อยทำงาน
>>>>>>> 23113f551ccd8b376f95675ca848842eae757c59
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
      debugPrint("Error loading products: $e");
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
      debugPrint("Error loading shop data: $e");
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
<<<<<<< HEAD
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int shopId = prefs.getInt('shopId') ?? 0;

      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
=======
      // ไม่เจอในเครื่อง -> ยิง API ไปเช็คที่ Server
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

>>>>>>> 23113f551ccd8b376f95675ca848842eae757c59
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
<<<<<<< HEAD
          Get.snackbar("ไม่พบสินค้า", "รหัส $barcode ไม่มีในระบบ",
              backgroundColor: Colors.orange, colorText: Colors.white);
=======
          // ถ้า Server ไม่ส่งกลับมา แสดงว่าไม่มีในร้านนี้ (แม้ว่าร้านอื่นจะมีบาร์โค้ดนี้ก็ตาม)
          Get.snackbar(
            "ไม่พบสินค้า",
            "รหัส $barcode ไม่มีในร้านนี้",
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
>>>>>>> 23113f551ccd8b376f95675ca848842eae757c59
        }
      } catch (e) {
        Get.back();
      }
    }
  }

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

<<<<<<< HEAD
  // --- การยืนยันชำระเงิน ---
  void openPaymentSheet(BuildContext context) {
    receivedAmountController.clear();
    changeAmount.value = 0.0;
=======
  void openPaymentSheet(BuildContext context, bool initialDebtMode) {
    isDebtMode.value = initialDebtMode;
    if (!initialDebtMode) {
      receivedAmountController.clear();
      changeAmount.value = 0.0;
    }
>>>>>>> 23113f551ccd8b376f95675ca848842eae757c59
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PaymentBottomSheet(controller: this),
    );
  }

  void goToDebtPaymentPage() {
    // ยังไม่ทำ ว่างไว้ก่อน
  }

  void confirmPayment() {
    if (cartItems.isEmpty) {
      Get.snackbar("ผิดพลาด", "กรุณาเลือกสินค้าก่อนชำระเงิน", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    Get.back();
<<<<<<< HEAD
    Get.snackbar("สำเร็จ", "บันทึกรายการเรียบร้อย", backgroundColor: Colors.green, colorText: Colors.white);
=======
    Get.snackbar(
      "สำเร็จ",
      "บันทึกรายการเรียบร้อย",
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
>>>>>>> 23113f551ccd8b376f95675ca848842eae757c59
    clearAll();
  }

  void registerNewDebtor() => Get.to(() => const DebtRegisterScreen());

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
<<<<<<< HEAD
              Expanded(child: _actionButton("จ่ายสด", const Color(0xFF00C853), () => controller.openPaymentSheet(context))),
              const SizedBox(width: 20),
              Expanded(child: _actionButton("ค้างชำระ", const Color(0xFF03A9F4), () => Get.to(() => const DebtPage()))),
=======
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
>>>>>>> 23113f551ccd8b376f95675ca848842eae757c59
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