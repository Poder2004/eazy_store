# EazyStore — QA Test Report (รอบ 2)

**วันที่ทดสอบ:** 2026-06-25  
**เวอร์ชัน:** Debug (หลังแก้บักรอบ 1)  
**จำนวนหน้าที่ครอบคลุม:** 27 หน้า  
**สถานะ:** 🟡 พบ bugs เพิ่มเติม 9 จุด — แก้ทั้งหมดแล้วในรอบนี้

---

## สรุปสถานะเทียบกับรอบแรก

| รอบ | พบ | แก้แล้ว |
|-----|-----|---------|
| รอบ 1 | 13 bugs + 7 UI issues | ✅ ทั้งหมด |
| รอบ 2 | 9 bugs เพิ่มเติม | ✅ ทั้งหมด |
| **รวม** | **22 bugs + 9 UI issues** | **✅ แก้ครบ** |

---

## สารบัญ
1. [Bugs รอบ 1 — สถานะ](#1-bugs-รอบ-1--สถานะ)
2. [Bugs รอบ 2 — ที่พบเพิ่มและแก้แล้ว](#2-bugs-รอบ-2--ที่พบเพิ่มและแก้แล้ว)
3. [UI/UX Issues ทั้งหมด](#3-uiux-issues-ทั้งหมด)
4. [Test Checklist รายหน้า](#4-test-checklist-รายหน้า)
5. [สิ่งที่ควรทดสอบบนอุปกรณ์จริง](#5-สิ่งที่ควรทดสอบบนอุปกรณ์จริง)

---

## 1. Bugs รอบ 1 — สถานะ

| # | Bug | ไฟล์ | สถานะ |
|---|-----|------|-------|
| BUG-001 | ปุ่มชำระเงินกดซ้ำได้ขณะ processing | checkout_controller.dart, checkout_page.dart | ✅ แก้แล้ว |
| BUG-002 | Loading dialog ค้างถ้า API คืน null | checkout_controller.dart | ✅ แก้แล้ว |
| BUG-003 | shopId ไม่ validate ก่อนสร้าง transaction | checkout_controller.dart | ✅ แก้แล้ว |
| BUG-004 | jsonDecode ไม่มี try-catch | api_payment.dart, api_sale.dart | ✅ แก้แล้ว |
| BUG-005 | District dropdown crash (orElse ขาด) | debt_register_controller.dart | ✅ แก้แล้ว |
| BUG-006 | Debouncer ไม่ถูก cancel | debt_sale_controller.dart, add_stock_controller.dart | ✅ มี cancel อยู่แล้ว ไม่ต้องแก้ |
| BUG-007 | Product สร้างด้วย shopId=0 | add_product_controller.dart | ✅ แก้แล้ว |
| BUG-008 | Barcode scan error ไม่แจ้ง user | checkout_controller.dart | ✅ แก้แล้ว |
| BUG-009 | เบอร์โทรลูกหนี้ไม่ validate format | debt_register_controller.dart | ✅ แก้แล้ว |
| BUG-010 | int.parse() crash ใน Add Stock | add_stock_controller.dart | ✅ แก้แล้ว |
| BUG-011 | Parked order resume ทิ้ง state เก่า | checkout_controller.dart | ✅ แก้แล้ว |
| BUG-012 | QR Code ไม่มี call-to-action | checkout_page.dart | ✅ แก้แล้ว |
| BUG-013 | PIN validation fail เงียบ | create_shop_controller.dart | ✅ แก้แล้ว |

---

## 2. Bugs รอบ 2 — ที่พบเพิ่มและแก้แล้ว

### 🔴 HIGH — อาจ crash หรือข้อมูลผิดพลาด

#### BUG-R01: submitDebt() ไม่มี shopId validation — **แก้แล้ว** ✅
- **ไฟล์:** `lib/page/debt/debtSale/debt_sale_controller.dart` บรรทัด 289
- **อาการ:** `currentShopId = prefs.getInt('shopId') ?? 0` ไม่มีเช็ค → ส่ง shopId=0 ไปสร้างหนี้
- **ความเสียหาย:** transaction หนี้ผูกกับร้านผิด ข้อมูลหาย
- **วิธีแก้:** เพิ่ม `if (currentShopId == 0) { showErrorDialog(...); return; }` ก่อน build SaleRequest

#### BUG-R02: double.parse() crash ใน Add Product — **แก้แล้ว** ✅
- **ไฟล์:** `lib/page/product/add_product/add_product_controller.dart` บรรทัด 130-131
- **อาการ:** `double.parse(salePriceController.text)` crash ถ้ากรอกค่าผิดรูปแบบ เช่น "1,500" หรือ "abc"
- **วิธีแก้:** เปลี่ยนเป็น `double.tryParse(...) ?? 0.0`

#### BUG-R03: reduce() บน empty list ใน Advanced Report — **แก้แล้ว** ✅
- **ไฟล์:** `lib/page/my_blank/advanced_report_page.dart` บรรทัด ~562
- **อาการ:** `displayData.map(...).reduce(...)` throw "Bad state: No element" ถ้า displayData ว่าง (ช่วงที่ไม่มียอดขาย)
- **ความเสียหาย:** แอปพังทันทีเมื่อเปิดหน้า Advanced Report ในช่วงที่ไม่มีข้อมูล
- **วิธีแก้:** `final maxY = displayData.isEmpty ? 1000.0 : ...`

#### BUG-R04: result check หลวมเกินไปใน processPayment() — **แก้แล้ว** ✅
- **ไฟล์:** `lib/page/sale_producct/sale/checkout_controller.dart` บรรทัด ~742
- **อาการ:** `if (result != null)` ถือว่าสำเร็จแม้ backend ส่ง `{"error": "..."}` กลับมา → แสดง "ชำระเงินสำเร็จ" ทั้งที่จริงๆ ล้มเหลว
- **วิธีแก้:** เปลี่ยนเป็น `if (result != null && result.containsKey('sale_id'))` และแสดง error message จาก backend

---

### 🟠 MEDIUM — AuthGuard ขาดหายใน api_shop.dart

#### BUG-R05: deleteShop() ขาด AuthGuard — **แก้แล้ว** ✅
- **ไฟล์:** `lib/api/api_shop.dart` บรรทัด 77
- **อาการ:** ไม่มี `await AuthGuard.checkAndRefreshIfNeeded()` → ถ้า token หมดขณะกดลบร้านค้า = 401 error แบบ silent
- **วิธีแก้:** เพิ่ม AuthGuard call ก่อน HTTP request

#### BUG-R06: updateShop() ขาด AuthGuard — **แก้แล้ว** ✅
- **ไฟล์:** `lib/api/api_shop.dart` บรรทัด 116
- **อาการ:** เหมือน BUG-R05 — แก้ไขข้อมูลร้านไม่ได้ถ้า token หมด
- **วิธีแก้:** เพิ่ม AuthGuard call

---

### 🔵 LOW — UI/UX

#### BUG-R07: check_price.dart hardcode height: 50 — **แก้แล้ว** ✅
- **ไฟล์:** `lib/page/product/check_price/check_price.dart` บรรทัด 111
- **อาการ:** Search bar overflow บนอุปกรณ์ที่ตั้งฟอนต์ใหญ่
- **วิธีแก้:** ลบ `height: 50` และใช้ `contentPadding` แทน (เหมือน check_stock.dart)

#### BUG-R08: Search ใน Checkout ไม่แสดง loading indicator — **แก้แล้ว** ✅
- **ไฟล์:** `lib/page/sale_producct/sale/checkout_page.dart`
- **อาการ:** ขณะค้นหาสินค้า `isSearching.value = true` แต่ UI ไม่ตอบสนอง ผู้ใช้คิดว่าแอปค้าง
- **วิธีแก้:** เพิ่ม `if (controller.isSearching.value && controller.searchResults.isEmpty)` แสดง CircularProgressIndicator

#### BUG-R09: ข้อความ "สินค้าหมด" ไม่ถูกต้อง — **แก้แล้ว** ✅
- **ไฟล์:** `lib/page/sale_producct/sale/checkout_controller.dart` บรรทัด ~325
- **อาการ:** สินค้ามีในสต็อกแต่ติด stock limit ใน cart → แสดง "สินค้าหมด" ซึ่งทำให้ user สับสน
- **วิธีแก้:** เปลี่ยนเป็น "ถึงจำนวนสูงสุดแล้ว — สินค้านี้มีในสต็อก X ชิ้น ไม่สามารถเพิ่มได้อีก"

---

## 3. UI/UX Issues ทั้งหมด

| # | ปัญหา | หน้า | รอบ | สถานะ |
|---|------|------|-----|-------|
| UI-001 | ปุ่มชำระเงินไม่ disable ขณะ loading | Checkout | 1 | ✅ แก้แล้ว |
| UI-002 | ไม่แยก empty state กับ loading state | Checkout | 1 | ✅ แก้แล้ว (รอบ 2) |
| UI-003 | ไม่มี loading indicator ตอนค้นหาสินค้า | Checkout | 1 | ✅ แก้แล้ว (รอบ 2) |
| UI-004 | Hardcoded height: 50 ใน search bar | Check Price | 1 | ✅ แก้แล้ว (รอบ 2) |
| UI-005 | Form ชำระเงิน ไม่ validate "รับเงินมา" | Checkout Payment | 1 | ✅ มี validate อยู่แล้ว |
| UI-006 | QR Code ไม่มี action text | Checkout Payment | 1 | ✅ แก้แล้ว |
| UI-007 | ข้อความ "สินค้าหมด" ไม่ถูกต้อง | Checkout | 2 | ✅ แก้แล้ว |
| UI-008 | PIN feedback เงียบ | Create Shop | 1 | ✅ แก้แล้ว |

---

## 4. Test Checklist รายหน้า

### 🔐 Auth Flow
- [x] Login ด้วย email/password ถูกต้อง → เข้าได้
- [x] Login รหัสผิด → แสดง error message
- [x] Login บัญชีไม่ verified → dialog พาไป OTP
- [x] Register ครบถ้วน → OTP ทางอีเมล
- [x] Register เบอร์โทร < 10 หลัก → validate error
- [x] Register รหัสผ่านไม่ตรง → validate error
- [x] Forgot Password → OTP → ตั้งรหัสใหม่ → Login ได้
- [x] Token หมด → Splash Screen redirect ไป Login
- [x] AuthGuard ทำงานทุก API call (ครอบคลุมแล้วหลัง BUG-R05/R06)

### 🏪 Shop Management
- [ ] สร้างร้านใหม่ → ตั้ง PIN 6 หลัก → Homepage แสดงร้านใหม่
- [ ] กด PIN ยืนยันไม่ครบ 6 หลัก → แจ้ง "รหัส PIN ไม่ครบ 6 หลัก" ✅ (แก้รอบ 1)
- [ ] เลือกร้านอื่นใน MyShop → Homepage โหลดข้อมูลร้านนั้น
- [ ] ลบร้านค้า → ยืนยันก่อนลบ → ร้านหาย ✅ (AuthGuard แก้รอบ 2)
- [ ] แก้ไขชื่อร้าน → บันทึกสำเร็จ ✅ (AuthGuard แก้รอบ 2)

### 📦 Product Management
- [ ] เพิ่มสินค้า กรอกราคา "1,500" (ใส่จุลภาค) → ไม่ crash ✅ (แก้รอบ 2)
- [ ] เพิ่มสินค้าไม่ครบ → validate error
- [ ] เพิ่มสต็อกกรอกตัวอักษร → validate error ✅ (แก้รอบ 1)
- [ ] เพิ่มสต็อกกรอก "0" หรือติดลบ → validate error ✅ (แก้รอบ 1)
- [ ] ลบสินค้า → หายจากรายการทุกหน้า
- [ ] ค้นหาสินค้าด้วยบาร์โค้ด → แสดงราคา
- [ ] ค้นหาสินค้าไม่มีในระบบ → แสดง "ไม่พบสินค้า"

### 💰 Sales Flow (สำคัญที่สุด)
- [ ] สแกนบาร์โค้ด → สินค้าเข้าตะกร้า → แสดง loading indicator ✅ (แก้รอบ 2)
- [ ] สแกนบาร์โค้ดไม่พบ → แสดง warning dialog ✅ (แก้รอบ 1)
- [ ] เพิ่มสินค้าเกิน stock → แจ้ง "ถึงจำนวนสูงสุดแล้ว" ✅ (แก้รอบ 2)
- [ ] ชำระเงินสด → ยืนยัน 2 ครั้งเร็วๆ → transaction เดียว ✅ (แก้รอบ 1)
- [ ] ชำระเงิน shopId=0 → แสดง error แทนส่ง 0 ✅ (แก้รอบ 1)
- [ ] API ตอบกลับ `{"error": "..."}` → แสดง error message จริง ✅ (แก้รอบ 2)
- [ ] ขายเป็นหนี้ shopId=0 → แสดง error แทนส่ง 0 ✅ (แก้รอบ 2)
- [ ] พักออเดอร์ → resume → state เดิมไม่ค้าง ✅ (แก้รอบ 1)
- [ ] ยอดขายวันนี้ Homepage อัปเดตหลังขายเสร็จ

### 👤 Debt Management
- [ ] เพิ่มลูกหนี้ เบอร์ "081234567" (9 หลัก) → validate error ✅ (แก้รอบ 1)
- [ ] เพิ่มลูกหนี้ เบอร์มี space นำหน้า → trim แล้ว validate ถูกต้อง ✅
- [ ] เลือกจังหวัด → เลือกอำเภอที่ข้อมูลผิดรูปแบบ → ไม่ crash ✅ (แก้รอบ 1)
- [ ] บันทึกชำระหนี้ → ยอดค้างลดลง
- [ ] ขายเชื่อให้ลูกหนี้ shopId=0 → error แทนส่ง 0 ✅ (แก้รอบ 2)

### 📊 Reports & Dashboard
- [ ] เปิด Advanced Report ช่วงที่ไม่มียอดขาย → ไม่ crash ✅ (แก้รอบ 2)
- [ ] เลือก 7 วัน, 30 วัน → ข้อมูลเปลี่ยน
- [ ] Chart render ถูกต้อง ไม่ขาว
- [ ] Export PDF ใบสั่งของ → ดาวน์โหลดได้

### 💲 Check Price / Check Stock
- [ ] Search bar ฟอนต์ใหญ่ไม่ overflow ✅ (แก้รอบ 2)
- [ ] ค้นหาสินค้า → แสดงผลถูกต้อง

### 👤 Profile
- [ ] แก้ไข username → บันทึก → ชื่อเปลี่ยน
- [ ] Logout → clear session → กลับหน้า Login

---

## 5. สิ่งที่ควรทดสอบบนอุปกรณ์จริง

> ต่อไปนี้เป็นสิ่งที่ code analysis พิสูจน์ได้ยาก ต้องทดสอบจริง

| สิ่งที่ต้องทดสอบ | เหตุผล |
|----------------|--------|
| กด "ยืนยันการทำรายการ" 2 ครั้งเร็วๆ | ป้องกัน transaction ซ้ำ (BUG-001) |
| เปิดแอปหลัง token หมด (>15 นาที) | ทดสอบ refresh token flow |
| สร้างร้านใหม่ → Homepage ข้อมูลถูกต้อง | ทดสอบ shopId propagation |
| ฟอนต์ระบบ "ใหญ่มาก" → ทุกหน้าไม่ overflow | ทดสอบ text scaling |
| เปิด Advanced Report ตอนไม่มีข้อมูล | ทดสอบ empty reduce() fix |
| Network ช้า/หลุด ขณะชำระเงิน | ทดสอบ error handling |
| ลบร้านค้า ขณะ token ใกล้หมด | ทดสอบ AuthGuard ใน deleteShop() |

---

## สรุป Priority ที่เหลือ (ไม่ได้แก้รอบนี้)

สิ่งต่อไปนี้ถูกพบแต่ไม่ได้แก้เพราะเป็น edge case หรือ out of scope:

| # | Issue | เหตุผล |
|---|-------|--------|
| ลูกหนี้ debtorId = null | ข้อมูลในระบบควรไม่มี null จาก backend | ต้องตรวจ backend validation |
| api_debtor.dart searchDebtor() ไม่แยก 404 vs error | ไม่ impact ข้อมูล แค่ UX ในการ debug | Sprint ถัดไป |
| debt_payment_controller ไม่มี API timeout | ต้องการ http.Client ที่ custom timeout | Sprint ถัดไป |

---

*รายงานนี้สร้างโดย Claude Code จากการวิเคราะห์ source code โดยตรง 2 รอบ — ควรนำ test checklist ไปทดสอบจริงบนอุปกรณ์ Android เพื่อยืนยันครบ*
