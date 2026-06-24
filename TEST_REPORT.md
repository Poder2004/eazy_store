# EazyStore — QA Test Report

**วันที่ทดสอบ:** 2026-06-24  
**เวอร์ชัน:** Debug  
**จำนวนหน้าที่ครอบคลุม:** 27 หน้า  
**สถานะ:** 🔴 พบ Critical bugs หลายจุด ควรแก้ก่อน Release

---

## สารบัญ
1. [สรุป Feature ทั้งหมด](#1-feature-ทั้งหมด)
2. [Bugs ที่พบ (Critical → Low)](#2-bugs-ที่พบ)
3. [UI/UX Issues](#3-uiux-issues)
4. [Test Checklist รายหน้า](#4-test-checklist-รายหน้า)
5. [Priority Action Items](#5-priority-action-items)

---

## 1. Feature ทั้งหมด

| หน้า | ฟีเจอร์หลัก | สถานะ |
|------|------------|-------|
| Splash Screen | ตรวจสอบ Token + Refresh | ✅ |
| Login | Login ด้วย email/username | ✅ |
| Register | สมัครสมาชิก + OTP | ✅ |
| Forgot Password | ขอ OTP รีเซ็ตรหัสผ่าน | ✅ |
| Verify OTP | ยืนยัน OTP | ✅ |
| Reset Password | ตั้งรหัสผ่านใหม่ | ✅ |
| MyShop | ดู/เลือก/ลบร้านค้า | ✅ |
| Create Shop | สร้างร้านค้า + ตั้ง PIN | ✅ |
| Edit Shop | แก้ไขข้อมูลร้าน | ✅ |
| Homepage | ยอดขายวันนี้ + เมนูด่วน | ✅ |
| Add Product | เพิ่มสินค้าใหม่ | ⚠️ |
| Add Stock | เติมสต็อก | ⚠️ |
| Check Price | เช็คราคาสินค้า | ✅ |
| Check Stock | เช็คสต็อก | ✅ |
| Product Detail | รายละเอียดสินค้า | ✅ |
| Edit Product | แก้ไขสินค้า | ✅ |
| Scan Barcode | สแกนบาร์โค้ด | ✅ |
| Checkout / Cart | ตะกร้า + ชำระเงิน | 🔴 |
| Parked Orders | พักออเดอร์ | ⚠️ |
| Manual List (No Barcode) | สินค้าไม่มีบาร์โค้ด | ✅ |
| Debt Ledger | สมุดลูกหนี้ | ✅ |
| Debtor Detail | รายละเอียดลูกหนี้ | ✅ |
| Debt Register | เพิ่มลูกหนี้ใหม่ | ⚠️ |
| Debt Payment | บันทึกชำระหนี้ | ✅ |
| Debt Sale | ขายเป็นหนี้ | ⚠️ |
| Buy Products / Order | ใบสั่งของ + Export PDF | ✅ |
| Profile | ดูโปรไฟล์ | ✅ |
| Edit Profile | แก้ไขข้อมูลส่วนตัว | ✅ |
| Sales Account | รายงานยอดขาย | ✅ |
| Advanced Report | รายงานละเอียด + Chart | ✅ |

> ✅ = ทำงานได้ปกติ &nbsp; ⚠️ = มีจุดเสี่ยง &nbsp; 🔴 = พบ bug ที่กระทบการใช้งาน

---

## 2. Bugs ที่พบ

### 🔴 CRITICAL — อาจทำให้ข้อมูลผิดพลาดหรือแอปพัง

#### BUG-001: ปุ่ม "ยืนยันการทำรายการ" กดซ้ำได้ขณะกำลัง process
- **ไฟล์:** `lib/page/sale_producct/sale/checkout_page.dart` บรรทัด 830-852
- **อาการ:** ปุ่มยืนยันชำระเงินไม่ถูก disable ขณะ API กำลังทำงาน → กดซ้ำได้ → อาจสร้าง transaction ซ้ำ
- **ความเสียหาย:** บิลขายซ้ำ, ข้อมูลเงินผิดพลาด
- **วิธีแก้:** เพิ่ม `isProcessingPayment.obs` และ disable ปุ่มใน `Obx`

#### BUG-002: Loading Dialog ค้างหรือปิดผิดลำดับถ้า API คืน null
- **ไฟล์:** `lib/page/sale_producct/sale/checkout_controller.dart` บรรทัด 724-728
- **อาการ:** `Get.back()` ถูกเรียก 2 ครั้ง — ครั้งแรกปิด loading dialog, ครั้งที่สองปิด payment sheet แม้ `result == null`
- **ความเสียหาย:** UI หายไป navigation stack เสีย ต้องปิดแอปใหม่
- **วิธีแก้:** ใช้ flag แยก loading vs payment sheet ก่อนเรียก `Get.back()`

#### BUG-003: shopId ไม่ถูก validate ก่อนสร้าง transaction
- **ไฟล์:** `lib/page/sale_producct/sale/checkout_controller.dart` บรรทัด 687
- **อาการ:** `shopId = prefs.getInt('shopId') ?? 0` ไม่เช็คว่า 0 = invalid → ส่ง shopId=0 ไปสร้างบิล
- **ความเสียหาย:** Transaction ผูกกับร้านผิด หรือ Backend reject แต่ error ไม่ชัด
- **วิธีแก้:** เพิ่ม `if (shopId == 0) { Get.snackbar(...); return; }` ก่อน processPayment

#### BUG-004: JSON Decode ไม่มี try-catch ในบาง API — อาจ crash
- **ไฟล์:** `lib/api/api_payment.dart` บรรทัด 26, `lib/api/api_sale.dart` บรรทัด 62
- **อาการ:** ถ้า Backend คืน HTML error page แทน JSON → `jsonDecode()` throw `FormatException` → App crash
- **ความเสียหาย:** แอปพังระหว่างทำธุรกรรม
- **วิธีแก้:** ครอบ `jsonDecode(response.body)` ทุกจุดด้วย try-catch

---

### 🟠 HIGH — กระทบประสบการณ์ใช้งานอย่างมีนัยสำคัญ

#### BUG-005: District dropdown crash ถ้าข้อมูลที่อยู่ผิดรูปแบบ
- **ไฟล์:** `lib/page/debt/debtRegister/debt_register_controller.dart` บรรทัด 87-91
- **อาการ:** `rawDistricts.firstWhere(...)` ไม่มี `orElse` → throw `StateError` ถ้าหาไม่เจอ
- **วิธีแก้:** เพิ่ม `orElse: () => null` และ null check ก่อนใช้ค่า

#### BUG-006: Debouncer ไม่ถูก cancel เมื่อออกจากหน้า
- **ไฟล์:** `lib/page/debt/debtSale/debt_sale_controller.dart` บรรทัด 59-71  
  `lib/page/product/add_stock/add_stock_controller.dart` บรรทัด 64-72
- **อาการ:** ออกจากหน้าก่อน debounce timer หมด → callback รันบน controller ที่ dispose แล้ว → crash
- **วิธีแก้:** เรียก `_debounce?.cancel()` ใน `onClose()`

#### BUG-007: สินค้าถูกสร้างด้วย shopId=0 ถ้า session มีปัญหา
- **ไฟล์:** `lib/page/product/add_product/add_product_controller.dart` บรรทัด 116
- **อาการ:** `shopId = prefs.getInt('shopId') ?? 0` ไม่มี validation → สินค้าอาจถูกสร้างกับร้านผิด
- **วิธีแก้:** เช็ค `if (shopId == 0) return;` ก่อน submit

#### BUG-008: Error หลัง barcode scan ไม่แสดงข้อความให้ user
- **ไฟล์:** `lib/page/sale_producct/sale/checkout_controller.dart` บรรทัด 280-282
- **อาการ:** `catch (e) { Get.back(); }` ปิด loading dialog เงียบๆ ไม่บอก user ว่าเกิดอะไร
- **วิธีแก้:** เพิ่ม `Get.snackbar("ไม่พบสินค้า", "กรุณาลองใหม่")` หลัง `Get.back()`

---

### 🟡 MEDIUM — ส่งผลต่อ UX แต่ไม่ทำให้ข้อมูลผิดพลาด

#### BUG-009: Form เพิ่มลูกหนี้ไม่ validate format เบอร์โทร
- **ไฟล์:** `lib/page/debt/debtRegister/debt_register_controller.dart` บรรทัด 123
- **อาการ:** เช็คแค่ไม่ว่าง แต่ไม่เช็คว่าเป็นตัวเลข 10 หลัก
- **วิธีแก้:** เพิ่ม `RegExp(r'^[0-9]{10}$')` เหมือน create_shop_controller

#### BUG-010: Add Stock — `int.parse()` crash ถ้ากรอกตัวอักษร
- **ไฟล์:** `lib/page/product/add_stock/add_stock_controller.dart` บรรทัด 219
- **อาการ:** `int.parse(addAmountController.text)` throw `FormatException` ถ้า text ไม่ใช่ตัวเลข
- **วิธีแก้:** เปลี่ยนเป็น `int.tryParse()` และเช็คผล null

#### BUG-011: Parked Order resume ทิ้ง cart state เก่าค้างไว้
- **ไฟล์:** `lib/page/sale_producct/sale/checkout_controller.dart` บรรทัด 402-407
- **อาการ:** ถ้า `retrieveOrder()` return null แล้ว early return แต่ cart อาจยังมีสินค้าเก่าค้างอยู่
- **วิธีแก้:** `clearAll()` ก่อน resume ทุกครั้ง

---

### 🔵 LOW — ปรับปรุง UX เพิ่มเติม

#### BUG-012: QR Code section ไม่มี call-to-action
- **ไฟล์:** `lib/page/sale_producct/sale/checkout_page.dart` บรรทัด 749-777
- **อาการ:** เมื่อร้านไม่มี QR Code แสดงแค่ "ไม่มี QR Code" ไม่บอกว่าไปเพิ่มได้ที่ไหน

#### BUG-013: PIN validation fail เงียบ ไม่มี feedback
- **ไฟล์:** `lib/page/shop/createShop/create_shop_controller.dart` บรรทัด 296
- **อาการ:** `if (currentPin.value.length != 6) return;` คืนค่าเงียบๆ ไม่แจ้ง user

---

## 3. UI/UX Issues

| # | ปัญหา | หน้าที่พบ | ระดับ |
|---|------|----------|-------|
| UI-001 | ปุ่มชำระเงินไม่ disable ขณะ loading | Checkout | 🔴 HIGH |
| UI-002 | ไม่แยก empty state กับ loading state | Checkout, Add Stock | 🟠 MEDIUM |
| UI-003 | ไม่มี loading indicator ตอนโหลดสินค้าครั้งแรก | Checkout | 🟡 MEDIUM |
| UI-004 | Hardcoded `height: 50` ใน search bar อาจ overflow บนฟอนต์ใหญ่ | Check Price | 🔵 LOW |
| UI-005 | ช่อง "รับเงินมา" ไม่มี validator | Checkout Payment | 🟠 MEDIUM |
| UI-006 | QR Code ไม่มี action text บอกให้ไปตั้งค่า | Checkout Payment | 🔵 LOW |
| UI-007 | หน้า Add Product ขาด back button ที่ชัดเจน | Add Product | 🔵 LOW |

---

## 4. Test Checklist รายหน้า

### 🔐 Auth Flow
- [ ] Login ด้วย email/password ถูกต้อง → เข้าได้
- [ ] Login ด้วยรหัสผ่านผิด → แสดง error message
- [ ] Login บัญชียังไม่ verify → แสดง dialog พาไป verify OTP
- [ ] Register ครบถ้วน → OTP ส่งมาทางอีเมล
- [ ] Register เบอร์โทร < 10 หลัก → ไม่ให้ submit พร้อม error
- [ ] Register รหัสผ่านไม่ตรงกัน → ไม่ให้ submit
- [ ] Forgot Password → OTP ส่งมา → ตั้งรหัสใหม่ได้ → Login ได้ทันที
- [ ] เปิดแอปหลังผ่านไป 1 วัน Token หมด → Refresh อัตโนมัติ
- [ ] Refresh ล้มเหลว → กลับหน้า Login พร้อม clear session ทั้งหมด

### 🏪 Shop Management
- [ ] สร้างร้านใหม่ → ตั้ง PIN → Homepage แสดงข้อมูลร้านใหม่ทันที
- [ ] เลือกร้านอื่นใน MyShop → Homepage โหลดข้อมูลร้านนั้น
- [ ] ลบร้านค้า → ร้านหายจากรายการ
- [ ] แก้ไขชื่อร้าน → บันทึกสำเร็จ → ชื่อเปลี่ยนใน Homepage

### 📦 Product Management
- [ ] เพิ่มสินค้าพร้อมรูป, ชื่อ, ราคา, สต็อก → บันทึกสำเร็จ
- [ ] เพิ่มสินค้าไม่ครบ → แสดง validation error ที่ถูกต้อง
- [ ] เพิ่มสต็อกสินค้า → จำนวนใน Check Stock เพิ่มขึ้น
- [ ] **เพิ่มสต็อกกรอกตัวอักษร → ไม่ crash** ⚠️ (BUG-010)
- [ ] แก้ไขราคาสินค้า → ราคาเปลี่ยนใน Check Price
- [ ] ลบสินค้า → หายจากรายการทุกหน้า
- [ ] ค้นหาสินค้าด้วยบาร์โค้ด → แสดงราคาถูกต้อง
- [ ] ค้นหาสินค้าที่ไม่มีในระบบ → แสดง "ไม่พบสินค้า"

### 💰 Sales Flow (สำคัญที่สุด)
- [ ] สแกนบาร์โค้ด → สินค้าเข้าตะกร้า
- [ ] เพิ่มสินค้าไม่มีบาร์โค้ดจาก manual list → เข้าตะกร้าได้
- [ ] เพิ่มจำนวนสินค้าในตะกร้า → ยอดรวมอัปเดตถูกต้อง
- [ ] ลบสินค้าจากตะกร้า → ยอดรวมอัปเดต
- [ ] ชำระเงินสด → กรอกรับเงิน → เงินทอนถูกต้อง → ยืนยัน → บิลถูกบันทึก
- [ ] **กดปุ่มยืนยันชำระเงิน 2 ครั้งเร็วๆ → ต้องสร้าง transaction เดียวเท่านั้น** 🔴 (BUG-001)
- [ ] ขายเป็นหนี้ → เลือกลูกหนี้ → ยอดหนี้เพิ่มขึ้น
- [ ] พักออเดอร์ → กลับมา resume ตะกร้าเดิมได้
- [ ] ยอดขายวันนี้ใน Homepage อัปเดตหลังขายเสร็จ (pull to refresh)

### 👤 Debt Management
- [ ] เพิ่มลูกหนี้ใหม่พร้อมรูป, ชื่อ, เบอร์, ที่อยู่ → บันทึกสำเร็จ
- [ ] **เพิ่มลูกหนี้ เบอร์ไม่ใช่ตัวเลข → validate แจ้ง error** ⚠️ (BUG-009)
- [ ] เลือกจังหวัด → อำเภอโหลดถูกต้อง
- [ ] เลือกอำเภอ → ตำบลโหลดถูกต้อง
- [ ] ดูรายละเอียดลูกหนี้ → ประวัติการซื้อถูกต้อง
- [ ] บันทึกชำระหนี้ → ยอดค้างลดลง
- [ ] ขายเชื่อให้ลูกหนี้ → ยอดหนี้เพิ่มขึ้น
- [ ] ค้นหาลูกหนี้ด้วยชื่อ → แสดงผลถูกต้อง

### 📊 Reports & Dashboard
- [ ] ยอดขายวันนี้ใน Homepage ถูกต้อง
- [ ] หน้า Sales Account เลือก 7 วัน, 30 วัน → ข้อมูลเปลี่ยน
- [ ] Chart แสดงถูกต้อง ไม่ขาว/ว่างเปล่า
- [ ] รายงานละเอียด (Advanced Report) โหลดได้
- [ ] Export PDF ใบสั่งของ → ไฟล์ดาวน์โหลดได้และเปิดได้

### 👤 Profile
- [ ] แก้ไข username → บันทึกสำเร็จ → ชื่อเปลี่ยน
- [ ] เปลี่ยนอีเมล → ต้องยืนยัน OTP ใหม่
- [ ] สลับร้านค้าจาก Profile → Homepage โหลดร้านใหม่
- [ ] Logout → กลับหน้า Login → SharedPreferences cleared ทั้งหมด

---

## 5. Priority Action Items

### 🔴 ต้องแก้ก่อน Release
| # | Bug | ไฟล์ |
|---|-----|------|
| 1 | BUG-001 + UI-001 — disable ปุ่มชำระเงินขณะ processing | `checkout_page.dart`, `checkout_controller.dart` |
| 2 | BUG-002 — fix double Get.back() ใน payment flow | `checkout_controller.dart` |
| 3 | BUG-003 — validate shopId > 0 ก่อน create transaction | `checkout_controller.dart` |
| 4 | BUG-004 — wrap jsonDecode ด้วย try-catch | `api_payment.dart`, `api_sale.dart` |

### 🟠 แก้ใน Sprint ถัดไป
| # | Bug | ไฟล์ |
|---|-----|------|
| 5 | BUG-005 — district dropdown orElse | `debt_register_controller.dart` |
| 6 | BUG-006 — cancel debouncer ใน onClose() | `debt_sale_controller.dart`, `add_stock_controller.dart` |
| 7 | BUG-007 — shopId validate ก่อนสร้างสินค้า | `add_product_controller.dart` |
| 8 | BUG-008 — แสดง error message หลัง barcode scan fail | `checkout_controller.dart` |
| 9 | BUG-009 + BUG-010 — form validation | `debt_register_controller.dart`, `add_stock_controller.dart` |
| 10 | UI-002, UI-003, UI-005 — loading/empty state, payment validation | `checkout_page.dart` |

---

*รายงานนี้สร้างโดย Claude Code จากการวิเคราะห์ source code โดยตรง — ควรนำไปทดสอบจริงบนอุปกรณ์เพื่อยืนยัน*
