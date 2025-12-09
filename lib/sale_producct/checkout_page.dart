import 'package:eazy_store/page/debt_register.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../menu_bar/bottom_navbar.dart'; // เรียกใช้ Navbar ของคุณพี่

// ----------------------------------------------------------------------
// Model: โครงสร้างข้อมูลสินค้า
// ----------------------------------------------------------------------
class ProductItem {
  final String id;
  final String name;
  final double price;
  final String category;
  final String imagePath;
  RxBool isSelected;
  RxBool showDelete; // สำหรับโชว์ปุ่มลบ

  ProductItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.imagePath,
    bool selected = false,
  }) : isSelected = selected.obs,
       showDelete = false.obs;
}

// ----------------------------------------------------------------------
// 1. Controller: จัดการคำนวณเงินและโหมดการจ่าย
// ----------------------------------------------------------------------
class CheckoutController extends GetxController {
  var cartItems = <ProductItem>[].obs;

  // โหมดการจ่าย: false = จ่ายสด, true = ค้างชำระ
  var isDebtMode = false.obs;

  // ตัวแปร input
  final receivedAmountController = TextEditingController();
  var changeAmount = 0.0.obs;

  final debtorNameController = TextEditingController();
  final payAmountController = TextEditingController(text: "0");
  final debtPhoneController = TextEditingController();
  final debtRemarkController = TextEditingController();

  var currentNavIndex = 2.obs;

  @override
  void onInit() {
    super.onInit();

    // --- Mock Data (ตัวอย่างให้เหมือนรูป) ---
    // 1. เบียร์สิงห์
    cartItems.add(
      ProductItem(
        id: '101',
        name: 'เบียร์สิงห์ 620 มล.',
        price: 130,
        category: 'เครื่องดื่ม',
        imagePath: 'assets/image/list1.png',
      ),
    );
    // 2. รสดี
    cartItems.add(
      ProductItem(
        id: '102',
        name: 'รสดี 70 กรัม',
        price: 13,
        category: 'เครื่องปรุง',
        imagePath: 'assets/image/list2.png',
      ),
    );
    // 3. มาม่า
    cartItems.add(
      ProductItem(
        id: '103',
        name: 'มาม่า',
        price: 35,
        category: 'อาหารแห้ง',
        imagePath: 'assets/image/list3.png',
      ),
    );

    // Listener คำนวณเงินทอน
    receivedAmountController.addListener(() {
      double received = double.tryParse(receivedAmountController.text) ?? 0;
      changeAmount.value = received - totalPrice;
    });
  }

  double get totalPrice => cartItems.fold(0, (sum, item) => sum + item.price);

  void increaseItem(ProductItem item) {
    // Logic จำลองการเพิ่มจำนวน (เพิ่มรายการซ้ำ)
    cartItems.add(
      ProductItem(
        id: item.id,
        name: item.name,
        price: item
            .price, // หมายเหตุ: ใน Mock นี้ price คือราคารวมของ item นั้นๆ อยู่แล้ว ถ้าของจริงต้องเป็น unitPrice
        category: item.category,
        imagePath: item.imagePath,
      ),
    );
  }

  void decreaseItem(ProductItem item) {
    int index = cartItems.indexWhere((e) => e.id == item.id);
    if (index != -1) cartItems.removeAt(index);
  }

  void removeItem(ProductItem item) {
    cartItems.removeWhere((e) => e.id == item.id);
  }

  void toggleDelete(ProductItem item) {
    for (var i in cartItems) {
      if (i != item) i.showDelete.value = false;
    }
    item.showDelete.value = !item.showDelete.value;
  }

