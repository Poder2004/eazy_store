# หน้า "สมุดสินค้า" (ManualListPage)

> **ไฟล์ที่เกี่ยวข้อง**
> - UI: [`book_list_no_barcode.dart`](file:///z:/eazy_store/lib/page/sale_producct/bookListNoBarcode/book_list_no_barcode.dart)
> - Controller: [`book_list_no_barcode_controller.dart`](file:///z:/eazy_store/lib/page/sale_producct/bookListNoBarcode/book_list_no_barcode_controller.dart)

---

## วัตถุประสงค์

ให้ผู้ใช้เลือกสินค้าเพิ่มเข้าตะกร้าโดย **ไม่ต้องสแกนบาร์โค้ด** — กาเลือกหลายรายการแล้วเพิ่มทีเดียว

---

## โครงสร้าง UI

```
AppBar: "สมุดสินค้า"
  └── TabBar (Segmented Style)
        ├── แท็บ 1: ไม่มีบาร์โค้ด
        └── แท็บ 2: มีบาร์โค้ด

Body:
  ├── ช่องค้นหา + ปุ่มกรอง  (ใช้ร่วมกันทั้ง 2 แท็บ)
  ├── TabBarView
  │     ├── แท็บ 1: ListView การ์ดสินค้า + Pagination
  │     └── แท็บ 2: ListView การ์ดสินค้า + Pagination
  └── ปุ่ม "เพิ่มลงรายการขาย (N)"
```

---

## การโหลดข้อมูล (onInit)

เมื่อเปิดหน้า จะดึงข้อมูล **3 อย่างพร้อมกัน** ด้วย `Future.wait`:

| ฟังก์ชัน | ดึงอะไร |
|---|---|
| `fetchCategories()` | หมวดหมู่สินค้า → ใช้ในตัวกรอง |
| `fetchProducts()` | สินค้าที่ **ไม่มีบาร์โค้ด** จาก `ApiProduct.getNullBarcodeProducts()` |
| `fetchBarcodeProducts()` | สินค้าที่ **มีบาร์โค้ด** จาก `ApiProduct.getProductsByShop()` |

> ขณะโหลด แสดง **Skeleton Loading** (การ์ดปลอม 6 ใบ) ให้ UI ไม่ว่างเปล่า

---

## State หลักใน Controller

| Variable | ประเภท | ความหมาย |
|---|---|---|
| `allProducts` | `RxList<ProductItem>` | สินค้าทั้งหมด (ไม่มีบาร์โค้ด) |
| `allBarcodeProducts` | `RxList<ProductItem>` | สินค้าทั้งหมด (มีบาร์โค้ด) |
| `filteredProducts` | `RxList<ProductItem>` | หลังกรอง+เรียง (ก่อนตัดหน้า) |
| `pagedProducts` | `RxList<ProductItem>` | หน้าปัจจุบันที่แสดงจริง |
| `selectedIds` | `RxSet<String>` | ID สินค้าที่ถูกเลือก (ใช้ร่วม 2 แท็บ) |
| `searchQuery` | `RxString` | คำค้นหาปัจจุบัน |
| `selectedCategoryId` | `RxInt` | หมวดหมู่ที่กรอง (0 = ทั้งหมด) |
| `selectedSortOption` | `RxString` | วิธีเรียง เช่น `name_asc`, `stock_desc` |

---

## การค้นหาและกรอง

```
พิมพ์ในช่องค้นหา
    → debounce 300ms (กันยิง API ถี่เกินไป)
    → filterProducts()
        ├── _filterNoBarcode()  กรองแท็บ 1
        └── _filterBarcode()    กรองแท็บ 2
```

```
กดปุ่มกรอง (เลือกหมวด / จัดเรียง)
    → applyFilter(categoryId, sortOption)
    → refreshProducts()  → ดึงข้อมูลใหม่จาก API พร้อมส่ง categoryId ไปด้วย
```

### ตัวเลือกการจัดเรียง

| ค่า | ความหมาย |
|---|---|
| `name_asc` | ชื่อ ก→ฮ (Thai sort) |
| `name_desc` | ชื่อ ฮ→ก |
| `stock_asc` | สต็อกน้อยไปมาก |
| `stock_desc` | สต็อกมากไปน้อย |

---

## Pagination (ตัดหน้าฝั่ง Client)

ข้อมูลโหลดมาครบแล้ว แล้วค่อยตัดแบ่งหน้าใน memory:

```
filteredProducts (ทั้งหมด N รายการ)
    ↓ _paginateNoBarcode()
pagedProducts  (แสดงแค่ หน้าปัจจุบัน × itemsPerPage)
```

> แท็บ 1 และแท็บ 2 มี pagination **แยกจากกัน** — `currentPage` / `currentPageBarcode`

---

## การเลือกสินค้า (Toggle Selection)

```dart
// กดการ์ดสินค้า
toggleSelection(id):
  ถ้า id อยู่ใน selectedIds → เอาออก (ยกเลิกเลือก)
  ถ้า id ไม่อยู่            → เพิ่มเข้า (เลือก)
```

- **Checkbox** ในการ์ดแต่ละใบใช้ `Obx` ดู `selectedIds` → เปลี่ยนสีทันที
- `selectedIds` ใช้ร่วมกันทั้ง 2 แท็บ — เลือกจากแท็บไหนก็รวมในตะกร้าเดียวกัน

---

## กดปุ่ม "เพิ่มลงรายการขาย"

```
goToCheckout()
    ├── เช็คว่าเลือกสินค้าอย่างน้อย 1 ชิ้น
    ├── checkoutCtrl.addItemsByIds(selectedIds)
    │       → เพิ่มสินค้าลงตะกร้า CheckoutController
    │       → เช็คสต็อก (ถ้าหมดก็ไม่เพิ่ม)
    │       → return จำนวนที่เพิ่มสำเร็จ
    │
    ├── ถ้า addedCount > 0
    │       → ล้าง selectedIds
    │       → snackbar "สำเร็จ"
    │
    └── Navigation:
          ถ้า _cameFromCheckout = true  → Get.close(2)   ← ปิด 2 หน้ากลับ Checkout เดิม
          ถ้าไม่ได้มาจาก Checkout      → Get.to(CheckoutPage)
```

> **`_cameFromCheckout`** ถูกส่งมาจาก `ScanBarcodeController` ผ่าน `Get.arguments` เพราะพอถึงหน้านี้แล้ว `Get.previousRoute` จะเป็นหน้าสแกนเสมอ ไม่สามารถเช็คย้อนไปถึง CheckoutPage ได้

---

## Flow สรุป

```
เปิดหน้า
    ↓
โหลด: หมวดหมู่ + สินค้าไม่มีบาร์โค้ด + สินค้ามีบาร์โค้ด (พร้อมกัน)
    ↓
ผู้ใช้ ค้นหา / กรอง / เรียง  →  แสดงผลทันที (debounce 300ms)
    ↓
กดการ์ดสินค้า  →  checkbox ติ๊ก / ยกเลิก
    ↓
กด "เพิ่มลงรายการขาย (N)"
    ↓
เพิ่มสินค้าเข้าตะกร้า  →  กลับหน้า Checkout
```
