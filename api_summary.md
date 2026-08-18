# 📡 สรุป API Layer — EazyStore Flutter App

> ทุก Future ที่ต้องการยืนยันตัวตนจะแนบ **JWT Bearer Token** ใน Header เสมอ  
> และผ่าน **`AuthGuard.checkAndRefreshIfNeeded()`** ก่อนยิง request ทุกครั้ง เพื่อ auto-refresh token อัตโนมัติ

---

## 1. 🔐 api_auth.dart — ระบบสมาชิก

| Future | HTTP | Endpoint | หน้าที่ |
|---|---|---|---|
| `login()` | POST | `/api/auth/login` | เข้าสู่ระบบ รับ JWT Token กลับมา |
| `register()` | POST | `/api/auth/register` | สมัครสมาชิกใหม่ |
| `requestResetOTP()` | POST | `/api/auth/request-reset` | ขอรหัส OTP เพื่อรีเซ็ตรหัสผ่าน ส่งไปทางอีเมล |
| `verifyOTP()` | POST | `/api/auth/verify-otp` | ยืนยันรหัส OTP ที่ได้รับจากอีเมล |
| `updatePassword()` | POST | `/api/auth/reset-password` | เปลี่ยนรหัสผ่านใหม่หลังจากยืนยัน OTP แล้ว |
| `verifyRegistration()` | POST | `/api/auth/verify-registration` | ยืนยันอีเมลหลังสมัครสมาชิก (กดลิงก์ในอีเมล) |
| `changeEmailVerify()` | POST | `/api/auth/change-email-verify` | ยืนยันอีเมลใหม่กรณีเปลี่ยนอีเมล |

**คำพูดพรีเซน:** *"ระบบ Authentication ทำงานแบบ Stateless ด้วย JWT Token ครับ โดยการ reset password ใช้ระบบ OTP ส่งไปยังอีเมล และการสมัครหรือเปลี่ยนอีเมลต้องผ่านการยืนยัน email verification ก่อนทุกครั้ง"*

---

## 2. 🏪 api_shop.dart — จัดการร้านค้า

| Future | HTTP | Endpoint | หน้าที่ |
|---|---|---|---|
| `createShop()` | POST | `/api/shops` | สร้างร้านค้าใหม่ บันทึก `shopId` ลงเครื่องหลังสร้างสำเร็จ |
| `getShops()` | GET | `/api/shops` | ดึงรายชื่อร้านค้าทั้งหมดที่ผู้ใช้คนนี้มี |
| `updateShop()` | PUT | `/api/shops/:id` | แก้ไขข้อมูลร้านค้า |
| `deleteShop()` | DELETE | `/api/shops/:id` | ลบร้านค้า |
| `getCurrentShop()` | GET | `/api/shops` | ดึงข้อมูลร้านปัจจุบันโดยใช้ `shopId` ที่เก็บอยู่ในเครื่อง |

**คำพูดพรีเซน:** *"ผู้ใช้คนหนึ่งสามารถมีได้หลายร้านค้าครับ โดยเมื่อ login แล้วจะต้องเลือกร้านที่ต้องการใช้งาน ระบบจะบันทึก shopId ลงเครื่องผ่าน SharedPreferences แล้วนำ ID นี้ไปใช้กับทุก API ที่เกี่ยวข้องกับร้านค้านั้นๆ"*

---

## 3. 📦 api_product.dart — จัดการสินค้า

| Future | HTTP | Endpoint | หน้าที่ |
|---|---|---|---|
| `createProduct()` | POST | `/api/products` | เพิ่มสินค้าใหม่ |
| `getProductsByShop()` | GET | `/api/products?shop_id=...` | ดึงรายการสินค้าของร้าน รองรับ pagination, ค้นหา, กรองหมวดหมู่ |
| `searchProduct()` | GET | `/api/products/search?keyword=...` | ค้นหาสินค้าด้วยชื่อหรือบาร์โค้ด (ใช้ตอนสแกนขาย) |
| `updateProduct()` | PUT | `/api/products/:id` | แก้ไขข้อมูลสินค้า (ชื่อ, ราคา, รูป ฯลฯ) |
| `updateStock()` | PATCH | `/api/products/:id/stock` | เพิ่มสต็อกสินค้า (Backend นำค่าที่ส่งไปบวกกับสต็อกปัจจุบัน) |
| `deleteProduct()` | DELETE | `/api/products/:id` | ลบสินค้า (Smart Delete: ถ้ามีประวัติขายจะซ่อนแทนลบจริง) |
| `getNullBarcodeProducts()` | GET | `/api/products/null-barcode?shop_id=...` | ดึงสินค้าที่ไม่มีบาร์โค้ด (เพิ่มเข้าตะกร้าผ่านชื่อได้) |
| `getCategories()` | GET | `/api/categories?shop_id=...` | ดึงหมวดหมู่สินค้าทั้งหมด |
| `createCategory()` | POST | `/api/categories` | เพิ่มหมวดหมู่ใหม่ |
| `updateCategory()` | PUT | `/api/categories/:id` | แก้ไขชื่อหมวดหมู่ |
| `deleteCategory()` | DELETE | `/api/categories/:id` | ลบหมวดหมู่ |
| `restoreCategory()` | PUT | `/api/categories/:id/restore` | กู้คืนหมวดหมู่ที่ถูกลบ (Soft Delete) |
| `moveCategoryProducts()` | PUT | `/api/categories/:id/move-products` | ย้ายสินค้าจากหมวดที่จะลบไปหมวดอื่น |
| `getCategoryProductCount()` | — | (ใช้ getProductsByShop แล้วกรองฝั่ง client) | นับจำนวนสินค้าในหมวดหมู่ (กรองเฉพาะที่ active) |

