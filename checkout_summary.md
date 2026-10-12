# หน้า "คิดเงิน / ตะกร้าสินค้า" (CheckoutPage + CheckoutController)

> **ไฟล์ที่เกี่ยวข้อง**
> - UI: [`checkout_page.dart`](file:///z:/eazy_store/lib/page/sale_producct/sale/checkout_page.dart)
> - Controller: [`checkout_controller.dart`](file:///z:/eazy_store/lib/page/sale_producct/sale/checkout_controller.dart)

---

## วัตถุประสงค์

หน้าหลักของระบบขาย — เป็นศูนย์กลางตะกร้าสินค้า, การค้นหา, การชำระเงิน, และการพักออเดอร์

---

## โครงสร้าง UI

```
Scaffold
  ├── Body (SafeArea + MediaQuery.clamp fontScale ≤ 1.2)
  │     ├── [ช่องค้นหา] พิมพ์ชื่อ/บาร์โค้ด + ปุ่มสแกน QR
  │     └── Obx → สลับอัตโนมัติ:
  │           ├── isSearching = true  → _buildSearchResults()
  │           └── isSearching = false → _buildCartList()
  │                 ├── Header "รายการในตะกร้า" + Badge "พัก N รายการ"
  │                 ├── ListView สินค้าในตะกร้า (Group by productId)
  │                 └── _buildBottomPanel()
  │                       ├── ยอดรวม
  │                       └── ปุ่ม [พักออเดอร์] [ชำระเงิน] [ค้างชำระ]
  └── BottomNavBar
```

---

## State หลักใน Controller

| Variable | ประเภท | ความหมาย |
|---|---|---|
| `cartItems` | `RxList<ProductItem>` | สินค้าในตะกร้า (1 ชิ้น = 1 element) |
| `allProducts` | `List<ProductResponse>` | คลังสินค้าทั้งหมด (cache ในเครื่อง) |
| `searchResults` | `RxList<ProductResponse>` | ผลค้นหาที่แสดงอยู่ |
| `isSearching` | `RxBool` | มีคำค้นหาอยู่ → โชว์หน้าค้นหา |
| `isSearchLoading` | `RxBool` | กำลังยิง API ค้นหา → โชว์ spinner |
| `paymentMethod` | `RxString` | `"จ่ายเงินสด"` หรือ `"โอนจ่าย"` |
| `changeAmount` | `RxDouble` | เงินทอน (คำนวณ realtime) |
| `shopQrCodeUrl` | `RxString` | URL QR Code ร้านสำหรับโอนจ่าย |
| `isProcessingPayment` | `RxBool` | กำลัง submit ชำระเงิน (กันกดซ้ำ) |
| `currentNavIndex` | `RxInt` | Tab ปัจจุบันของ BottomNavBar |
| `loadedShopId` | `int?` | shopId ที่โหลดข้อมูลล่าสุด |

### TextEditingControllers

| Controller | ใช้สำหรับ |
|---|---|
| `searchController` | ช่องค้นหาสินค้า |
| `receivedAmountController` | รับเงินมากี่บาท |
| `noteController` | หมายเหตุ |

---

## การโหลดข้อมูลตอนเปิดหน้า

```
CheckoutPage.build()
      ↓
Get.put(CheckoutController())
      → onInit():
            checkShopAndLoadData()
            receivedAmountController.addListener(...)  ← คำนวณเงินทอน realtime
            เช็ค arguments: barcode → addProductByBarcode
                            selectedIds → addItemsByIds
      ↓
addPostFrameCallback → fetchFreshProducts()
      ← โหลดสินค้าใหม่ทุกครั้งที่เปิดหน้า (refresh stock)
```

### `checkShopAndLoadData()` — ตรวจร้านค้าก่อนโหลด

```dart
// ซิงค์ shopId ให้ ParkOrderController ก่อนเสมอ
_parkCtrl.currentShopId.value = currentShopId;

// ถ้า shopId เปลี่ยน (สลับร้าน) → รีเซ็ตทุกอย่าง
if (loadedShopId != currentShopId) {
    allProducts.clear();
    cartItems.clear();
    searchResults.clear();
    // แล้วโหลดใหม่
    await _loadAllProducts();
    await _fetchShopData();
}
```

### `_fetchProductsFromApi()` — ดึงสินค้า 2 ประเภทพร้อมกัน

```
API 1: getProductsByShop(limit: 1000)    → สินค้ามีบาร์โค้ด
API 2: getNullBarcodeProducts(shopId)    → สินค้าไม่มีบาร์โค้ด
      ↓ merge ทั้งสอง (dedup ด้วย productId)
      ↓ กรองเฉพาะ status == true
      ↓ allProducts = ผลรวม
```

### `_fetchShopData()` — ดึง QR Code ร้าน

```dart
// แนบ timestamp กันรูปถูก cache เก่า
shopQrCodeUrl.value = url + "?t=${DateTime.now().millisecondsSinceEpoch}";
```

---

## การค้นหาสินค้า (`onSearchChanged`)

### ปัญหา Race Condition ที่แก้แล้ว

> ถ้าพิมพ์ "a" → "ab" ติดกันรวดเร็ว ผลของ "a" (ช้ากว่า) อาจมาทับผลของ "ab" ทำให้รายการหายวับ

### วิธีแก้: `_searchRequestId`

```dart
int _searchRequestId = 0;

void onSearchChanged(String query) async {
    final int requestId = ++_searchRequestId;  // เพิ่มเลข version

    // ค้นหา local cache ก่อน
    if (localMatches.isNotEmpty) {
        if (requestId != _searchRequestId) return;  // มีใหม่กว่าแล้ว ทิ้ง
        searchResults.assignAll(localMatches);
        return;
    }

    // fallback API
    final product = await ApiProduct.searchProduct(query, shopId);
    if (requestId != _searchRequestId) return;  // มีใหม่กว่าแล้ว ทิ้ง
    searchResults.assignAll([product]);
}
```

### ป้องกัน `isSearchLoading` ค้าง

```dart
// ครอบด้วย try/finally ทั้งฟังก์ชัน
try {
    // ค้นหา...
} finally {
    if (requestId == _searchRequestId) isSearchLoading.value = false;
}
// เดิม: ถ้าเจอใน local cache → ไม่มีจุดไหน reset เป็น false เลย → spinner ค้างตลอด
```

### Flow ค้นหา

```
พิมพ์ในช่องค้นหา
      → isSearching = true (สลับจากหน้าตะกร้า → หน้าค้นหา)
      → isSearchLoading = true (spinner)
      → ค้นใน allProducts (ชื่อ / บาร์โค้ด)
            เจอ → searchResults, isSearchLoading = false
            ไม่เจอ → ApiProduct.searchProduct(API)
                    เจอ → searchResults
                    ไม่เจอ → searchResults.clear()
                    finally → isSearchLoading = false

ลบคำค้น (query.isEmpty)
      → isSearching = false (กลับหน้าตะกร้า)
      → searchResults.clear()
```

---

## การจัดการตะกร้าสินค้า

### โครงสร้างข้อมูลตะกร้า

```
cartItems = [ProductItem, ProductItem, ProductItem, ...]
// สินค้าชิ้นเดียวกัน = element หลายตัว (1 ชิ้น = 1 element)
// ตอนแสดงผล → group by item.id ก่อน

groupedItems = {
    "101": [item, item, item],   // สินค้า 101 จำนวน 3 ชิ้น
    "205": [item],               // สินค้า 205 จำนวน 1 ชิ้น
}
```

> **ทำไมไม่เก็บ `quantity` ใน ProductItem?**
> เพราะ `cartItems.fold(0, (sum, item) => sum + item.price)` คำนวณยอดรวมได้ง่ายโดยไม่ต้องคิดราคา × จำนวนเอง

### เพิ่มสินค้า `_addToCart()`

```dart
int currentQty = cartItems.where((i) => i.id == product.productId.toString()).length;
if (currentQty < product.stock) {
    cartItems.add(ProductItem(...));  // เพิ่ม element
} else {
    Get.snackbar("ถึงจำนวนสูงสุดแล้ว", "สต็อก ${product.stock} ชิ้น");
}
```

### เพิ่มจำนวน `increaseItem()` / ลด `decreaseItem()`

```dart
// increaseItem: เช็คสต็อกจาก allProducts (ไม่ใช้ snapshot เก่าใน cart)
int maxStock = _currentMaxStock(item);  // ดึงสต็อกล่าสุดจาก allProducts
if (currentQty < maxStock) cartItems.add(...);

// decreaseItem: ลบ element สุดท้ายที่ id ตรงกัน
int index = cartItems.indexWhere((e) => e.id == item.id);
if (index != -1) cartItems.removeAt(index);
```

### ตั้งจำนวนโดยตรง `setItemQuantity()`

```dart
// ใช้เมื่อผู้ใช้พิมพ์จำนวนใน Dialog แทนกด +/- ทีละครั้ง
final clamped = newQty.clamp(0, maxStock);   // กันเกินสต็อก

if (clamped > currentQty) {
    // เพิ่ม: addAll List.generate(toAdd, ...)
} else {
    // ลด: วนลบจากท้ายสุด ไม่ให้ลบผิดตัว
    for (int i = cartItems.length - 1; i >= 0 && toRemove > 0; i--) {
        if (cartItems[i].id == item.id) { cartItems.removeAt(i); toRemove--; }
    }
}
```

### ลบสินค้าทั้งหมด `removeItem()` + ปุ่ม Delete

```
แตะที่ row สินค้า
      → toggleDelete(item): แสดงปุ่มลบแดง (AnimatedContainer slide-in)
        ปุ่มอื่น → ซ่อนปุ่มลบทั้งหมดก่อน แล้ว toggle ตัวที่แตะ

กดปุ่มลบแดง
      → removeItem(item): cartItems.removeWhere(e.id == item.id)
        ลบทุก element ของสินค้านั้นออกหมด
```

### `_currentMaxStock()` — สต็อกล่าสุด

```dart
// ดึงจาก allProducts แทนค่า snapshot ใน cart
// กันกรณี: หยิบสินค้าใส่ตะกร้าตอนสต็อก 5
//          แต่มีการขายจากเครื่องอื่นเหลือ 2
//          → ป้องกันขายเกินสต็อกจริง
int _currentMaxStock(ProductItem item) {
    final match = allProducts.firstWhereOrNull((p) => p.productId.toString() == item.id);
    return match?.stock ?? item.maxStock;
}
```

---

## Dialog พิมพ์จำนวน (`_showEditQuantityDialog`)

```
แตะที่ "N ชิ้น ✏️" ใต้ชื่อสินค้า
      ↓
Dialog: ช่องตัวเลข autofocus + แสดง "มีในสต็อก X ชิ้น"
      ↓
พิมพ์จำนวน → กด "ยืนยัน" (หรือ Enter)
      ↓
ถ้า > maxStock → แสดง errorText ใต้ช่อง (ไม่ปิด dialog)
ถ้า ≤ maxStock → setItemQuantity() → ปิด dialog
```

---

## พักออเดอร์ (`parkOrder` / `resumeOrder`)

### `parkOrder()` — พักตะกร้าปัจจุบัน

```
ตะกร้าว่าง? → snackbar เตือน
      ↓
_parkCtrl.parkCurrentOrder(cartItems.toList())
      ↓
clearAll() + clear note + clear receivedAmount
      ↓
snackbar "พักออเดอร์แล้ว"
```

### `resumeOrder(parkId)` — กู้ออเดอร์ที่พักไว้

```
✅ เช็คว่าเจอออเดอร์ก่อน ค่อยล้างตะกร้า
(เดิม: ล้างก่อน → ถ้าไม่เจอ → ของในตะกร้าหาย)

parked = _parkCtrl.retrieveOrder(parkId)
      ↓ เจอ:
ถ้า cartItems ไม่ว่าง → park ออเดอร์ปัจจุบันก่อน (ไม่ให้หาย)
clearAll()
      ↓
วนใส่ cartItems ทีละชิ้น:
    effectiveMaxStock = allProducts[productId].stock ?? parked.maxStock
    qty = parked.quantity.clamp(0, effectiveMaxStock)
    if qty < parked.quantity → stockReduced = true

✅ stockReduced = true → snackbar เตือน
(เดิม: ปรับลดเงียบๆ แคชเชียร์ไม่รู้)
```

---

## Flow ชำระเงิน (เงินสด / โอน)

### 1. กดปุ่ม "ชำระเงิน"

```
openPaymentSheet(context, false, _PaymentBottomSheet)
      → ตรวจตะกร้าว่าง? → snackbar
      → reset: paymentMethod = "จ่ายเงินสด", clear receivedAmount
      → showModalBottomSheet(_PaymentBottomSheet)
```

### 2. หน้า Payment Bottom Sheet

```
DraggableScrollableSheet (ปรับขนาดได้ 50%–95%)
      ├── ยอดรวม (ตัวเลขใหญ่ 40px)
      ├── ChoiceChip: [จ่ายเงินสด] [โอนจ่าย]
      │
      ├── ถ้า "จ่ายเงินสด":
      │     ├── ช่อง "รับเงินมา" (กรอกได้)
      │     └── กล่อง "เงินทอน" (คำนวณ realtime)
      │
      ├── ถ้า "โอนจ่าย":
      │     └── QR Code ร้าน (220×220)
      │
      ├── ช่องหมายเหตุ
      └── ปุ่ม "ยืนยันการทำรายการ" (disable + spinner ถ้ากำลัง submit)
```

### 3. กด "ยืนยันการทำรายการ" → `confirmPayment(processPayment)`

```
เช็คตะกร้าว่าง? → Warning dialog
เช็ค paymentMethod == "จ่ายเงินสด" && received < total?
      → Warning "ยอดเงินไม่พอ"
      ↓ ผ่านทั้งหมด
เปิด Popup ยืนยัน:
      จำนวนรายการ: N ชิ้น
      วิธีชำระเงิน: จ่ายเงินสด / โอนจ่าย
      ยอดสุทธิ: XXX ฿
      [กลับไปแก้ไข] [ยืนยัน]
      ↓ กด "ยืนยัน"
Get.back() ← ปิด popup
processPayment()
```

> **`confirmPayment`** รับ `VoidCallback processPaymentFunc` แทนเรียกตรงๆ เพื่อให้นำไปใช้ซ้ำได้กับ function อื่นในอนาคต

### 4. `processPayment()` — บันทึกการขายจริง

```dart
if (isProcessingPayment.value) return;  // กันกดซ้ำ
isProcessingPayment.value = true;

// แสดง Loading dialog
Get.dialog(CircularProgressIndicator);

// Group cartItems by productId
// รวมราคาจริงทุกชิ้น (ไม่ใช้ราคาล่าสุด × จำนวน)
// เผื่อราคาสินค้าเดียวกันเปลี่ยนกลางทาง
pricePerUnit = totalPrice / amount;  // ราคาเฉลี่ย

SaleRequest {
    paymentMethod: "จ่ายเงินสด" หรือ "โอนจ่าย"
    pay: ถ้าโอนจ่าย → ใช้ totalPrice (ไม่มีช่องกรอก)
         ถ้าเงินสด  → ใช้ receivedAmount
}
      ↓
ApiSale.createSale(saleRequest)
      ↓ สำเร็จ (result['sale_id'] exists):
          Get.back()        ← ปิด Loading
          Get.back()        ← ปิด Payment sheet
          _showSuccessDialog()
          clearAll()
          noteController.clear()
          await _loadAllProducts()   ← โหลดสต็อกใหม่
      ↓ ล้มเหลว:
          _showErrorDialog(result['error'])
```

---

## Flow ค้างชำระ

```
กดปุ่ม "ค้างชำระ"
      ↓
goToDebtPaymentPage()
      ↓
Get.to(DebtSalePage)
      (ตะกร้า cartItems ยังอยู่ DebtSalePage อ่านจาก CheckoutController โดยตรง)
```

---

## `openCashPaymentSheet` — เปิดจ่ายเงินสดจากหน้าอื่น

```dart
// CheckoutPage กำหนดให้ตอน build()
controller.openCashPaymentSheet = (ctx) => controller.openPaymentSheet(
    ctx, false, _PaymentBottomSheet(controller: controller),
);

// DebtSalePage เรียกได้เลย (เมื่อจ่ายครบ ไม่มียอดค้าง)
checkoutController.openCashPaymentSheet!(ctx);
```

> ทำไมไม่ call โดยตรง? เพราะ `_PaymentBottomSheet` เป็น private Widget ในไฟล์ checkout_page ไม่สามารถสร้างจากที่อื่นได้ จึงเก็บ callback ไว้แทน

---

## การดักบัคสำคัญ

| บัค | สาเหตุ | วิธีแก้ |
|---|---|---|
| **Search result เก่าทับใหม่** | async race: "a" ช้ากว่า "ab" แต่มาทีหลัง | `_searchRequestId` version counter |
| **isSearchLoading ค้าง** | เจอ local cache → ออกก่อน → ไม่มีจุด reset | `try/finally` ครอบทั้งฟังก์ชัน |
| **กดยืนยันชำระเงินซ้ำ** | async delay ระหว่าง submit | `isProcessingPayment` flag |
| **ลบตะกร้าแล้ว resume ไม่เจอ** | ล้างตะกร้าก่อนเช็ค parkId | เช็คก่อน ค่อยล้าง (safe pattern) |
| **สต็อก snapshot เก่าในตะกร้า** | หยิบตอนสต็อก 5 แต่เหลือ 2 แล้ว | `_currentMaxStock()` ดึงจาก allProducts เสมอ |
| **ออเดอร์พักข้ามร้าน** | ParkOrderController เป็น permanent singleton | ซิงค์ `currentShopId` ทุกครั้งที่เปิดหน้า |
| **QR Code ถูก cache เก่า** | Image.network cache รูป URL เดิม | แนบ `?t=timestamp` ทุก fetch |
| **ฟอนต์ใหญ่ทำ layout ล้น** | ผู้ใช้ตั้งฟอนต์ใหญ่ | `MediaQuery.clamp(maxScaleFactor: 1.2)` ทั้งหน้า + ทุก dialog |
| **ราคาเฉลี่ยผิด** | ราคาเดียวกันเปลี่ยนกลางทาง แล้วใช้ราคาล่าสุด × N | สะสม `totalPrice` จริงทีละ element |

---

## สรุป Flow ทั้งหมด

```
เปิดหน้า → โหลดสินค้า (มีบาร์โค้ด + ไม่มี) + QR Code
      ↓
ค้นหาสินค้า (Local → API fallback, Anti-race condition)
      ↓
เลือกสินค้า → เพิ่มตะกร้า (เช็คสต็อกก่อน)
      ↓
จัดการตะกร้า: +/- / พิมพ์จำนวน / ลบ / พักออเดอร์
      ↓
กดชำระเงิน → Payment Sheet → เลือกวิธีจ่าย
      → เงินสด: กรอกรับเงิน + เงินทอน realtime
      → โอน: แสดง QR Code
      ↓
ยืนยัน → confirmPayment (Validate) → Popup → processPayment (API)
      ↓ สำเร็จ → clear ตะกร้า → reload สต็อก
      ↓ หรือ ค้างชำระ → DebtSalePage (ใช้ cartItems เดิม)
```
