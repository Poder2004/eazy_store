# 📡 สรุป API Layer — EazyStore Flutter App

> 📎 ดูสรุป **Request / Response Models** ได้ด้านล่างสุดของไฟล์นี้

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

---

# 📦 สรุป Request / Response Models — EazyStore

> **Pattern หลัก:** Request ใช้ `toJson()` แปลงเป็น JSON ก่อนส่ง — Response ใช้ `fromJson()` แปลง JSON กลับมาเป็น Object

---

## 🔷 REQUEST Models (lib/model/request/)

### 1. LoginRequest
| Field | Type | JSON Key | หมายเหตุ |
|---|---|---|---|
| `username` | String | `username` | รับทั้ง email/phone ขึ้นอยู่กับ Backend |
| `password` | String | `password` | |
| `deviceId` | String? | `device_id` | optional — ใช้จัดการ session หลายอุปกรณ์ |
| `deviceName` | String? | `device_name` | optional |

### 2. RegisterRequest
| Field | Type | JSON Key |
|---|---|---|
| `username` | String | `username` |
| `password` | String | `password` |
| `email` | String | `email` |
| `phone` | String | `phone` |

### 3. ResetRequest
| Field | Type | JSON Key | หมายเหตุ |
|---|---|---|---|
| `email` | String | `email` | ขอ OTP reset password ไปที่อีเมลนี้ |

### 4. VerifyOtpRequest
| Field | Type | JSON Key |
|---|---|---|
| `email` | String | `email` |
| `otpCode` | String | `otp_code` |

### 5. UpdatePasswordRequest
| Field | Type | JSON Key |
|---|---|---|
| `email` | String | `email` |
| `otpCode` | String | `otp_code` |
| `newPassword` | String | `new_password` |

### 6. ProductRequest
| Field | Type | JSON Key | หมายเหตุ |
|---|---|---|---|
| `shopId` | int | `shop_id` | |
| `categoryId` | int | `category_id` | |
| `name` | String | `name` | |
| `barcode` | String? | `barcode` | optional |
| `imgProduct` | String | `img_product` | URL จาก Cloudinary |
| `sellPrice` | double | `sell_price` | ราคาขาย |
| `costPrice` | double | `cost_price` | ต้นทุน |
| `stock` | int | `stock` | จำนวนสต็อก |
| `unit` | String | `unit` | หน่วยนับ เช่น "ชิ้น", "กก." |
| `status` | bool | `status` | default = true |

### 7. DebtorRequest
| Field | Type | JSON Key |
|---|---|---|
| `shopId` | int | `shop_id` |
| `name` | String | `name` |
| `phone` | String | `phone` |
| `address` | String | `address` |
| `imgDebtor` | String | `img_debtor` |
| `creditLimit` | double | `credit_limit` |
| `currentDebt` | double | `current_debt` |

### 8. PayDebtRequest
| Field | Type | JSON Key | หมายเหตุ |
|---|---|---|---|
| `shopId` | int | `shop_id` | |
| `debtorId` | int | `debtor_id` | |
| `amountPaid` | double | `amount_paid` | จำนวนเงินที่รับชำระ |
| `paymentMethod` | String | `payment_method` | เช่น "เงินสด", "โอน" |
| `payWith` | String | `pay_with` | ช่องทางที่ใช้จ่าย |
| `pinCode` | String | `pin_code` | PIN ยืนยันการรับเงิน |

### 9. SaleRequest (api_sale)
| Field | Type | JSON Key | หมายเหตุ |
|---|---|---|---|
| `shopId` | int | `shop_id` | |
| `debtorId` | int? | `debtor_id` | null = ขายปกติ, มีค่า = ขายเชื่อ |
| `netPrice` | double | `net_price` | ยอดรวมสุทธิ |
| `pay` | double | `pay` | เงินที่รับมา (โอน = เท่ากับ netPrice) |
| `paymentMethod` | String | `payment_method` | |
| `note` | String? | `note` | optional |
| `createdBuy` | String | `created_buy` | username ของคนขาย |
| `saleItems` | List\<SaleItemRequest\> | `sale_items` | รายการสินค้าในบิล |

**SaleItemRequest (sub-model)**

| Field | Type | JSON Key |
|---|---|---|
| `productId` | int | `product_id` |
| `amount` | int | `amount` |
| `pricePerUnit` | double | `price_per_unit` |
| `totalPrice` | double | `total_price` |

### 10. ProductItem (Basket/Cart Model)
| Field | Type | หมายเหตุ |
|---|---|---|
| `id` | String | productId เป็น String |
| `name` | String | |
| `price` | double | ราคาต่อชิ้น |
| `category` | String | ชื่อหมวดหมู่ |
| `imagePath` | String | |
| `maxStock` | int | สต็อกสูงสุด (snapshot ตอนหยิบ) |
| `unit` | String | |
| `showDelete` | RxBool | คุม UI ปุ่มลบ (GetX reactive) |

### 11. ParkedOrder / ParkedItem (พักออเดอร์)
**ParkedOrder**
| Field | Type | หมายเหตุ |
|---|---|---|
| `id` | String | `park_<timestamp>` |
| `label` | String | "ออเดอร์ 1", "ออเดอร์ 2" |
| `items` | List\<ParkedItem\> | รายการ (grouped) |
| `totalPrice` | double | |
| `parkedAt` | DateTime | เวลาที่พัก |
| `shopId` | int | แยก scope ตามร้าน |