**คำพูดพรีเซน:** *"สินค้าที่เคยมีประวัติการขายแล้วจะไม่ถูกลบจริงๆ ครับ แต่จะเปลี่ยน status เป็น false แทน เพื่อเก็บประวัติการขายไว้ครบ เรียกว่า Soft Delete ครับ"*

---

## 4. 💵 api_sale.dart — บันทึกการขาย

| Future | HTTP | Endpoint | หน้าที่ |
|---|---|---|---|
| `createSale()` | POST | `/api/sales` | บันทึกการขายแบบเงินสด/โอน |
| `createCreditSale()` | POST | `/api/sales/credit` | บันทึกการขายแบบลูกหนี้ (ติดค้างไว้ก่อน) |

**คำพูดพรีเซน:** *"ตอนบันทึกการขาย ระบบจะส่งรายการสินค้าทั้งหมดไปพร้อมกันใน request เดียวครับ โดย Backend จะทำการลดสต็อก, บันทึกยอดขาย, และคำนวณกำไรให้ทั้งหมดในคราวเดียว มีให้เลือกทั้งจ่ายเงินสด โอน และขายเชื่อ"*

---

## 5. 👥 api_debtor.dart — จัดการลูกหนี้

| Future | HTTP | Endpoint | หน้าที่ |
|---|---|---|---|
| `createDebtor()` | POST | `/api/debtors` | เพิ่มลูกหนี้ใหม่เข้าระบบ |
| `getDebtorsByShop()` | GET | `/api/debtors?shop_id=...` | ดึงรายชื่อลูกหนี้ทั้งหมดของร้าน (รองรับ pagination) |
| `searchDebtor()` | GET | `/api/debtors/search?keyword=...` | ค้นหาลูกหนี้จากชื่อหรือเบอร์โทร |
| `getDebtorHistory()` | GET | `/api/debtors/:id/history` | ดูประวัติยอดหนี้และการชำระเงินของลูกหนี้คนนั้น |
| `updateDebtor()` | PUT | `/api/debtors/:id` | แก้ไขข้อมูลลูกหนี้ |

**คำพูดพรีเซน:** *"ระบบลูกหนี้เชื่อมกับการขายเชื่อโดยตรงครับ เมื่อขายเชื่อแล้วยอดจะขึ้นในบัญชีลูกหนี้คนนั้นทันที และสามารถดูประวัติการชำระเงินย้อนหลังได้ทั้งหมด"*

---

## 6. 💳 api_payment.dart — ชำระหนี้ลูกหนี้

| Future | HTTP | Endpoint | หน้าที่ |
|---|---|---|---|
| `payDebt()` | POST | `/api/payments` | บันทึกการรับชำระหนี้จากลูกหนี้ |
| `getPaymentHistory()` | GET | `/api/debtors/:id/payments` | ดูประวัติการชำระหนี้ทั้งหมดของลูกหนี้คนนั้น |

---

## 7. 📊 api_dashboad.dart — Dashboard และรายงาน

| Future | HTTP | Endpoint | หน้าที่ |
|---|---|---|---|
| `getSalesSummary()` | GET | `/api/dashboard/sales-summary` | สรุปยอดขายรวม (รายได้, กำไร, จำนวนบิล) กรองด้วยช่วงวันที่ |
| `getTransactionsDetail()` | GET | `/api/dashboard/transactions` | รายละเอียดทุกบิลการขายในช่วงวันที่ที่เลือก |
| `getProductSalesDetail()` | GET | `/api/dashboard/product-details` | สถิติสินค้าขายดี/กำไรต่อสินค้า |
| `getSaleItems()` | GET | `/api/dashboard/sale-items` | ดูรายการสินค้าภายในบิลนั้นๆ |
| `getAdvancedReport()` | GET | `/api/dashboard/advanced-report` | รายงานขั้นสูง (ยอดหนี้คงค้าง, สต็อกใกล้หมด ฯลฯ) |
| `getAgingReportDetail()` | GET | `/api/dashboard/aging-report-detail` | รายชื่อลูกหนี้แยกตามอายุหนี้ (0-30 วัน, 31-60 วัน ฯลฯ) |