  // เปิด Sheet จ่ายเงิน
  void openPaymentSheet(BuildContext context, bool initialDebtMode) {
    isDebtMode.value = initialDebtMode;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PaymentBottomSheet(controller: this),
    );
  }

  void confirmPayment() {
    Get.back();
    if (isDebtMode.value) {
      Get.snackbar(
        "บันทึก",
        "บันทึกยอดค้างชำระเรียบร้อย",
        backgroundColor: Colors.blueAccent,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        "สำเร็จ",
        "ชำระเงินเรียบร้อย",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }

  void clearAll() {
    cartItems.clear();
  }

  void registerNewDebtor() {
    Get.to(() => const DebtRegisterScreen());
  }
}

// ----------------------------------------------------------------------
// 2. The View: หน้าจอ UI หลัก (Responsive iPad/Mobile)
// ----------------------------------------------------------------------
class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final CheckoutController controller = Get.put(CheckoutController());

    return Scaffold(
      backgroundColor: Colors.white, // พื้นหลังขาวตามรูป
      body: SafeArea(
        child: Column(
          children: [
            // --- Content Area (Expanded) ---
            Expanded(
              child: Center(
                child: Container(
                  // Responsive: ขยายกว้างขึ้นสำหรับ iPad (800px) แต่ไม่เต็มจอเกินไป
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    children: [
                      // 1. Search Bar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5), // สีเทาอ่อนๆ
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const TextField(
                            decoration: InputDecoration(
                              hintText: 'ค้นหาหรือสแกนบาร์โค้ด',
                              hintStyle: TextStyle(color: Colors.grey),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey,
                              ),
                              suffixIcon: Icon(
                                Icons.qr_code_scanner,
                                color: Colors.grey,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 2. Header
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 20,
                        ),
                        child: Align(
                          alignment:
                              Alignment.center, // จัดกึ่งกลางตามรูป reference
                          child: Text(
                            "รายการสินค้า",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      // เส้นคั่นบางๆ
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFEEEEEE),
                      ),

                      // 3. Product List
                      Expanded(
                        child: Obx(() {
                          if (controller.cartItems.isEmpty) {
                            return const Center(
                              child: Text(
                                "ยังไม่มีสินค้า",
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          // จัดกลุ่มสินค้าเพื่อแสดงผล
                          final groupedItems = <String, List<ProductItem>>{};
                          for (var item in controller.cartItems) {
                            if (!groupedItems.containsKey(item.id))
                              groupedItems[item.id] = [];
                            groupedItems[item.id]!.add(item);
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            itemCount: groupedItems.keys.length,
                            separatorBuilder: (c, i) => const Divider(
                              height: 1,
                              color: Color(0xFFEEEEEE),
                            ), // เส้นคั่นระหว่างรายการ
                            itemBuilder: (context, index) {
                              String key = groupedItems.keys.elementAt(index);
                              List<ProductItem> items = groupedItems[key]!;
                              return _buildProductRow(
                                items.first,
                                items.length,
                                controller,
                              );
                            },
                          );
                        }),
                      ),

                      // 4. Summary & Buttons (Fixed at bottom)
                      _buildBottomPanel(context, controller),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // --- Navbar ---
      bottomNavigationBar: Obx(
        () => BottomNavBar(
          currentIndex: controller.currentNavIndex.value,
          onTap: (index) => controller.currentNavIndex.value = index,
        ),
      ),
    );
  }

  // Widget: แถวสินค้า (Layout เหมือนรูปเป๊ะๆ)
  Widget _buildProductRow(
    ProductItem item,
    int qty,
    CheckoutController controller,
  ) {
    // คำนวณราคา (Mockup: ราคาที่โชว์คือราคารวม)
    double totalItemPrice = item.price * qty;
    // ราคาต่อหน่วย (Mockup)
    double unitPrice = item.price;

    return GestureDetector(
      onTap: () => controller.toggleDelete(item), // กดเพื่อโชว์ปุ่มลบ
      child: Container(
        color: Colors.transparent, // ให้กดติดง่าย
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. ปุ่ม +/- (ซ้ายสุด แนวตั้ง) ---
            Column(
              children: [
                _squareBtn(Icons.add, () => controller.increaseItem(item)),
                const SizedBox(height: 8),
                _squareBtn(Icons.remove, () => controller.decreaseItem(item)),
              ],
            ),
            const SizedBox(width: 15),

            // --- 2. ข้อมูลสินค้า (ชื่อ + จำนวน) ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 5), // จัดให้ตรงกับปุ่ม +
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$qty ${item.category == 'เครื่องดื่ม'
                        ? 'ขวด'
                        : item.category == 'อาหารแห้ง'
                        ? 'ห่อ'
                        : 'ชิ้น'}",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // --- 3. ราคา (ขวาสุด) ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      "${totalItemPrice.toInt()}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      "บาท",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "${unitPrice.toInt()}", // ราคาต่อหน่วย
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
              ],
            ),

            // --- 4. ปุ่มลบ (Slide ออกมา) ---
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

  // ปุ่มสี่เหลี่ยมสีเทาสำหรับ + / -
  Widget _squareBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEEE), // สีเทาอ่อน
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 20, color: Colors.black87),
      ),
    );
  }

  // Panel ด้านล่าง (ยอดรวม + ปุ่มเปิด Sheet)
  Widget _buildBottomPanel(
    BuildContext context,
    CheckoutController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ยอดรวม
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "รวมทั้งหมด",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
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
          const Divider(height: 30, color: Color(0xFFEEEEEE)), // เส้นคั่นบางๆ
          // ปุ่ม 2 ปุ่ม (จ่าย / ค้างชำระ)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _actionButton(
                "จ่าย",
                const Color(0xFF00C853), // เขียว
                () => controller.openPaymentSheet(
                  context,
                  false,
                ), // false = จ่ายสด
              ),
              const SizedBox(width: 20),
              _actionButton(
                "ค้างชำระ",
                const Color(0xFF03A9F4), // ฟ้า
                () => controller.openPaymentSheet(
                  context,
                  true,
                ), // true = ค้างชำระ
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: 120, // กำหนดความกว้างให้เท่ากัน
      height: 40,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 3. Widget: Slider Bar (Sheet ชำระเงิน)
// ----------------------------------------------------------------------
class _PaymentBottomSheet extends StatelessWidget {
  final CheckoutController controller;

  const _PaymentBottomSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    // Responsive: จำกัดความกว้าง Sheet ไม่ให้เต็มจอ iPad
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          // ใช้ Stack เพื่อซ้อน Layer
          children: [
            // --- 1. Layer สำหรับกดปิด (พื้นที่ว่างด้านบน) ---
            GestureDetector(
              onTap: () => Get.back(), // กดที่ว่างเพื่อปิด
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: Colors.transparent,
                width: double.infinity,
                height: double.infinity,
              ),
            ),

            // --- 2. ตัว Sheet ---
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 800,
                ), // Max width สำหรับ iPad
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
                          // Handle
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

                          // --- Toggle Switch (สลับโหมด) ---
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Center(
                              child: Container(
                                width: 250, // จำกัดความกว้างปุ่มสลับ
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

                          // Content
                          Expanded(
                            child: Obx(
                              () => SingleChildScrollView(
                                controller: scrollController,
                                padding: const EdgeInsets.all(20),
                                // สลับ Form ตามโหมด
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

  // ฟอร์มจ่ายสด
  Widget _buildCashForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "จ่ายสด / โอน",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        _rowInput("รับเงิน", controller.receivedAmountController, true),
        const SizedBox(height: 15),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "เงินทอน",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Obx(
              () => Text(
                "${controller.changeAmount.value.toInt()} บาท",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 30),
        Center(
          child: Container(
            height: 180,
            width: 180,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.qr_code_2, size: 120),
          ),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            "สแกนเพื่อจ่าย (PromptPay)",
            style: TextStyle(color: Colors.grey),
          ),
        ),

        const SizedBox(height: 40),
        _buildActionButtons(const Color(0xFF1B1B1B), "ชำระเงิน"),
        const SizedBox(height: 40),
      ],
    );
  }

  // ฟอร์มค้างชำระ
  Widget _buildDebtForm() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "ชื่อคนเซ็น",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: controller.registerNewDebtor,
              child: const Text(
                "+ สมัครลูกหนี้",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
        TextField(
          controller: controller.debtorNameController,
          decoration: _inputDeco("ค้นหาชื่อ หรือ เบอร์โทร"),
        ),
        const SizedBox(height: 15),
        _rowInput("จ่าย", controller.payAmountController, true),
        const SizedBox(height: 15),

        _rowDisplay("จำนวนที่เซ็น", controller.totalPrice.toInt().toString()),
        const SizedBox(height: 15),

        _textFieldInput("หมายเหตุ", controller.debtRemarkController),

        const SizedBox(height: 40),
        _buildActionButtons(const Color(0xFF1B1B1B), "บันทึกยอดค้าง"),
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
          width: 140,
          height: 35,
          child: TextField(
            controller: ctrl,
            readOnly: !isEditable,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            decoration: InputDecoration(
              suffixText: " บาท",
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
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
            Container(
              width: 90,
              height: 35,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 5),
            const Text(
              "บาท",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
        const SizedBox(height: 5),
        TextField(controller: ctrl, decoration: _inputDeco("")),
      ],
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
    );
  }

  Widget _buildActionButtons(Color color, String text) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => controller.confirmPayment(),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
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
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: controller.clearAll,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.black),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "ล้างทั้งหมด",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