---

## 🔶 RESPONSE Models (lib/model/response/)

### 1. LoginResponse
| Field | Type | JSON Key | หมายเหตุ |
|---|---|---|---|
| `message` | String | `message` | |
| `token` | String? | `token` | format เก่า |
| `accessToken` | String? | `access_token` | format ใหม่ |
| `refreshToken` | String? | `refresh_token` | |
| `expiresIn` | int? | `expires_in` | หน่วยวินาที |
| `user` | UserData? | `user` | object ข้อมูลผู้ใช้ |
| `error` | String? | `error` | |

**UserData (sub-model)**
```
id, username, email, phone
```

### 2. ShopResponse
| Field | Type | JSON Key |
|---|---|---|
| `shopId` | int | `shop_id` |
| `userId` | int | `user_id` |
| `name` | String | `name` |
| `phone` | String | `phone` |
| `address` | String | `address` |
| `imgQrcode` | String | `img_qrcode` |
| `imgShop` | String | `img_shop` |
| `pinCode` | String | `pin_code` |

### 3. ProductResponse
| Field | Type | JSON Key | หมายเหตุ |
|---|---|---|---|
| `productId` | int? | `product_id` | |
| `shopId` | int | `shop_id` | |
| `categoryId` | int | `category_id` | |
| `productCode` | String? | `product_code` | |
| `name` | String | `name` | |
| `barcode` | String? | `barcode` | |
| `imgProduct` | String | `img_product` | |
| `sellPrice` | double | `sell_price` | |
| `costPrice` | double | `cost_price` | |
| `stock` | int | `stock` | mutable (อัปเดตสต็อกได้) |
| `unit` | String | `unit` | |
| `status` | bool | `status` | false = soft-deleted |
| `category` | CategoryModel? | `category` | object หมวดหมู่ |
| `categoryName` | String? | — | ดึงจาก category.name |

**ProductPagedResponse (Pagination wrapper)**
```
items, totalItems, totalPages, currentPage
```

### 4. DebtorResponse
| Field | Type | JSON Key |
|---|---|---|
| `debtorId` | int | `debtor_id` |
| `name` | String | `name` |
| `phone` | String | `phone` |
| `address` | String | `address` |
| `imgDebtor` | String | `img_debtor` |
| `creditLimit` | double | `credit_limit` |
| `currentDebt` | double | `current_debt` |

**DebtorPagedResponse** = `items, totalItems, totalPages, currentPage`

### 5. SalesSummaryModel (Dashboard Summary)
| Field | Type | JSON Key | หมายเหตุ |
|---|---|---|---|
| `totalRevenue` | double | `total_revenue` | ยอดขายรวมตามบิล |
| `actualPaid` | double | `actual_paid` | เงินที่รับจริงเข้ากระเป๋า |
| `debtAmount` | double | `debt_amount` | ยอดค้างชำระใหม่ |
| `cost` | double | `cost` | ต้นทุนรวม |
| `profit` | double | `profit` | กำไรตามบัญชี |
| `transactions` | int | `transactions` | จำนวนบิล |
| `paidCash` | double | `paid_cash` | ยอดจ่ายเงินสด |
| `paidTransfer` | double | `paid_transfer` | ยอดจ่ายโอน |

### 6. AdvancedReportResponse (รายงานขั้นสูง)
รวม 8 sub-model:

| Sub-Model | Field หลัก |
|---|---|
| `SalesChartItem` | date, totalSales (กราฟยอดขายรายวัน) |
| `SummaryStats` | totalTransactions, totalSales, averageSales |
| `PaymentMethods` | paidCash, paidTransfer, debtAmount |
| `TopProductItem` | productName, totalQty, totalSales (ขายดีสุด) |
| `DebtSummary` | totalOutstanding, collectedThisMonth, debtorCount |
| `AgingReport` | safe, warning, danger (ยอดหนี้แยกระดับความเสี่ยง) |
| `TopDebtorItem` | debtorId, name, currentDebt (ลูกหนี้มากสุด) |
| `DebtCollection` | newDebt, collectedDebt |

### 7. TransactionDetailModel (ประวัติบิล)
| Field | Type | JSON Key |
|---|---|---|
| `saleId` | int | `sale_id` |
| `netPrice` | double | `net_price` |
| `pay` | double | `pay` |
| `paymentMethod` | String | `payment_method` |
| `createdAt` | String | `created_at` |

### 8. SaleDetailModel (รายการสินค้าในบิล)
```
saleId, createdAt, paymentMethod, netPrice, pay, change
→ items: List<SaleItemModel>
   → productId, productName, imgProduct, qty, unitPrice, costPrice, subtotal
```

### 9. CategoryModel (ใช้ทั้ง Request/Response)
| Field | Type | JSON Key |
|---|---|---|
| `categoryId` | int | `category_id` |
| `shopId` | int | `shop_id` |
| `name` | String | `name` |
| `status` | bool | `status` |

---

> [!NOTE]
> **Pattern ที่ควรพูดถึง:** ทุก Response Model ที่รองรับ Pagination จะมี wrapper class เป็น `XxxPagedResponse` เสมอ โดยมี fields: `items`, `totalItems`, `totalPages`, `currentPage`