**คำพูดพรีเซน:** *"Dashboard ดึงข้อมูลจาก Backend โดยส่งช่วงวันที่ผ่าน Query Parameter ครับ ไม่ได้คำนวณฝั่งแอป เพื่อให้ตัวเลขถูกต้องและรวดเร็ว มีตั้งแต่ยอดขายสรุปรายวัน รายเดือน ไปจนถึงรายงานลูกหนี้แยกตามอายุหนี้"*

---

## 8. 📋 api_orderlist.dart — ใบสั่งซื้อ PDF

| Future | HTTP | Endpoint | หน้าที่ |
|---|---|---|---|
| `exportOrderPdf()` | POST | `/api/orderlist` | ส่งรายการสินค้าที่ต้องสั่ง → Backend สร้าง PDF → แอปรับ Binary และเปิดไฟล์ |

**คำพูดพรีเซน:** *"ฟีเจอร์นี้ช่วยให้ผู้ประกอบการสร้างใบสั่งซื้อสินค้าจากร้านส่งได้ครับ โดยเลือกสินค้าที่ต้องการสั่งซื้อ กำหนดจำนวน แล้วระบบจะสร้างเป็น PDF ที่มีชื่อร้าน ที่อยู่ เบอร์โทร และรายการสินค้า พร้อมส่งออกเป็นไฟล์ได้ทันที ชื่อไฟล์จะเป็นวันที่-ชื่อร้านอัตโนมัติ"*

---

## 9. 🖼️ api_service_image.dart — อัปโหลดรูปภาพ

| Future | HTTP | ปลายทาง | หน้าที่ |
|---|---|---|---|
| `uploadImage()` | POST | Cloudinary API | อัปโหลดรูปจาก File/XFile แปลงเป็น Bytes แล้วอัปโหลด |
| `uploadBytes()` | POST | Cloudinary API | อัปโหลดโดยตรงจาก Bytes (รองรับทุกแพลตฟอร์มรวมถึงเว็บ) |

**คำพูดพรีเซน:** *"รูปภาพสินค้าและร้านค้าจะถูกอัปโหลดไปเก็บที่ Cloudinary ซึ่งเป็น Cloud Storage ภายนอกครับ โดย Backend ของเราเก็บแค่ URL ของรูป ไม่ได้เก็บไฟล์รูปไว้เอง ทำให้ประหยัด Storage และโหลดรูปได้เร็วผ่าน CDN"*

---

## 10. 👤 api_user.dart — ข้อมูลผู้ใช้

| Future | HTTP | Endpoint | หน้าที่ |
|---|---|---|---|
| `getUserProfile()` | GET | `/api/profile` | ดึงข้อมูลโปรไฟล์ล่าสุด (ชื่อ, อีเมล, เบอร์โทร) |
| `verifyToken()` | GET | `/api/profile` | ตรวจสอบว่า JWT Token ที่มีอยู่ยังใช้งานได้หรือหมดอายุ |
| `updateProfile()` | PUT | `/api/profile` | แก้ไขข้อมูลโปรไฟล์ (รองรับการเปลี่ยนอีเมลที่ต้องยืนยันใหม่) |

---

## 🗺️ ภาพรวมระบบ

```
Flutter App (lib/api/)
│
├── api_auth.dart         → JWT Authentication, OTP Reset
├── api_shop.dart         → CRUD ร้านค้า
├── api_product.dart      → CRUD สินค้า + หมวดหมู่ + สต็อก
├── api_sale.dart         → บันทึกขายเงินสด / เชื่อ
├── api_debtor.dart       → จัดการลูกหนี้
├── api_payment.dart      → รับชำระหนี้
├── api_dashboad.dart     → รายงาน / Dashboard
├── api_orderlist.dart    → ออกใบสั่งซื้อ PDF
├── api_service_image.dart → อัปโหลดรูป Cloudinary
└── api_user.dart         → โปรไฟล์ผู้ใช้
```

> [!TIP]
> **ประโยคสรุปพรีเซน:** *"ระบบ API ของ EazyStore แบ่งออกเป็น 10 กลุ่ม รวมทั้งสิ้น 37 Future ครับ ทุกกลุ่มใช้ HTTP package ในการสื่อสารกับ Backend ที่เขียนด้วย Go (Gin Framework) โดยมีระบบ Auto-refresh JWT Token ผ่าน AuthGuard ที่ทำงานเบื้องหลังทุก request เพื่อไม่ให้ผู้ใช้ถูก logout กลางคัน"*
