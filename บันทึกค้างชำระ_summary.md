# หน้า "บันทึกค้างชำระ" (DebtSalePage)

> **ไฟล์ที่เกี่ยวข้อง**
> - UI: [`debt_sale.dart`](file:///z:/eazy_store/lib/page/debt/debtSale/debt_sale.dart)
> - Controller: [`debt_sale_controller.dart`](file:///z:/eazy_store/lib/page/debt/debtSale/debt_sale_controller.dart)
> - สมุดลูกหนี้: [`debtor_book_sheet.dart`](file:///z:/eazy_store/lib/page/debt/debtSale/debtor_book_sheet.dart)

---

## วัตถุประสงค์

บันทึกการขายแบบ **"ค้างชำระ"** — ลูกค้าซื้อสินค้าแต่ยังไม่ได้จ่ายครบ โดยผูกกับบัญชีลูกหนี้ที่มีอยู่ในระบบ

---

## โครงสร้าง UI

```
AppBar: "บันทึกค้างชำระ"

Body:
  ├── [1] การ์ดเลือกลูกหนี้     (แตะ → เปิดสมุดลูกหนี้)
  ├── [2] รายการสินค้าในตะกร้า  (ดึงจาก CheckoutController)
  └── [3] กล่องสรุปการค้างชำระ
          ├── รวมทั้งหมด
          ├── ชื่อคนเซ็น (read-only จากลูกหนี้ที่เลือก)
          ├── เบอร์โทรศัพท์ (read-only)
          ├── จ่ายตอนนี้ (กรอกเองได้)
          ├── ยอดที่เซ็นค้าง (คำนวณอัตโนมัติ)
          ├── เงินทอน (แสดงเมื่อจ่ายเกิน)
          ├── กล่องเตือน (แสดงเมื่อจ่ายครบ/เกิน)
          └── หมายเหตุ

ปุ่มด้านล่าง (sticky):
  ├── [ล้าง]
  └── [ยืนยันการค้างชำระ] หรือ [ไปคิดเงินสด]  ← สลับอัตโนมัติ
```

---

## State ใน Controller

| Variable | ประเภท | ความหมาย |
|---|---|---|
| `selectedDebtorRx` | `Rxn<DebtorResponse>` | ลูกหนี้ที่เลือกอยู่ (null = ยังไม่เลือก) |
| `payAmount` | `RxDouble` | ยอดที่ลูกค้าจ่ายมาตอนนี้ (sync กับ TextController) |
| `isSubmitting` | `RxBool` | กันกด submit ซ้ำ |
| `allDebtors` | `RxList<DebtorResponse>` | รายชื่อลูกหนี้ทั้งหมด (cache ในเครื่อง) |
| `bookResults` | `RxList<DebtorResponse>` | ผลค้นหาที่แสดงในสมุด |
| `isLoadingBook` | `RxBool` | กำลังโหลดสมุดลูกหนี้ |
| `isSearchingBook` | `RxBool` | กำลังค้นหาจาก Server |
| `bookKeyword` | `RxString` | คำค้นหาปัจจุบัน |
| `bookError` | `RxString` | ข้อความ error จากการโหลดสมุด |

### TextEditingControllers

| Controller | ใช้สำหรับ | หมายเหตุ |
|---|---|---|
| `debtorNameController` | ชื่อลูกหนี้ | read-only (ใส่อัตโนมัติ) |
| `debtorPhoneController` | เบอร์โทร | read-only |
| `payAmountController` | จ่ายตอนนี้ | default = `"0"`, กรอกได้ |
| `debtRemarkController` | หมายเหตุ | optional |
| `bookSearchController` | ค้นหาในสมุด | อยู่ใน DebtorBookSheet |

---

## การคำนวณยอดเงิน (Realtime)

```dart
// ทุกครั้งที่ผู้ใช้พิมพ์ใน "จ่ายตอนนี้"
payAmountController.addListener(() {
  payAmount.value = double.tryParse(payAmountController.text) ?? 0.0;
});
```

จาก `payAmount` และ `totalPrice` จาก CheckoutController:

```
remainingDebt = max(0, totalPrice - payAmount)   // ยอดค้าง (ไม่ติดลบ)
changeAmount  = max(0, payAmount - totalPrice)   // เงินทอน (ถ้าจ่ายเกิน)
creditRemain  = max(0, debtor.creditLimit - debtor.currentDebt)  // วงเงินที่เหลือ
```

### ตัวอย่าง

| สินค้า | จ่ายตอนนี้ | ยอดค้าง | เงินทอน |
|---|---|---|---|
| 500 บาท | 0 | **500** | 0 |
| 500 บาท | 200 | **300** | 0 |
| 500 บาท | 500 | **0** | 0 |
| 500 บาท | 600 | **0** | **100** |

---

## ปุ่มด้านล่าง — สลับอัตโนมัติ

```dart
bool isCashCase = payAmount.value > 0 && remainingDebt(total) <= 0;
```

| เงื่อนไข | ปุ่มที่แสดง | Action |
|---|---|---|
| ยังมียอดค้าง | **"ยืนยันการค้างชำระ"** (เขียว) | `confirmSubmit()` |
| จ่ายครบ/เกิน | **"ไปคิดเงินสด"** (ฟ้า) | `switchToCashCheckout()` |

> `Obx` ครอบปุ่มด้านล่าง ทำให้สลับทันทีที่ผู้ใช้แก้ตัวเลข "จ่ายตอนนี้"

---

## Flow 1: เลือกลูกหนี้ (สมุดลูกหนี้)

```
แตะการ์ด "เลือกลูกหนี้"
      ↓
openDebtorBook()
      ├── unfocus keyboard
      ├── clear bookSearchController
      ├── DebtorBookSheet.show(this)   ← เปิด Bottom Sheet
      └── loadAllDebtors()
```

### `loadAllDebtors()`

```dart
// ถ้า cache มีอยู่แล้ว → ไม่ดึง API ซ้ำ
if (allDebtors.isNotEmpty && !forceRefresh) {
  filterBook(bookSearchController.text);
  return;
}

// ดึงมาทีเดียวทั้งหมด
ApiDebtor.getDebtorsByShop(shopId, page: 1, limit: 1000)
    ↓
เรียงตามตัวอักษร (case-insensitive)
    ↓
allDebtors.assignAll(list)
    ↓
filterBook(...)  // กรองตาม keyword ที่พิมพ์ไว้
```

### การค้นหาในสมุด — 2 ชั้น (`filterBook`)

```
พิมพ์ใน bookSearchController
      ↓
ค้นจาก allDebtors ใน memory ก่อน (ชื่อ + เบอร์)
      ↓ ถ้าเจอ → แสดงทันที
      ↓ ถ้าไม่เจอ + keyword ≥ 2 ตัว
          → debounce 400ms
          → ApiDebtor.searchDebtor(keyword)
          → เช็ค stale: bookSearchController.text == key?
          → ถ้าตรง → bookResults.assignAll(results)
          → ถ้าไม่ตรง → ทิ้งผล (ผู้ใช้พิมพ์ต่อไปแล้ว)
```

> **Anti-stale** กันผลค้นหาเก่า override ผลค้นหาใหม่ — ถ้าพิมพ์ "ก" แล้วพิมพ์ "กา" ทัน ผลของ "ก" จะถูกทิ้งทั้งที่มาทีหลัง

### `groupedBookResults()` — จัดกลุ่มตามตัวอักษร

```dart
// ตัวอย่างผลลัพธ์:
{
  "ก": [กมลา, กาญจนา],
  "ข": [ขวัญ],
  "ส": [สมชาย, สุดา],
}
```

แสดงเป็น sticky header แต่ละตัวอักษร + รายชื่อด้านล่าง

### กดเลือกลูกหนี้

```dart
selectDebtorFromBook(debtor)
    → Get.back()           // ปิดสมุด
    → selectDebtor(debtor)
          → selectedDebtorRx.value = debtor
          → debtorNameController.text = debtor.name
          → debtorPhoneController.text = debtor.phone
          → unfocus keyboard
```

---

## Flow 2: กด "ยืนยันการค้างชำระ" (`confirmSubmit`)

### ขั้นตอน Validation (ก่อนแสดง Popup)

```
1. ตะกร้าว่าง?                       → showErrorDialog
2. ไม่ได้เลือกลูกหนี้?               → showErrorDialog
3. remainingDebt <= 0?
      จ่ายเกิน → แจ้งให้ใช้หน้าเงินสด
      จ่ายพอดี → แจ้งให้ใช้หน้าเงินสด
4. ↓ Refresh ข้อมูลลูกหนี้จาก Server
      ApiDebtor.searchDebtor(phone) → เช็ค debtorId ตรงกัน
      ถ้า refresh ได้ → อัปเดต selectedDebtorRx (ข้อมูลล่าสุด)
      ถ้า fail → ใช้ cache เดิม (ไม่ block)
5. debtValue > creditRemain?          → showErrorDialog (แจ้งวงเงินที่เหลือ)
6. ↓ เปิด Popup ยืนยัน
```

### Popup ยืนยัน แสดง

```
ลูกหนี้:               สมชาย
ยอดสินค้า:            1,500.00 ฿
จ่ายล่วงหน้า:          300.00 ฿
วงเงินคงเหลือหลังเซ็น:  700.00 ฿
──────────────────────────────
ยอดที่เซ็น:            1,200.00 ฿   (สีแดง)

[ยกเลิก]  [ยืนยัน]
```

> **จุดสำคัญ**: ปุ่มมองเห็นได้ทันทีโดยไม่ต้องเลื่อน เพราะใช้ `Column(mainAxisSize: MainAxisSize.min)` + `MediaQuery.clamp`

---

## Flow 3: `submitDebt()` — บันทึกจริง

```dart
if (isSubmitting.value) return;  // กันกดซ้ำ
isSubmitting.value = true;

// รวมสินค้าใน cartItems (group by productId)
// คำนวณราคาจริงตาม quantity
List<SaleItemRequest> itemsRequest = ...;

// ⚠️ ถ้าจ่ายเกินยอด → ตัดเป็นเท่ากับ total
// (กันเซิร์ฟเวอร์เอาส่วนเกินไปหักหนี้ก้อนเก่า)
effectivePay = min(payAmount, total);

SaleRequest {
  paymentMethod: "ค้างชำระ",
  debtorId: selectedDebtor.debtorId,
  netPrice: total,
  pay: effectivePay,
  note: debtRemarkController.text,
}
      ↓
ApiSale.createCreditSale(saleRequest)
      ↓ สำเร็จ → clearAll() → Get.offAll(HomePage)
      ↓ ล้มเหลว → showErrorDialog(errorMsg)
```

---

## Flow 4: กด "ไปคิดเงินสด" (`switchToCashCheckout`)

ใช้เมื่อลูกค้าจ่ายครบ/เกิน ไม่มียอดค้าง:

```
เคลียร์ payAmountController, debtRemarkController
(ไม่แตะ cartItems — สินค้ายังอยู่ครบ)
      ↓
Get.back()  ← กลับหน้า Checkout
      ↓
WidgetsBinding.addPostFrameCallback(...)
      ↓  (รอ UI render เสร็จก่อน)
checkoutController.openCashPaymentSheet(ctx)
      ↓
ถ้า payAmount > 0 → ใส่ยอดใน receivedAmountController อัตโนมัติ
```

> **`addPostFrameCallback`** จำเป็น เพราะ `Get.back()` ยังไม่ได้ย้าย route ทันที — ถ้าเรียก `openCashPaymentSheet` ทันทีจะ error เพราะ Checkout ยังไม่ได้ mount

---

## Flow 5: สร้างลูกหนี้ใหม่ (`goToRegisterDebtor`)

```
Get.to(DebtRegisterScreen)
      ↓ รอผลลัพธ์
result is DebtorResponse?
      ↓ ใช่:
          allDebtors.clear()    ← บังคับโหลดสมุดใหม่ครั้งหน้า
          selectDebtor(result)  ← เลือกลูกหนี้ที่เพิ่งสมัครทันที
          snackbar "เลือกลูกหนี้แล้ว"
```

---

## Flow 6: ปุ่ม "ล้าง" (`confirmClearForm`)

```
ConfirmDialog.show(...)  ← ถาม "ยืนยันล้างหรือไม่?"
      ↓ กด "ล้าง"
clearForm():
  debtorNameController.clear()
  debtorPhoneController.clear()
  payAmountController.text = '0'   ← reset เป็น default
  debtRemarkController.clear()
  selectedDebtorRx.value = null
  checkoutController.clearAll()    ← เคลียร์ตะกร้าด้วย
```

---

## การดักบัคทั้งหมด

| บัค | สาเหตุ | วิธีแก้ |
|---|---|---|
| **วงเงินล้าสมัย** | ร้านอื่น/เครื่องอื่นบันทึกหนี้พร้อมกัน | Refresh ข้อมูลลูกหนี้จาก Server ก่อนเช็ควงเงินทุกครั้ง |
| **กดยืนยันซ้ำ 2 ครั้งรวดเร็ว** | async delay ทำให้ submit 2 รอบ | `isSubmitting` flag กัน |
| **Popup โดนคีย์บอร์ดดัน** | keyboard ยังค้างเปิดอยู่ | `unfocus()` ก่อนเปิด dialog ทุก case |
| **ฟอนต์ใหญ่ layout ล้น** | ผู้ใช้ตั้งฟอนต์ใหญ่มากในระบบ | `MediaQuery.clamp(maxScaleFactor: 1.2)` ทั้งหน้า + ทุก dialog |
| **ผลค้นหาเก่า (stale) ทับผลใหม่** | API ช้า + พิมพ์ต่อเนื่อง | เช็ค `bookSearchController.text == key` ก่อน assign |
| **จ่ายเกินยอด → หักหนี้เก่า** | Server ใช้ `pay` ไปหักหนี้ก้อนเก่า | `effectivePay = min(payAmount, total)` |
| **cache สมุดลูกหนี้ไม่สด** | สมัครลูกหนี้ใหม่แต่สมุดยังเป็นข้อมูลเก่า | `allDebtors.clear()` หลังสมัครสำเร็จ |
| **`openCashPaymentSheet` crash** | เรียกทันทีหลัง `Get.back()` ก่อน UI render | `addPostFrameCallback` เพื่อรอ frame ถัดไป |
| **ค้นหาแล้ว loader ค้าง** | `isSearchingBook` ไม่ถูก reset ถ้า throw | ครอบด้วย `try/finally` |

---

## สรุป Flow ทั้งหมด

```
เปิดหน้า DebtSalePage
      ↓
[เลือกลูกหนี้] → สมุดลูกหนี้ → ค้นหา → เลือก → กรอกชื่อ/เบอร์ให้อัตโนมัติ
      ↓
[เพิ่มสินค้า] (จาก CheckoutController.cartItems — เพิ่มจากหน้าหลัก/สมุดสินค้า)
      ↓
[กรอก "จ่ายตอนนี้"]
      → Realtime คำนวณยอดค้าง / เงินทอน
      → ปุ่มสลับระหว่าง "ยืนยันค้างชำระ" ↔ "ไปคิดเงินสด"
      ↓
[ยืนยันการค้างชำระ]
      → Validate หลายชั้น (ตะกร้า, ลูกหนี้, ยอด, วงเงิน)
      → Refresh ข้อมูลลูกหนี้จาก Server
      → Popup ยืนยัน
      → submitDebt() → API → HomePage
```
