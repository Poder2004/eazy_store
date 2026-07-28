# EazyStore — QA Test Report (รอบ 3)

**วันที่ทดสอบ:** 28 กรกฎาคม 2569
**ผู้ทดสอบ:** QA (static code review + tooling)
**ขอบเขต:** ตั้งแต่สมัครสมาชิกจนจบทุกฟีเจอร์ ทั้ง Frontend และ Backend

| Repo | Path | Branch | Commit |
|---|---|---|---|
| Frontend (Flutter) | `c:\eazy_store` | `feature/multi-unit` | `6e59b20` |
| Backend (Go + Gin) | `c:\EazyStoreAPI` | `main` | `fe0a202` |
| Backend (ยังไม่ merge) | `c:\EazyStoreAPI` | `origin/feature/multi-unit` | `1854f97` |

**วิธีทดสอบรอบนี้:** อ่านโค้ดทุก path (109 ไฟล์ Dart / 31,757 บรรทัด + 45 endpoint Go) + รัน `flutter analyze`
**ไม่ได้ทำ:** ไม่ได้รันแอปบนอุปกรณ์จริง ไม่ได้ยิง API จริง ไม่ได้แตะ DB production
**หมายเหตุ:** รายงานนี้ **ไม่ได้แก้โค้ดใดๆ** เป็นเอกสารรายงานผลอย่างเดียว

---

## สารบัญ

1. [สรุปผู้บริหาร](#1-สรุปผู้บริหาร)
2. [ปัญหาหลัก — Frontend/Backend ไม่ตรงกัน](#2-ปัญหาหลัก--frontendbackend-ไม่ตรงกัน)
3. [บัคที่พบทั้งหมด](#3-บัคที่พบทั้งหมด)
4. [Test Case Matrix](#4-test-case-matrix)
5. [ผลจาก flutter analyze](#5-ผลจาก-flutter-analyze)
6. [Regression Checklist หลัง merge](#6-regression-checklist-หลัง-merge)
7. [ลำดับความสำคัญในการแก้](#7-ลำดับความสำคัญในการแก้)

---

## 1. สรุปผู้บริหาร

### เจอบัคทั้งหมด 47 รายการ

| ระดับ | จำนวน | ความหมาย |
|---|---|---|
| 🔴 CRITICAL | 10 | ข้อมูลผิดพลาดถาวร / ยึดบัญชีได้ / เงินกับสต็อกไม่ตรง |
| 🟠 HIGH | 16 | แอปพัง หรือผู้ใช้เห็นข้อมูลผิด |
| 🟡 MEDIUM | 15 | UX เสีย แต่ข้อมูลยังถูก |
| 🔵 LOW | 6 | โค้ดสะอาด / เอกสาร |

### ประเด็นที่ต้องแก้ก่อน Release เด็ดขาด

> **1. ฟีเจอร์ multi-unit ใช้งานไม่ได้เลยตอนนี้**
> Flutter ส่งฟีเจอร์หน่วยขายหลายหน่วยขึ้น production แล้ว แต่ Backend `main` ยังไม่ merge โค้ดฝั่งเซิร์ฟเวอร์
> **ผลที่เกิดขึ้นจริง: ขาย "1 ลัง" (12 ขวด) ระบบตัดสต็อกแค่ 1 ขวด** — สต็อกในระบบจะเพี้ยนสะสมทุกบิลที่ขายเป็นลัง

> **2. ยึดบัญชีคนอื่นได้โดยไม่ต้องล็อกอิน**
> `POST /api/auth/change-email-verify` เป็น public route ไม่มีการยืนยันตัวตนใดๆ ใครก็ตามที่รู้ `username` ของบัญชีที่ยังไม่ยืนยันอีเมล สามารถเปลี่ยนอีเมลบัญชีนั้นเป็นของตัวเองแล้วรับ OTP ไปยืนยันได้เลย

> **3. เงินกับสต็อกไม่ตรงกันได้หลายทาง**
> ขายเงินสดไม่เช็คสต็อก (ติดลบได้) · ชำระหนี้ไม่เช็คว่าลูกหนี้เป็นของร้านตัวเอง · ส่งยอดจ่ายติดลบเพื่อ**เพิ่ม**หนี้ได้ · ขายเชื่อโดยไม่บันทึกหนี้ได้

> **4. ข้อมูลร้านอื่นเข้าถึงได้ทั้งหมด (IDOR)**
> ทุก endpoint รับ `shop_id` จาก client ไม่เคยดึงจาก JWT เลย ผู้ใช้ที่ล็อกอินร้าน A เปลี่ยนเลข `shop_id` ใน request ก็อ่าน/แก้/ลบข้อมูลร้าน B ได้ทั้งหมด
> มีฟังก์ชัน `GetShopIDFromAuth` เขียนไว้แล้วที่ `middleware/auth.go:58` แต่**ไม่มีที่ไหนเรียกใช้เลย**

---

## 2. ปัญหาหลัก — Frontend/Backend ไม่ตรงกัน

Flutter branch `feature/multi-unit` ส่งข้อมูลหน่วยขายเพิ่มเติมไปให้ backend แต่ backend `main` ไม่รู้จักอะไรเลย

| สิ่งที่ Flutter ทำ | ไฟล์ Flutter | ผลลัพธ์กับ backend `main` (ตอนนี้) | ผลลัพธ์กับ `feature/multi-unit` (ถ้า merge) |
|---|---|---|---|
| `POST /api/products/{id}/units` เพิ่มหน่วยขาย | [api_product.dart:462](lib/api/api_product.dart#L462) | **404** — ไม่มี route นี้ | ✅ ทำงานปกติ |
| `PUT /api/products/units/{unitId}` แก้หน่วยขาย | [api_product.dart:497](lib/api/api_product.dart#L497) | **404** | ✅ |
| `DELETE /api/products/units/{unitId}` ลบหน่วยขาย | [api_product.dart:530](lib/api/api_product.dart#L530) | **404** | ✅ soft-delete ถ้าเคยขายแล้ว |
| ส่ง `units[]` ตอนสร้างสินค้า | [product_request.dart:15,43](lib/model/request/product_request.dart#L15) | **หายเงียบ** — `ShouldBindJSON` ทิ้ง field ที่ struct ไม่มี ไม่มี error | ✅ (ยังต้องเพิ่มหน่วยทีหลังทีละอัน) |
| ส่ง `product_unit_id` ตอนขาย | [sales_model_request.dart:42,57](lib/model/request/sales_model_request.dart#L42) | **ถูกทิ้ง** — struct ที่ `sale_cash_controller.go:23-28` ไม่มี field นี้ → **ขาย 1 ลัง ตัดสต็อก 1 ขวด** | ✅ เซิร์ฟเวอร์อ่าน `conversion_qty` จาก DB เอง ตัด `amount × conv` |
| ส่ง `product_unit_id` ตอนเติมสต็อก | [api_product.dart:437](lib/api/api_product.dart#L437) | **ถูกทิ้ง** — `models.UpdateStockRequest` มีแค่ `{product_id, stock}` → **เติม 1 ลัง สต็อกเพิ่ม 1** | ✅ คืน `added_base_amount` มาด้วย |
| สแกนบาร์โค้ดที่แปะบนลัง | [checkout_controller.dart:279-285](lib/page/sale_producct/sale/checkout_controller.dart#L279) | หาใน cache local เจอ → OK แต่ถ้าไม่มีใน cache ยิงไป API → **"ไม่พบสินค้า"** เพราะ `GetProductBySearch` ค้นแค่ `product_code`/`barcode`/`name` ของตาราง `products` | ✅ ค้น `product_units.barcode` ด้วย + ส่ง `matched_unit` กลับมา |
| แสดงสต็อกเป็น "10 ลัง + 5 ขวด" | [stock_format.dart:6](lib/utils/stock_format.dart#L6) | แสดงเป็นหน่วยฐานอย่างเดียว เพราะ `units` ที่ backend ส่งมาว่างเปล่าเสมอ | ✅ `Preload("Units")` where status=1 |
| ตาราง `product_units` | — | **ไม่มีในฐานข้อมูล** — migration `003_product_units.sql` และ `004_sale_items_unit_columns.sql` มีอยู่แค่บน branch | ต้องรัน migration ก่อน |

**สรุป:** ฟีเจอร์ multi-unit ทั้งหมดที่ทำมา 32 ไฟล์ (+1943/−291) **ยังไม่มีผลใดๆ** และที่แย่กว่าคือมันทำให้ข้อมูลสต็อกผิด ไม่ใช่แค่ "ใช้ไม่ได้เฉยๆ"

---

## 3. บัคที่พบทั้งหมด

### 🔴 CRITICAL

---

#### BUG-V3-001 · ขายเป็นลังตัดสต็อกผิดจำนวน

**ที่:** `../EazyStoreAPI/controllers/sales/sale_cash_controller.go:23-28, 80-85`
**อาการ:** ขายสินค้าเป็นหน่วยใหญ่ (เช่น 1 ลัง = 12 ขวด) ระบบตัดสต็อกแค่ 1 ขวด แทนที่จะเป็น 12 ขวด

**วิธี reproduce:**
1. สร้างสินค้า "น้ำอัดลม" หน่วยฐาน = ขวด สต็อก 100 ขวด
2. เพิ่มหน่วยขาย "ลัง" = 12 ขวด (ขั้นนี้จะ 404 อยู่แล้ว ดู BUG-V3-002 ท้ายตาราง — สมมติว่าเพิ่มตรงใน DB)
3. ขาย 1 ลัง
4. เช็คสต็อก → เหลือ 99 (ที่ถูกต้องคือ 88)

**สาเหตุ:** struct รับข้อมูลใน `CreateSale` ไม่มี field `product_unit_id` เลย Gin จึงทิ้งค่าที่ Flutter ส่งมาโดยไม่แจ้ง error แล้วตัดสต็อกด้วย `item.Amount` ตรงๆ

**แนวทางแก้:** merge `origin/feature/multi-unit` ฝั่ง backend (โค้ดแก้เสร็จแล้ว รอ merge อย่างเดียว) และรัน migration 003 + 004

---

#### BUG-V3-002 · ยึดบัญชีคนอื่นได้ผ่าน endpoint เปลี่ยนอีเมล

**ที่:** `../EazyStoreAPI/controllers/auth/auth_controller.go:116-156`, route ที่ `routes/auth_routes.go:14`
**อาการ:** `POST /api/auth/change-email-verify` อยู่ใน group `/api/auth` ซึ่ง**ไม่ผ่าน middleware `CheckAuth()`** ตัวฟังก์ชันเองก็ไม่ตรวจอะไรนอกจาก "มี username นี้ที่ยังไม่ยืนยันไหม"

**วิธี reproduce:**
```
POST /api/auth/change-email-verify
{ "username": "<username ของเหยื่อที่ยังไม่ยืนยัน>", "new_email": "attacker@evil.com" }
```
ระบบจะเปลี่ยนอีเมลบัญชีเหยื่อเป็นของผู้โจมตี แล้วส่ง OTP ไปที่อีเมลผู้โจมตี → ยืนยัน → ได้บัญชีเหยื่อไป

**สาเหตุ:** route สาธารณะ + ไม่มี proof of ownership ใดๆ (ไม่ขอรหัสผ่าน ไม่ขอ OTP เดิม)

**หมายเหตุเสริม:** ตาราง `email_verifications` ใช้ email เป็น PK แถว OTP ของอีเมลเดิมจึงยังค้างอยู่และใช้ได้ต่อ

---

#### BUG-V3-003 · Refresh token ใช้แทน access token ได้ทุก endpoint

**ที่:** `../EazyStoreAPI/middleware/auth.go:31-51`
**อาการ:** middleware ตรวจแค่ signature กับ HMAC algorithm แต่**ไม่ตรวจ claim `type`** ทั้งที่ตอนออก token มีการใส่ `type: "access"` / `type: "refresh"` ไว้แล้ว (`auth_controller.go:210-240`)

**ผลกระทบ:** refresh token อายุ **7 วัน** ใช้เรียก API ที่ต้อง auth ได้ทั้งหมด ทำให้ access token อายุ 15 นาทีไม่มีความหมาย และ refresh token ที่หลุด (เก็บใน SharedPreferences แบบ plaintext — ดู BUG-V3-019) กลายเป็นกุญแจถาวร 7 วัน

**วิธี reproduce:** ล็อกอิน เอา `refresh_token` ที่ได้ ใส่เป็น `Authorization: Bearer <refresh_token>` แล้วยิง `GET /api/products?shop_id=1` → ได้ 200

---

#### BUG-V3-004 · OTP หมดอายุแล้วยังรีเซ็ตรหัสผ่านได้

**ที่:** `../EazyStoreAPI/controllers/ResetPassword/ResetPassword.go:148-153`
**อาการ:** `VerifyOTP` เช็ค `ExpiresAt` ถูกต้อง (บรรทัด 133) แต่ `UpdatePassword` ที่เป็นขั้นสุดท้ายกลับ **query แค่ `email + otp_code` ไม่เช็ควันหมดอายุเลย**

```go
if err := database.DB.Where("email = ? AND otp_code = ?", input.Email, input.OTPCode).First(&resetRecord).Error; err != nil {
```

**ผลกระทบ:** OTP ที่ออกไว้เมื่อ 3 วันก่อนและไม่เคยถูกใช้ ยังเปลี่ยนรหัสผ่านได้อยู่ แถมยิง `/reset-password` ตรงๆ ได้โดยไม่ต้องผ่าน `/verify-otp` ก่อน

**เสริม:** ไม่มี rate limit ในการเดา OTP เลย OTP 6 หลัก = 1,000,000 ความเป็นไปได้ เดาแบบ brute force ได้

---

#### BUG-V3-005 · สมัครสมาชิกซ้ำเบอร์เดิม ทับบัญชีคนอื่น

**ที่:** `../EazyStoreAPI/controllers/auth/auth_controller.go:37-50`
**อาการ:** ค้นหาด้วย `WHERE email = ? OR phone = ?` ถ้าเจอแถวที่ยังไม่ยืนยัน จะ**เขียนทับ email กับ password ของแถวนั้น** โดยไม่สนว่าที่เจอเป็นเพราะ email ตรงหรือ phone ตรง

**วิธี reproduce:**
1. คน A สมัครด้วย `a@mail.com` เบอร์ `0812345678` แต่ยังไม่กด verify
2. คน B สมัครด้วย `b@mail.com` เบอร์ `0812345678` (เบอร์ซ้ำ)
3. ระบบเจอแถวของ A (เพราะเบอร์ตรง) → เขียนทับ email เป็น `b@mail.com` และ password เป็นของ B
4. บัญชีของ A หายไป ถูกแทนที่ด้วย B แต่ยังเก็บ `username` เดิมของ A ไว้

**เสริม:** `input.Username` ที่ B กรอกถูกทิ้งเงียบในเส้นทางนี้ B จะได้ username ของ A แทน

---

#### BUG-V3-006 · ขายเงินสดไม่เช็คสต็อก ทำให้สต็อกติดลบ

**ที่:** `../EazyStoreAPI/controllers/sales/sale_cash_controller.go:79-85`
**อาการ:** ตัดสต็อกทันทีโดยไม่เช็คว่ามีของพอไหม ต่างจากเส้นทางขายเชื่อที่เช็คถูกต้องที่ `sale_credit_controller.go:70`

**วิธี reproduce:** สินค้ามีสต็อก 3 ยิง `POST /api/sales` ด้วย `amount: 10` → สำเร็จ 200 สต็อกเหลือ **-7**

**เสริม:** บรรทัด 81 ใช้ `database.DB.Raw("stock - ?", ...)` เป็นค่าใน `UpdateColumn` ซึ่งต่างจากทุกจุดอื่นในโค้ดเบสที่ใช้ `gorm.Expr(...)` และยังเรียก global handle `database.DB` แทน `tx` ที่กำลังเปิด transaction อยู่ — branch `feature/multi-unit` แก้เป็น `gorm.Expr` แล้วพร้อมกับเพิ่มการเช็คสต็อก โดยเขียนคอมเมนต์กำกับไว้ว่า *"เดิม path นี้ไม่เคยเช็คมาก่อน ปล่อยให้ติดลบได้"*

---

#### BUG-V3-007 · ชำระหนี้ข้ามร้านได้ + จ่ายเกินยอด + จ่ายติดลบเพื่อเพิ่มหนี้

**ที่:** `../EazyStoreAPI/controllers/payment/payment_controller.go:55, 62`
**อาการ:** สามข้อในฟังก์ชันเดียว

1. **ข้ามร้าน:** บรรทัด 55 หาลูกหนี้ด้วย `WHERE debtor_id = ?` เท่านั้น ไม่เช็ค `shop_id` — PIN ที่ตรวจไปตอนบรรทัด 41 เป็น PIN ของร้านตัวเอง ผู้ใช้ร้าน A จึงตัดหนี้ลูกหนี้ร้าน B ได้ด้วย PIN ร้านตัวเอง
2. **จ่ายเกิน:** บรรทัด 62 `newTotalDebt := debtor.CurrentDebt - input.AmountPaid` ไม่มีเพดาน — หนี้ 500 จ่าย 5000 → หนี้กลายเป็น **-4500**
3. **จ่ายติดลบ:** `binding:"required"` บน `float64` กันได้แค่ค่า 0 ส่ง `amount_paid: -1000` ผ่านฉลุย → `500 - (-1000)` = หนี้กลายเป็น **1500** ใช้ endpoint ชำระหนี้เพื่อ**เพิ่ม**หนี้ได้

**เสริม:** บรรทัด 88 `tx.Commit()` ไม่เช็ค error → ถ้า commit ล้มเหลว client ยังได้ 200 "บันทึกการชำระเงินเรียบร้อย"

---

#### BUG-V3-008 · IDOR ทั่วทั้งระบบ — เข้าถึงข้อมูลร้านอื่นได้ทั้งหมด

**ที่:** ทุก controller ยกเว้น `shop_controller.go:63`
**อาการ:** `shop_id` มาจาก query string หรือ request body เสมอ ไม่เคยดึงจาก JWT

จุดที่ยืนยันแล้ว:

| Endpoint | บรรทัด | ทำอะไรได้ |
|---|---|---|
| `PUT /api/products/:id` | `product_controller.go:176` | แก้ชื่อ/ราคา/บาร์โค้ดสินค้าร้านอื่น |
| `DELETE /api/products/:id` | `product_controller.go:281` | ลบสินค้าร้านอื่น |
| `PUT /api/products/stock` | `product_controller.go:133-135` | เติม/ลดสต็อกสินค้าร้านอื่น |
| `GET /api/products` | `get_product_controller.go:96` | อ่านแคตตาล็อกทั้งร้านของคนอื่น |
| `PUT /api/debtors/:id` | `debtor_controller.go:300-307` | แก้ข้อมูลลูกหนี้ร้านอื่น |
| `GET /api/debtors/:id/history` | `debtor_controller.go:174` | อ่านประวัติหนี้ร้านอื่น |
| `POST /api/debtors` | `debtor_controller.go:29-45` | สร้างลูกหนี้ในร้านคนอื่น |
| dashboard ทั้ง 6 route | `controllers/dashboad/*` | อ่านยอดขาย กำไร ต้นทุน ของร้านคู่แข่ง |

**สาเหตุ:** middleware เก็บแค่ `user_id`/`username` ลง context (`middleware/auth.go:49-50`) ฟังก์ชัน `GetShopIDFromAuth` ที่บรรทัด 58 เขียนไว้แล้วแต่ตรวจสอบทั้ง repo แล้ว**ไม่มีที่ไหนเรียกใช้เลย**

---

#### BUG-V3-009 · ขายเชื่อโดยไม่บันทึกหนี้ / ส่งจำนวนติดลบเพื่อเพิ่มสต็อก

**ที่:** `../EazyStoreAPI/controllers/sales/sale_credit_controller.go:27, 56, 62, 70, 84`
**อาการ:** `CreateCreditSale` bind `models.Sale` ทั้งก้อนซึ่ง**ไม่มี binding tag แม้แต่ตัวเดียว** (`models/sale.go:8-32`)

1. **ขายเชื่อฟรี:** บรรทัด 56 `amountToCharge := input.NetPrice - input.Pay` — client ส่ง `pay` เท่ากับ `net_price` ได้ → `amountToCharge = 0` → สินค้าถูกตัดสต็อก แต่หนี้ไม่เพิ่ม
2. **จำนวนติดลบ:** ไม่มีที่ไหนเช็ค `item.Amount > 0` — บรรทัด 70 `if product.Stock < item.Amount` ถ้า Amount = -5 เงื่อนไขเป็นเท็จ ผ่านไปบรรทัด 77 `stock - (-5)` → **สต็อกเพิ่ม 5 โดยไม่ต้องเติมของ**
3. **บิลเปล่า:** ไม่เช็ค `len(input.SaleItems) == 0` → สร้างบิลไม่มีสินค้าแต่เพิ่มหนี้ได้
4. **Mass assignment:** บรรทัด 84 `tx.Create(&input)` — client กำหนด `sale_id` เองได้

**เสริม:** บรรทัด 100-103 คืน **HTTP 500** สำหรับทุก business rule (วงเงินเกิน / สต็อกไม่พอ / ไม่พบลูกหนี้) ควรเป็น 400 หรือ 409 — Flutter จึงแยกไม่ออกว่าเซิร์ฟเวอร์พังหรือผู้ใช้ทำผิด

---

#### BUG-V3-010 · รหัสผ่านฐานข้อมูลจริงอยู่ในโค้ดที่ commit ขึ้น git

**ที่:** `../EazyStoreAPI/database/db.go:16`
**อาการ:** DSN ของฐานข้อมูล production เขียน hardcode ไว้ในโค้ด พร้อม username/password/host/port ครบ ไม่มีทางอ่านจาก env var เลย

**ผลกระทบ:** ใครก็ตามที่เข้าถึง repo ได้ (รวมถึงถ้า repo เคยเป็น public แม้ชั่วคราว) ต่อฐานข้อมูล production ได้ตรงๆ

**เสริม:** ไฟล์ `EazyStoreAPI.exe` ขนาด 48 MB ก็ถูก commit ขึ้นไปด้วย ทั้งที่ `.gitignore:8` ระบุไว้แล้ว — binary ตัวนั้นมี DSN ฝังอยู่ข้างในเช่นกัน

---

### 🟠 HIGH

---

#### BUG-V3-011 · หน้าจอ crash ถ้า `conversion_qty` เป็น 0

**ที่:** [stock_format.dart:20-21](lib/utils/stock_format.dart#L20)
**อาการ:** `stock ~/ largest.conversionQty` และ `stock % largest.conversionQty` ไม่มีการกัน 0 → โยน `IntegerDivisionByZeroException` ทำให้หน้ารายละเอียดสินค้าและหน้าเช็คสต็อกขึ้นจอแดง

**หมายเหตุ:** จุดอื่นที่หารด้วย `conversionQty` ในตะกร้าทั้ง 3 จุด (`checkout_controller.dart:423`, `:524`) **มีการกันไว้แล้ว** เหลือแค่ไฟล์นี้ที่ไม่กัน

**เส้นทางที่ 0 เข้าถึงได้:** [product_response.dart:31](lib/model/response/product_response.dart#L31) เขียน `json['conversion_qty'] ?? 1` — `??` ทำงานเฉพาะตอนค่าเป็น `null` ถ้า backend ส่ง `0` มาจริงๆ จะได้ 0 ไปเลย และ migration `003_product_units.sql` ประกาศคอลัมน์เป็น `INT NOT NULL` เฉยๆ ไม่มี `CHECK (conversion_qty > 1)` ระดับฐานข้อมูล

---

#### BUG-V3-012 · สินค้าไม่มีบาร์โค้ดได้สต็อก 999 และหน่วยขายหายหมด

**ที่:** [checkout_controller.dart:125-141](lib/page/sale_producct/sale/checkout_controller.dart#L125)
**อาการ:** เส้นทางนี้สร้าง `ProductResponse` ด้วยมือแทนที่จะเรียก `ProductResponse.fromJson` ผลคือ

1. บรรทัด 136 `stock: int.tryParse(...) ?? 999` — ถ้า backend ไม่ส่ง `stock` มา สินค้าจะมีสต็อก **999** ขายได้ไม่จำกัด
2. **ไม่ส่ง `units:` เข้าไปเลย** → สินค้าไม่มีบาร์โค้ดจะไม่มีหน่วยขายเพิ่มเติมในตะกร้า แม้ backend จะส่งมาก็ตาม

**วิธี reproduce:** เพิ่มสินค้าไม่ใส่บาร์โค้ด ตั้งหน่วยขาย "ลัง" ไว้ → เข้าหน้าขาย ค้นหาสินค้านั้น → ไม่มี chip "ลัง" ให้เลือก

---

#### BUG-V3-013 · หน้าสมุดสินค้าไม่มีบาร์โค้ด ไม่รองรับหน่วยขายเลย

**ที่:** [book_list_no_barcode_controller.dart](lib/page/sale_producct/bookListNoBarcode/book_list_no_barcode_controller.dart) และ [book_list_no_barcode.dart](lib/page/sale_producct/bookListNoBarcode/book_list_no_barcode.dart)
**อาการ:** commit multi-unit แก้ไฟล์คู่นี้ไป +140/−89 บรรทัด แต่ค้นทั้งสองไฟล์แล้ว**ไม่พบการอ้างถึง `unitName`, `conversionQty`, `activeUnits`, `unitId` แม้แต่ครั้งเดียว**

**ผลกระทบ:** สินค้าที่เลือกจากสมุดนี้เข้าตะกร้าเป็นหน่วยฐานเสมอ ไม่มีทางเลือกขายเป็นลังจากหน้านี้ ต่างจากช่องค้นหาในหน้า Checkout ที่มี chip ให้เลือก — ผู้ใช้จะสับสนว่าทำไมสินค้าตัวเดียวกันเลือกหน่วยได้จากที่หนึ่งแต่ไม่ได้จากอีกที่

---

#### BUG-V3-014 · แอปขึ้น error ตอนกดยืนยันการขาย ถ้า `product_id` เป็น null

**ที่:** [checkout_controller.dart:821](lib/page/sale_producct/sale/checkout_controller.dart#L821)
**อาการ:** `int.parse(item.id)` โดย `item.id` มาจาก `product.productId.toString()` และ `ProductResponse.productId` ประกาศเป็น `int?` (nullable ที่ [product_response.dart:51](lib/model/response/product_response.dart#L51))

ถ้า `productId` เป็น null → `.toString()` ได้สตริง `"null"` → `int.parse("null")` โยน `FormatException` ตอนกดยืนยัน ผู้ใช้เห็น dialog *"ข้อผิดพลาดระบบ: พบปัญหา: FormatException..."* — ตะกร้ายังอยู่แต่ขายไม่ได้ ไม่มีทางรู้ว่าสินค้าตัวไหนมีปัญหา

**เส้นทางที่เกิด:** [checkout_controller.dart:127](lib/page/sale_producct/sale/checkout_controller.dart#L127) `int.tryParse(...)` คืน `null` ได้ถ้า backend ไม่ส่ง `product_id` หรือ `id` มา

---

#### BUG-V3-015 · หน้าเพิ่มสินค้าพัง ถ้าพิมพ์ตัวอักษรในช่องจำนวน

**ที่:** [add_product_controller.dart:175](lib/page/product/add_product/add_product_controller.dart#L175)
**อาการ:** ใช้ `int.parse()` ในขณะที่บรรทัด 173-174 ที่อยู่ติดกันใช้ `double.tryParse(...) ?? 0.0` — ไม่สม่ำเสมอ

กรอก "abc" ในช่องจำนวน → `FormatException` ถูกจับที่ catch บรรทัด 190 → ขึ้น snackbar *"เกิดข้อผิดพลาด: FormatException: abc"* ซึ่งเป็นข้อความ exception ดิบ ผู้ใช้ทั่วไปอ่านไม่รู้เรื่อง

---

#### BUG-V3-016 · API พังทั้งชุดถ้าเซิร์ฟเวอร์คืน HTML แทน JSON

**ที่:** ~15 จุดใน [api_auth.dart](lib/api/api_auth.dart) และ [api_product.dart](lib/api/api_product.dart) — ตัวอย่าง `api_auth.dart:34, 76, 106, 131, 161, 192, 209` และ `api_product.dart:32, 202, 246, 308, 477, 512, 541, 646`
**อาการ:** เรียก `jsonDecode(response.body)` **ก่อน**เช็ค `statusCode` เสมอ

เมื่อ nginx/proxy คืนหน้า 502 เป็น HTML หรือ 404 คืน body ว่าง → `FormatException` ถูกโยนภายใน try → catch แปลงเป็นข้อความเดียวกันหมด *"ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้"* ทั้งที่จริงๆ เซิร์ฟเวอร์ตอบมาแล้วแต่ตอบไม่ใช่ JSON

**ทำไมสำคัญตอนนี้:** endpoint หน่วยขายทั้ง 3 ตัวคืน 404 อยู่แล้วบน `main` (ดู BUG-V3-001) ผู้ใช้จะเห็นแค่ "เชื่อมต่อไม่ได้" ไม่มีทางรู้ว่าฟีเจอร์ไม่มีในเซิร์ฟเวอร์

**มีจุดเดียวที่ทำถูก:** `api_sale.dart:62` แยก decode ออกมาต่างหาก

---

#### BUG-V3-017 · ออกจากระบบไม่หมด PIN ร้านค้าค้างข้ามบัญชี

**ที่:** มี 3 เส้นทางที่เคลียร์ session และ**เคลียร์ไม่เท่ากันเลยสักคู่**

| เส้นทาง | ไฟล์ | เคลียร์อะไร |
|---|---|---|
| หมดอายุ / 401 | [auth_guard.dart:127-131](lib/utils/auth_guard.dart#L127) | 5 key: `token`, `refresh_token`, `token_expires_at`, `shopId`, `shopName` |
| Splash เช็ค token ไม่ผ่าน | [splash_screen.dart:60-64](lib/page/checkToken/splash_screen.dart#L60) | 5 key เหมือนกัน |
| กดปุ่มออกจากระบบ | [profile_controller.dart:333](lib/page/profile/profile_controller.dart#L333) | `prefs.clear()` — ล้างหมด |

**ผลกระทบ:** ถ้าออกจากระบบด้วยเส้นทางที่ 1 หรือ 2 (ซึ่งเกิดบ่อยกว่าการกดปุ่ม) ค่าเหล่านี้จะค้างอยู่: `userId`, `username`, `shopAddress`, `shop_image`, **`pinCode`**

`pinCode` คือ PIN 6 หลักที่ใช้ยืนยันการชำระหนี้ ([debt_payment.dart:34](lib/page/debt/debtPayment/debt_payment.dart#L34)) — ค้างอยู่ในเครื่องหลังผู้ใช้คนก่อนออกจากระบบ

---

#### BUG-V3-018 · `limit` ไม่ใช่ตัวเลข ทำให้ `total_pages` เป็นค่าขยะ

**ที่:** `../EazyStoreAPI/controllers/products/get_product_controller.go:81-82, 154` และ `debtor_controller.go:107-108`
**อาการ:** `strconv.Atoi` ทิ้ง error ด้วย `_` ถ้าแปลงไม่ได้จะได้ 0

`?limit=abc` → `limit = 0` → บรรทัด 154 `math.Ceil(float64(totalItems) / float64(0))` = `+Inf` → `int(+Inf)` ใน Go เป็น undefined behavior ปกติได้ค่าติดลบมหาศาล → JSON คืน `"total_pages": -9223372036854775808`

**เพิ่มเติม:** `?page=0` → `offset = (0-1) * limit` = ติดลบ → MySQL error 1064 หรือ GORM ตัดทิ้งแล้วคืนหน้าแรกเงียบๆ

---

#### BUG-V3-019 · Token เก็บแบบ plaintext อ่านได้จากเครื่องที่ root/jailbreak

**ที่:** [login.dart:61-69](lib/page/auth/login.dart#L61), [auth_guard.dart:46-49](lib/utils/auth_guard.dart#L46)
**อาการ:** ทั้ง `token` และ `refresh_token` เก็บใน `SharedPreferences` ซึ่งบน Android คือไฟล์ XML ธรรมดาใน `/data/data/<pkg>/shared_prefs/` ไม่ได้เข้ารหัส `pubspec.yaml` ไม่มี `flutter_secure_storage`

**ทำไมหนักกว่าปกติ:** ประกอบกับ BUG-V3-003 (refresh token ใช้แทน access token ได้) และไม่มี token rotation ฝั่ง backend (`auth_controller.go:279`) → refresh token ที่หลุดใช้ได้เต็ม 7 วัน ยกเลิกไม่ได้จนกว่าผู้ใช้จะกด logout

---

#### BUG-V3-020 · `tx.Commit()` ไม่เช็ค error — บอกสำเร็จทั้งที่บันทึกไม่ลง

**ที่:** `../EazyStoreAPI/controllers/sales/sale_cash_controller.go:89` และ `controllers/payment/payment_controller.go:88`
**อาการ:** เขียน `tx.Commit()` โดยไม่ดูค่าที่คืนกลับ ถ้า commit ล้มเหลว (deadlock, connection ขาด, disk เต็ม) client ยังได้ 200 พร้อมข้อความ "บันทึกการขายสำเร็จ" ทั้งที่ข้อมูลไม่ได้ลงฐานข้อมูล

Flutter จะเคลียร์ตะกร้าทิ้งที่ [checkout_controller.dart:861](lib/page/sale_producct/sale/checkout_controller.dart#L861) → **บิลหายไปเลย ไม่มีทางกู้**

---

#### BUG-V3-021 · แก้ราคาสินค้าด้วยข้อมูลผิดชนิด บันทึกประวัติราคาผิด

**ที่:** `../EazyStoreAPI/controllers/products/product_controller.go:214-242`
**อาการ:** `newPrice, _ := val.(float64)` — ถ้า client ส่ง `"sell_price": "50"` เป็นสตริง type assertion ล้มเหลวเงียบๆ ได้ `newPrice = 0` แล้วบันทึกลง `sell_price_logs` ว่าราคาใหม่คือ 0 แต่ค่าที่ส่งต่อไปให้ GORM เขียนจริงคือสตริง `"50"`

**เพิ่มเติม (สำคัญกว่า):** whitelist บรรทัด 191-195 อนุญาต `"barcode"` แต่**ไม่มีการเช็คบาร์โค้ดซ้ำเลย** ต่างจาก `CreateProduct` บรรทัด 37-46 ที่เช็ค → แก้บาร์โค้ดสินค้าให้ซ้ำกับสินค้าอื่นในร้านเดียวกันได้ ทำให้การสแกนบาร์โค้ดตอนขายเจอสินค้าผิดตัว

whitelist ยังมี `"status"` ด้วย → คืนชีพสินค้าที่ถูก soft-delete ไปแล้วผ่าน endpoint แก้ไขได้

---

#### BUG-V3-022 · แก้โปรไฟล์ด้วย JSON ผิดชนิด ทำเซิร์ฟเวอร์ panic

**ที่:** `../EazyStoreAPI/controllers/user/user_controller.go:65, 80, 93, 107`
**อาการ:** type assertion แบบไม่รับค่า ok — `val.(string)` ถ้าค่าที่ส่งมาไม่ใช่ string จะ panic

**วิธี reproduce:** `PUT /api/profile/update` body `{"username": 123}` → gin Recovery middleware จับ panic คืน **HTTP 500 body ว่าง** ไม่มี JSON error ให้ Flutter parse → Flutter เจอ `FormatException` ต่อ (ดู BUG-V3-016)

---

#### BUG-V3-023 · สร้างลูกหนี้โดยไม่มี validation ใดๆ กำหนดยอดหนี้เองได้

**ที่:** `../EazyStoreAPI/models/debtor.go:4-13` และ `controllers/debtor/debtor_controller.go:29-45`
**อาการ:** struct `Debtor` **ไม่มี binding tag แม้แต่ตัวเดียว** ทำให้

- `name` และ `phone` ว่างเปล่าได้
- `credit_limit` ติดลบได้
- **`current_debt` client กำหนดเองได้** → สร้างลูกหนี้ที่มีหนี้ 50,000 บาททันทีโดยไม่มีบิลขายรองรับ ทำให้รายงานลูกหนี้และ aging report เพี้ยนทั้งหมด
- `shop_id` มาจาก client → สร้างลูกหนี้ในร้านคนอื่นได้ (ดู BUG-V3-008)

**ฝั่ง Flutter:** ฟอร์มลงทะเบียนลูกหนี้ก็ไม่ validate รูปแบบเบอร์โทร (ยกมาจาก BUG-009 รอบแรก — **ยังไม่ได้แก้**)

---

#### BUG-V3-024 · รหัสสินค้าซ้ำกันได้ถ้าเพิ่มสินค้าพร้อมกัน

**ที่:** `../EazyStoreAPI/controllers/products/product_controller.go:49-82`
**อาการ:** สร้าง `product_code` ด้วยการ "อ่านตัวล่าสุด แล้ว +1 แล้วค่อย insert" โดยไม่มี transaction lock และไม่มี unique constraint รองรับ

- สองคำขอพร้อมกันในร้านเดียวกันอ่านค่าเดิมได้เหมือนกัน → ได้ `product_code` ซ้ำกัน
- บรรทัด 53 เรียงด้วย `product_id desc` ไม่ใช่ตัวเลขในรหัส ถ้าแถวล่าสุดมีรหัสรูปแบบผิด บรรทัด 75-77 จะ fallback เป็น `_001` ซึ่ง**ชนกับสินค้าตัวแรกของร้าน**

**เพิ่มเติม:** การเช็คบาร์โค้ดซ้ำบรรทัด 37-46 ก็เป็นแบบ check-then-insert เหมือนกัน มี race condition ระดับเดียวกัน

---

#### BUG-V3-025 · เรียกคืนบิลที่พักไว้ อาจได้ของเกินสต็อก

**ที่:** [checkout_controller.dart:515-538](lib/page/sale_producct/sale/checkout_controller.dart#L515)
**อาการ:** ลูป `for (final pi in parked.items)` clamp แต่ละรายการเทียบกับ `effectiveMaxStock` เต็มจำนวน **แยกกันคนละรอบ ไม่ได้หักลบสะสม**

**วิธี reproduce:**
1. สินค้า A สต็อก 12 ขวด มีหน่วย "ลัง" = 12 ขวด
2. ใส่ตะกร้า 1 ลัง (12 ขวด) + 0 ขวด แล้วพักบิล
3. ระหว่างนั้นขายไป 6 ขวดจากอีกเครื่อง สต็อกเหลือ 6
4. เรียกคืนบิล → บรรทัดลังคำนวณ `12 clamp to 6` → `6 ~/ 12 = 0` ลัง (ถูก) แต่ถ้ามีอีกบรรทัดเป็นขวดอยู่ด้วย บรรทัดนั้นจะ clamp เทียบ 6 เต็มอีกรอบ → **รวมกันเกิน 6**

ต่างจาก `_addToCart` บรรทัด 342 และ `setQuantity` บรรทัด 418 ที่คำนวณ `usedBase` สะสมข้ามบรรทัดถูกต้อง

---

#### BUG-V3-026 · หน้าเช็คราคา/ค้นหา คืนสินค้าแค่ตัวเดียวแบบสุ่ม

**ที่:** `../EazyStoreAPI/controllers/products/get_product_controller.go:192-200`
**อาการ:** `GetProductBySearch` ใช้ `.First(&product)` คืนสินค้าตัวเดียว โดยเงื่อนไขมี `name LIKE '%keyword%'` อยู่ด้วย

ค้นคำกว้างๆ อย่าง "น้ำ" ที่ตรงกับสินค้า 30 ตัว → ได้กลับมาแค่ตัวเดียว เป็นตัวที่ `product_id` น้อยที่สุด ไม่ใช่ตัวที่ตรงที่สุด

**เพิ่มเติม:** บรรทัด 197-200 คืน **404** เมื่อไม่เจอ แทนที่จะเป็น 200 พร้อม array ว่าง — เส้นทาง search ของลูกหนี้ที่ `debtor_controller.go:85-88` ก็ทำแบบเดียวกัน ทำให้ Flutter แยกไม่ออกระหว่าง "ไม่มีผลลัพธ์" กับ "endpoint หาย"

---

### 🟡 MEDIUM

---

#### BUG-V3-027 · ฟอร์มหน่วยขายหน้าแก้ไขสินค้า validate ไม่ครบเท่าหน้าเพิ่มสินค้า

**ที่:** [edit_product_screen.dart:874-895](lib/page/product/edit_product/edit_product_screen.dart#L874) เทียบกับ [add_product_controller.dart:288-349](lib/page/product/add_product/add_product_controller.dart#L288)

| การตรวจ | หน้าเพิ่มสินค้า | หน้าแก้ไขสินค้า |
|---|---|---|
| ชื่อหน่วยว่าง | ✅ | ✅ |
| `conversion_qty > 1` | ✅ (`:311`) | ✅ (`:886`) |
| ราคาขาย > 0 | ✅ (`:318`) | ✅ (`:891`) |
| ชื่อหน่วยซ้ำกับหน่วยฐาน | ✅ (`:299`) | ❌ **ไม่มี** |
| ชื่อหน่วยซ้ำกับหน่วยอื่น | ✅ (`:304`) | ❌ **ไม่มี** |
| บาร์โค้ดซ้ำกับบาร์โค้ดหลัก | ✅ (`:328`) | ❌ **ไม่มี** |
| บาร์โค้ดซ้ำกับหน่วยอื่น | ✅ (`:333`) | ❌ **ไม่มี** |

**ผลกระทบ:** บน `main` ไม่มี backend รองรับอยู่แล้ว (404) บน `feature/multi-unit` backend เช็คให้ครบที่ `product_unit_controller.go` แต่ผู้ใช้จะเห็น error หลังกดบันทึกแทนที่จะเห็นทันทีขณะกรอก

---

#### BUG-V3-028 · Memory leak ทุกครั้งที่เปิดฟอร์มหน่วยขาย

**ที่:** [edit_product_screen.dart:742-752](lib/page/product/edit_product/edit_product_screen.dart#L742)
**อาการ:** สร้าง `TextEditingController` 5 ตัวใน `_showUnitFormSheet` แล้ว **ไม่มี `dispose()` ที่ไหนเลย** เปิดฟอร์ม 20 ครั้ง = 100 controller ค้างในหน่วยความจำ

เทียบกับหน้าเพิ่มสินค้าที่จัดการถูกต้อง — `UnitFormEntry` มี `dispose()` และถูกเรียกที่ `add_product_controller.dart:280`

---

#### BUG-V3-029 · กล่องยืนยันแสดงยอดเงินไม่ตรงกับที่หักจริง

**ที่:** [checkout_controller.dart:714](lib/page/sale_producct/sale/checkout_controller.dart#L714)
**อาการ:** `"${totalPrice.toInt()} ฿"` — `.toInt()` **ตัดทศนิยมทิ้ง** ไม่ใช่ปัดเศษ

ยอดจริง 99.50 บาท → กล่องยืนยันแสดง **"99 ฿"** แต่ค่าที่ส่งไป backend ที่บรรทัด 846 คือ `netPrice: totalPrice` = 99.50 เต็ม → ลูกค้าเห็นยอดหนึ่ง ระบบบันทึกอีกยอดหนึ่ง

---

#### BUG-V3-030 · จำนวนสินค้าในกล่องยืนยันนับผิดหน่วย

**ที่:** [checkout_controller.dart:667](lib/page/sale_producct/sale/checkout_controller.dart#L667)
**อาการ:** `"${cartItems.length} ชิ้น"` — `cartItems` เก็บ 1 แถวต่อ 1 หน่วยที่ขาย ไม่ใช่ต่อชิ้นฐาน

ขาย 2 ลัง (ลังละ 12 ขวด) → แสดง **"2 ชิ้น"** ทั้งที่จริงคือ 24 ขวด — หน่วย "ชิ้น" ที่ hardcode ไว้ไม่ตรงกับสิ่งที่นับ

---

#### BUG-V3-031 · ตั้งสต็อกเป็น 0 ไม่ได้

**ที่:** `../EazyStoreAPI/models/product.go:21-24`
**อาการ:** `Stock int \`binding:"required"\`` — ใน Go validator คำว่า `required` แปลว่า "ต้องไม่ใช่ zero value" สำหรับ `int` คือ **ต้องไม่ใช่ 0**

ส่ง `{"product_id": 5, "stock": 0}` → 400 *"ข้อมูลไม่ถูกต้อง"* ทั้งที่การเติมสต็อก 0 (เช่น กดบันทึกโดยแก้แต่ราคา) ควรผ่าน

**เพิ่มเติม:** `stock` ติดลบผ่าน validator ได้ แล้ว `gorm.Expr("stock + ?", -100)` จะลดสต็อกผ่าน endpoint ที่ชื่อว่า "เพิ่มสต็อก"

**เจอรูปแบบเดียวกันที่:** `sale_cash_controller.go:26-27` — `PricePerUnit` และ `TotalPrice` เป็น `binding:"required"` → **ขายสินค้าราคา 0 บาท (ของแถม) ไม่ได้** จะโดน 400

---

#### BUG-V3-032 · Logic ตัดสินใจผูกกับข้อความภาษาไทยจาก backend

**ที่:** [login.dart:45](lib/page/auth/login.dart#L45) และ [register.dart:76](lib/page/auth/register.dart#L76)
**อาการ:**

```dart
res.error!.contains("ยืนยันตัวตน")      // login.dart:45
res.error!.contains("ถูกใช้งานแล้ว")     // register.dart:76
```

Flutter ตัดสินใจว่าจะเปิด dialog ยืนยัน OTP หรือไม่ โดยเทียบสตริงภาษาไทยจาก error message ของ backend

**ผลกระทบ:** backend แก้คำหรือเว้นวรรคเปลี่ยนแม้แต่ตัวเดียว → flow ยืนยันตัวตนพังเงียบ ผู้ใช้ที่ยังไม่ยืนยันอีเมลจะเห็นแค่ "เข้าสู่ระบบไม่สำเร็จ" ติดค้างไปตลอด

**ทางที่ถูก:** backend ส่ง `"is_verified": false` มาให้แล้วที่ `auth_controller.go:194` — ใช้ field นั้นแทน

---

#### BUG-V3-033 · Login เผยอีเมลจริงของบัญชีคนอื่น

**ที่:** `../EazyStoreAPI/controllers/auth/auth_controller.go:191-199`
**อาการ:** บรรทัด 181 ตั้ง `invalidMsg` ไว้เพื่อกัน user enumeration แต่ 10 บรรทัดถัดมากลับคืน **อีเมลจริงและ username จริงจากฐานข้อมูล** ใน response 403 — และเช็คนี้อยู่**ก่อน**การตรวจรหัสผ่าน

**วิธี reproduce:** ยิง `POST /api/auth/login` ด้วยเบอร์โทรที่เดาไปเรื่อยๆ กับรหัสผ่านมั่วๆ ถ้าเบอร์นั้นมีบัญชีที่ยังไม่ยืนยัน → ได้ 403 พร้อมอีเมลจริงกลับมา โดยไม่ต้องรู้รหัสผ่านเลย

---

#### BUG-V3-034 · Dashboard คืน 200 พร้อมเลข 0 เมื่อ query ล้มเหลว

**ที่:** ทุก `.Scan()` ใน `controllers/dashboad/` — `dashboad_sale_controller.go:35-66`, `dashboard_details_controller.go:32-36, 64-79`, `advanced_report_controller.go:29-42, 77-84, 92-99, 108-116, 124-134, 153-186, 195-200, 207-216, 262-304`
**อาการ:** ไม่มีจุดไหนเช็ค error ที่ `.Scan()` คืนมาเลย ถ้า query พัง (ตารางหาย คอลัมน์เปลี่ยน DB ล่ม) struct ยังเป็นค่าเริ่มต้น = 0 แล้วคืน HTTP 200

**ผลกระทบ:** เจ้าของร้านเปิดหน้ารายงานเห็น "ยอดขายวันนี้ 0 บาท" แล้วเข้าใจว่าวันนี้ขายไม่ได้จริงๆ ทั้งที่ระบบมีปัญหา — ผิดพลาดในทิศทางที่อันตรายที่สุดสำหรับรายงานการเงิน

**เจอรูปแบบเดียวกันที่:** `query.Count()` ไม่เช็ค error ที่ `get_product_controller.go:109` และ `debtor_controller.go:128`

---

#### BUG-V3-035 · เรียงชื่อสินค้าภาษาไทย ดึงสินค้าทั้งร้านมาทุกครั้ง

**ที่:** `../EazyStoreAPI/controllers/products/get_product_controller.go:116-141`
**อาการ:** โหมด `name_asc` / `name_desc` ต้องเรียงด้วย `thaiSortKey` ในภาษา Go จึงเรียก `query.Find(&products)` **โดยไม่มี LIMIT** ดึงสินค้าทุกตัวของร้านมาก่อน แล้วค่อย slice ในหน่วยความจำ

ร้านที่มีสินค้า 10,000 ตัว การเปิดหน้าสินค้าหน้าละ 10 รายการจะดึง 10,000 แถวทุกครั้งที่เปลี่ยนหน้า

**หมายเหตุ:** วิธีนี้ให้ผลลัพธ์ที่ถูกต้อง (คอมเมนต์บรรทัด 118-121 อธิบายเหตุผลไว้ชัด) แต่ scale ไม่ได้ — ควรมีคอลัมน์ `name_sort_key` เก็บไว้ในตารางแล้วให้ MySQL เรียงแทน

---

#### BUG-V3-036 · ค้นหาด้วย `%` หรือ `_` ได้ผลลัพธ์ทุกอย่าง

**ที่:** `get_product_controller.go:100, 194`, `debtor_controller.go:78, 124`
**อาการ:** สร้าง pattern ด้วย `"%"+search+"%"` โดยไม่ escape อักขระพิเศษของ LIKE

ค้นหา `50%` → กลายเป็น `LIKE '%50%%'` → `%` ตัวหลังเป็น wildcard → ตรงกับสินค้าทุกตัวที่มี "50"
ค้นหา `_` เดี่ยวๆ → `LIKE '%_%'` → ตรงกับทุกแถวที่ชื่อยาวอย่างน้อย 1 ตัวอักษร = ทั้งร้าน

**หมายเหตุ:** ไม่ใช่ช่องโหว่ SQL injection — ค่าถูกส่งเป็น bound parameter ถูกต้อง เป็นแค่พฤติกรรมการค้นหาที่ผิดคาด

---

#### BUG-V3-037 · Token ไม่ต่ออายุล่วงหน้าถ้าไม่มี `token_expires_at`

**ที่:** [auth_guard.dart:71](lib/utils/auth_guard.dart#L71)
**อาการ:** `if (expiresAt > 0 && now > expiresAt - 60)` — ถ้า key `token_expires_at` ไม่มีอยู่ `prefs.getInt()` คืน `null` → `?? 0` → เงื่อนไข `expiresAt > 0` เป็นเท็จ → **ข้ามการต่ออายุล่วงหน้าไปเลย**

ผู้ใช้ที่ล็อกอินไว้ก่อนที่จะมีการเก็บ key นี้ หรือเครื่องที่ key หายไปด้วยเหตุใดก็ตาม จะต้องรอให้เจอ 401 ก่อนเสมอ ทำให้ทุก request แรกหลัง token หมดอายุล้มเหลว 1 ครั้ง

**หนักขึ้นเพราะ:** endpoint ส่วนใหญ่หลังเรียก `handleUnauthorized()` แล้ว**ไม่ยิงซ้ำ** แค่คืน `null`/`false`/`[]` มีแค่ `ApiProduct.getCategories` (`api_product.dart:80-90`) และ `getInactiveCategories` (`:158-167`) ที่ยิงซ้ำจริง — endpoint อื่นผู้ใช้จะเห็น "โหลดข้อมูลไม่สำเร็จ" ทั้งที่ token ต่ออายุสำเร็จไปแล้ว ต้องกดใหม่เอง

---

#### BUG-V3-038 · `GET /api/profile` โดน redirect ทำให้ Authorization header หาย

**ที่:** `../EazyStoreAPI/routes/profile_routes.go:16`
**อาการ:** ลงทะเบียน route เป็น `"/"` ในกลุ่ม `/api/profile` ทำให้ path จริงคือ `/api/profile/` (มี slash ปิดท้าย)

เรียก `GET /api/profile` (ไม่มี slash) → Gin คืน **301 Moved Permanently** → HTTP client จำนวนมากรวมถึง `package:http` ของ Dart **ตัด header `Authorization` ทิ้งตอน redirect** ด้วยเหตุผลด้านความปลอดภัย → request ที่สองไปถึงแบบไม่มี token → 401

---

#### BUG-V3-039 · การแปลง JSON ที่ไม่ปลอดภัยหลายจุดใน model

**ที่:** หลายไฟล์ใน `lib/model/response/`

| จุด | ปัญหา |
|---|---|
| [debtor_response.dart:48](lib/model/response/debtor_response.dart#L48) | `(json['items'] as List)` — cast แบบไม่มี `?` ถ้า backend คืน `{"error": ...}` แทน → `TypeError` ทันที (ทุก paged model อื่นใช้ `as List?`) |
| [product_response.dart:128](lib/model/response/product_response.dart#L128) | `stock: json['stock'] ?? 0` ประกาศเป็น `int` — ถ้า MySQL/GORM คืน `10.0` เป็น float → `TypeError` |
| [product_response.dart:31](lib/model/response/product_response.dart#L31) | `conversionQty: json['conversion_qty'] ?? 1` — ถ้าเป็นสตริง `"12"` → `TypeError` (ดู BUG-V3-011 สำหรับกรณีค่า 0) |
| [product_response.dart:35,130](lib/model/response/product_response.dart#L35) | `status: json['status'] ?? true` — ค่า default เป็น "แสดง" ถ้า backend ไม่ส่ง field มา สินค้าที่ถูกซ่อนจะโผล่กลับมา |
| `advanced_report_response.dart:45,60,75,93,106,121,139,173,209`<br>`sales_summary_respone.dart:29-36`<br>`dashboard_detail_response.dart:21,54,89,123` | `(json['x'] ?? 0).toDouble()` — ถ้า MySQL DECIMAL ถูก serialize เป็นสตริง (`"1500.00"`) จะโยน `NoSuchMethodError` เพราะ String ไม่มี `.toDouble()` |

**หมายเหตุ:** [debtor_response.dart:27-28](lib/model/response/debtor_response.dart#L27) ทำถูกแล้ว ใช้ `double.tryParse(json['x']?.toString() ?? '0') ?? 0.0` — ควรใช้รูปแบบนี้ทุกที่

---

#### BUG-V3-040 · ผลของ bcrypt ที่ล้มเหลวถูกบันทึกเป็นรหัสผ่านว่าง

**ที่:** `auth_controller.go:47, 53` และ `ResetPassword.go:156`
**อาการ:** `hashedPassword, _ := bcrypt.GenerateFromPassword(...)` ทิ้ง error ทั้งสามจุด

`bcrypt` คืน error เมื่อรหัสผ่านยาวเกิน **72 bytes** (ภาษาไทย 1 ตัว = 3 bytes → รหัสผ่านไทย 25 ตัวอักษรก็เกินแล้ว) ในกรณีนั้น `hashedPassword` เป็น slice ว่าง → บันทึกรหัสผ่านเป็นสตริงว่างลงฐานข้อมูล → บัญชีนั้น**ล็อกอินไม่ได้ตลอดกาล** และไม่มี error message บอกอะไรเลย

---

#### BUG-V3-041 · Status code สื่อความหมายผิด แยกไม่ออกว่าใครผิด

**ที่:** หลายจุด

| Endpoint | คืนอะไร | ควรเป็น |
|---|---|---|
| `POST /api/sales/credit` — วงเงินเกิน/สต็อกไม่พอ/ไม่พบลูกหนี้ | **500** (`sale_credit_controller.go:100-103`) | 400 หรือ 409 |
| `POST /api/sales` — สินค้าไม่มีในบิล | **500** (`sale_cash_controller.go:75, 83`) | 400 |
| `POST /api/categories` — error ใดๆ รวมถึง DB ล่ม | **409** (`category_controller.go:27`) | 409 เฉพาะชื่อซ้ำ, 500 สำหรับ DB |
| `PUT /api/categories/:id` — error ใดๆ | **409** (`category_controller.go:54`) | เหมือนข้างบน |
| `GET /api/debtors/search` — ไม่เจอ | **404** (`debtor_controller.go:85-88`) | 200 + `[]` |
| `GET /api/products/search` — ไม่เจอ | **404** (`get_product_controller.go:197-200`) | 200 + `[]` |

**เพิ่มเติม:** รูปแบบ response ไม่สม่ำเสมอด้วย — บางที่ `{"message","data"}` บางที่ array เปล่าๆ บางที่ `{"items","total_items",...}` บางที่ object ดิบ ทำให้ Flutter ต้องเขียน parse หลายแบบ (`api_product.dart` มีทั้ง 3 รูปแบบ)

---

### 🔵 LOW

---

#### BUG-V3-042 · `print()` 114 จุด log ข้อมูล response ดิบขึ้น logcat

**ที่:** ทั่วทั้ง `lib/` — หนักสุดที่ `checkout_controller.dart` (10 จุด), `api_auth.dart:31-32, 73-74` (log ข้อมูลตอน login/register)
**ผลกระทบ:** บน release build `print()` ยังทำงานอยู่ ใครก็ตามที่ต่อ `adb logcat` เห็นข้อมูลผู้ใช้และ response body ทั้งหมด

---

#### BUG-V3-043 · Cloudinary preset และ base URL hardcode ในโค้ด

**ที่:** [api_service_image.dart:8,11](lib/api/api_service_image.dart#L8), [app_config.dart:5-18](lib/config/app_config.dart#L5)
**อาการ:**
- cloud name `ddcuq2vh9` และ unsigned upload preset `eazy_store` hardcode ไว้ → ใครก็อัปโหลดรูปเข้า account นี้ได้ไม่จำกัด
- base URL: Android ใช้ `10.0.2.2:8080` (emulator), iOS/desktop ใช้ `192.168.6.1:8080` (LAN IP ประจำเครื่องนักพัฒนา) — **ทั้งหมดเป็น cleartext HTTP** ไม่มี HTTPS และไม่มีสวิตช์ build flavor / `--dart-define` เลย URL production ถูกคอมเมนต์ทิ้งไว้ที่บรรทัด 17-18

---

#### BUG-V3-044 · เอกสาร Swagger ไม่ตรงกับ API จริงเลย

**ที่:** `../EazyStoreAPI/docs/swagger.yaml`
**อาการ:**
- **14 path ที่เอกสารระบุไว้แต่ไม่มีจริง:** `/api/createProduct`, `/api/createShop`, `/api/createDebtor`, `/api/createCreditSale`, `/api/paymentDebt`, `/api/debtor`, `/api/debtor/search`, `/api/debtor/{id}/history`, `/api/product/search`, `/api/product/stock`, `/api/getShop`, `/api/getNullBarcode`, `/api/deleteShop/{shop_id}`, `/api/updateShop/{shop_id}`
- **ไม่มีในเอกสารเลย:** dashboard ทั้ง 6 route, category ทั้ง 7 route, `/api/sales`, `/api/orderlist`, `/api/profile*` และ 7 จาก 9 auth route
- `GET /swagger/*any` เข้าถึงได้โดยไม่ต้องล็อกอิน (`main.go:38`)

---

#### BUG-V3-045 · ไม่มีการทดสอบอัตโนมัติเลยทั้งสองฝั่ง

**ที่:** `test/widget_test.dart` (Flutter) และทั้ง repo (Go)
**อาการ:**
- Flutter: มีไฟล์เดียวคือ template นับเลขที่ Flutter สร้างให้ตอน `flutter create` — ทดสอบ `find.text('0')` และแตะ `Icons.add` ซึ่ง `MyApp` ไม่มีทั้งคู่ (มันเรนเดอร์ `SplashScreen`) → **test นี้ fail ถ้ารัน**
- Go: **ไม่มีไฟล์ `*_test.go` แม้แต่ไฟล์เดียว** ทั้ง repo
- ไม่มี `integration_test/`, ไม่มี mock library ใน `pubspec.yaml`, ไม่มี CI workflow, ไม่มี Postman collection

---

#### BUG-V3-046 · Environment variable ที่ตั้งไว้แต่ไม่มีใครใช้

**ที่:** `../EazyStoreAPI/.env:2`
**อาการ:** `GMAIL_APP_PASSWORD` ถูกตั้งค่าไว้ใน `.env` แต่ค้นทั้ง repo แล้วไม่มีโค้ดไหนอ่านเลย — ระบบส่งอีเมลจริงใช้ Google Apps Script ผ่าน HTTP แทน (`ResetPassword.go:30`) URL ของ script ก็ hardcode ไว้เช่นกัน

**เพิ่มเติม:** `.env:1` `JWT_SECRET=SecretKey555` — secret ที่เดาได้ง่ายมากและถูก commit ขึ้น git แถมยังใช้ secret เดียวกันทั้ง access token และ refresh token (`auth_controller.go:210-240`)

---

#### BUG-V3-047 · โค้ดตายและ import ที่ไม่ได้ใช้ 62 จุด

**ที่:** ดูรายละเอียดใน [ส่วนที่ 5](#5-ผลจาก-flutter-analyze)
**สรุป:** `dead_null_aware_expression` 14 จุด, `unnecessary_non_null_assertion` 14 จุด, `unused_element` 9 จุด, `unused_import` 8 จุด, `dead_code` 7 จุด, `unnecessary_null_comparison` 7 จุด

จุดที่น่าสนใจเป็นพิเศษ:
- `debt_ledger.dart:64` — ฟังก์ชัน `_buildPaginationControls` เขียนไว้แต่ไม่มีใครเรียก → หน้าสมุดหนี้ไม่มี pagination ทั้งที่โค้ดมีอยู่
- `add_stock.dart:661` — `_showSaveCheckDialog` ไม่ถูกเรียก → dialog ยืนยันก่อนบันทึกที่เขียนไว้ไม่ทำงาน
- `debt_sale.dart:232-235`, `debtor_detail.dart:38, 219-225, 481-487` — เช็ค null บนฟิลด์ที่ประกาศเป็น non-nullable แปลว่านักพัฒนา**คิดว่าค่านี้เป็น null ได้** ซึ่งขัดกับ type — ความเสี่ยงจริงย้ายไปอยู่ที่ขั้นตอน parse JSON แทน (ดู BUG-V3-039)

---

## 4. Test Case Matrix

**วิธีอ่านตาราง:**
`✅` = ผ่าน · `❌` = ไม่ผ่าน · `⚠️` = ผ่านแบบมีเงื่อนไข · `➖` = ไม่เกี่ยวข้องกับ baseline นั้น

คอลัมน์ `vs main` คือสถานะจริงตอนนี้ · คอลัมน์ `vs MU` คือสถานะถ้า merge `origin/feature/multi-unit` ฝั่ง backend แล้ว

---

### 4.1 AUTH — สมัครสมาชิกและเข้าสู่ระบบ (18 เคส)

| # | Test Case | ผลที่คาดหวัง | vs main | vs MU | Bug |
|---|---|---|---|---|---|
| TC-AUTH-01 | สมัครด้วยข้อมูลถูกต้องครบถ้วน | ได้ 200 + ส่ง OTP ไปอีเมล | ✅ | ✅ | |
| TC-AUTH-02 | สมัครด้วยอีเมลรูปแบบผิด (`abc`) | 400 | ✅ | ✅ | |
| TC-AUTH-03 | สมัครด้วยอีเมลที่ยืนยันแล้ว | 409 "ถูกใช้งานแล้ว" | ✅ | ✅ | |
| TC-AUTH-04 | สมัครด้วยเบอร์ที่ยืนยันแล้ว | 409 | ✅ | ✅ | |
| TC-AUTH-05 | **สมัครด้วยเบอร์ซ้ำกับบัญชีที่ยังไม่ยืนยัน** | ควรปฏิเสธ หรือแจ้งให้ยืนยันบัญชีเดิม | ❌ **ทับบัญชีเดิม** | ❌ | V3-005 |
| TC-AUTH-06 | สมัครด้วยรหัสผ่านภาษาไทย 30 ตัวอักษร (>72 bytes) | ควร 400 แจ้งว่ายาวเกิน | ❌ **บันทึกรหัสว่าง ล็อกอินไม่ได้ตลอดกาล** | ❌ | V3-040 |
| TC-AUTH-07 | กรอก OTP ถูกต้องภายใน 15 นาที | 200 ยืนยันสำเร็จ | ✅ | ✅ | |
| TC-AUTH-08 | กรอก OTP ผิด | 400 | ✅ | ✅ | |
| TC-AUTH-09 | กรอก OTP หลังหมดอายุ 15 นาที | 400 หมดอายุ | ✅ | ✅ | |
| TC-AUTH-10 | **เดา OTP รัวๆ 1000 ครั้ง** | ควรล็อกหลังผิด N ครั้ง | ❌ **ไม่มี rate limit** | ❌ | V3-004 |
| TC-AUTH-11 | กดขอ OTP ใหม่ก่อนครบ 60 วินาที | ปุ่มควร disable | ✅ (UI กันไว้) | ✅ | |
| TC-AUTH-12 | **ยิง `/api/auth/register` รัวๆ 100 ครั้ง** | ควรมี rate limit | ❌ **email bombing ได้** | ❌ | V3-004 |
| TC-AUTH-13 | **เปลี่ยนอีเมลบัญชีคนอื่นผ่าน `/change-email-verify`** | ควร 401 ไม่มีสิทธิ์ | ❌ **สำเร็จ → ยึดบัญชีได้** | ❌ | V3-002 |
| TC-AUTH-14 | ล็อกอินด้วยอีเมล + รหัสถูก | 200 ได้ token คู่ | ✅ | ✅ | |
| TC-AUTH-15 | ล็อกอินด้วยเบอร์โทร + รหัสถูก | 200 | ✅ | ✅ | |
| TC-AUTH-16 | **ล็อกอินด้วย username + รหัสถูก** | ควร 200 (เอกสารบอกว่ารองรับ) | ❌ **401** — `auth_controller.go:184` ค้นแค่ email/phone | ❌ | — |
| TC-AUTH-17 | ล็อกอินบัญชีที่ยังไม่ยืนยัน | 403 + เด้ง dialog ยืนยัน OTP | ⚠️ **ทำงานได้แต่เผยอีเมลจริง และผูกกับข้อความไทย** | ⚠️ | V3-033, V3-032 |
| TC-AUTH-18 | ล็อกอินด้วยรหัสผ่านผิด | 401 ข้อความกลาง | ✅ | ✅ | |

### 4.2 RESET PASSWORD — ลืมรหัสผ่าน (6 เคส)

| # | Test Case | ผลที่คาดหวัง | vs main | vs MU | Bug |
|---|---|---|---|---|---|
| TC-PWD-01 | ขอ OTP ด้วยอีเมลที่มีในระบบ | 200 ส่ง OTP | ✅ | ✅ | |
| TC-PWD-02 | ขอ OTP ด้วยอีเมลที่ไม่มี | 200 ข้อความกลาง (ไม่บอกว่าไม่มี) | ✅ | ✅ | |
| TC-PWD-03 | ยืนยัน OTP ถูกภายใน 10 นาที | 200 verified | ✅ | ✅ | |
| TC-PWD-04 | ยืนยัน OTP หลังหมดอายุ | 401 หมดอายุ | ✅ | ✅ | |
| TC-PWD-05 | **รีเซ็ตรหัสด้วย OTP ที่หมดอายุแล้ว** | ควร 401 | ❌ **เปลี่ยนรหัสสำเร็จ** | ❌ | V3-004 |
| TC-PWD-06 | **ยิง `/reset-password` ตรงๆ ไม่ผ่าน `/verify-otp`** | ควร 401 | ❌ **สำเร็จถ้ารู้ OTP** | ❌ | V3-004 |

### 4.3 SESSION — จัดการ token (8 เคส)

| # | Test Case | ผลที่คาดหวัง | vs main | vs MU | Bug |
|---|---|---|---|---|---|
| TC-SES-01 | ใช้แอปปกติ token เหลือ >60 วินาที | ไม่ refresh | ✅ | ✅ | |
| TC-SES-02 | token เหลือ <60 วินาที ยิง API | refresh อัตโนมัติก่อน แล้วยิงต่อ | ✅ | ✅ | |
| TC-SES-03 | **ไม่มี `token_expires_at` ใน prefs** | ควร refresh เชิงรุกอยู่ดี | ❌ **ข้ามการเช็ค รอ 401 อย่างเดียว** | ❌ | V3-037 |
| TC-SES-04 | เจอ 401 กลางคัน refresh สำเร็จ | ยิง request ซ้ำอัตโนมัติ | ❌ **แค่ 2 endpoint ที่ยิงซ้ำจริง ที่เหลือคืน null** | ❌ | V3-037 |
| TC-SES-05 | เจอ 401 และ refresh ล้มเหลว | เด้งออกหน้า login | ✅ | ✅ | |
| TC-SES-06 | **ใช้ refresh token เป็น access token** | ควร 401 | ❌ **ผ่านทุก endpoint** | ❌ | V3-003 |
| TC-SES-07 | **ออกจากระบบด้วยการหมดอายุ แล้วล็อกอินบัญชีใหม่** | prefs เก่าต้องหายหมด | ❌ **`pinCode`, `userId`, `shopAddress` ค้าง** | ❌ | V3-017 |
| TC-SES-08 | กดปุ่มออกจากระบบ | prefs หายหมด + revoke ฝั่ง server | ✅ | ✅ | |

### 4.4 SHOP — จัดการร้านค้า (7 เคส)

| # | Test Case | ผลที่คาดหวัง | vs main | vs MU | Bug |
|---|---|---|---|---|---|
| TC-SHOP-01 | สร้างร้านใหม่พร้อม PIN 6 หลัก | 200 บันทึกสำเร็จ | ✅ | ✅ | |
| TC-SHOP-02 | สร้างร้านด้วย PIN 5 หลัก | 400 (`binding:"len=6"`) | ✅ | ✅ | |
| TC-SHOP-03 | แก้ไขข้อมูลร้านตัวเอง | 200 | ✅ | ✅ | |
| TC-SHOP-04 | **แก้ไขร้านของคนอื่น (เปลี่ยน `shop_id` ใน URL)** | ควร 403 | ❌ **สำเร็จ** | ❌ | V3-008 |
| TC-SHOP-05 | ลบร้านตัวเอง | 200 | ✅ | ✅ | |
| TC-SHOP-06 | สลับร้าน แล้วเข้าหน้าสินค้า | เห็นสินค้าของร้านใหม่ | ✅ | ✅ | |
| TC-SHOP-07 | ยังไม่เลือกร้าน แล้วกดเพิ่มสินค้า | ควรแจ้ง "กรุณาเลือกร้าน" | ✅ (`add_product_controller.dart:161`) | ✅ | |

### 4.5 PRODUCT — จัดการสินค้าและหมวดหมู่ (16 เคส)

| # | Test Case | ผลที่คาดหวัง | vs main | vs MU | Bug |
|---|---|---|---|---|---|
| TC-PRD-01 | เพิ่มสินค้าครบทุกช่อง + รูป | 200 บันทึกสำเร็จ | ✅ | ✅ | |
| TC-PRD-02 | เพิ่มสินค้าไม่เลือกรูป | แจ้งเตือนก่อนยิง API | ✅ | ✅ | |
| TC-PRD-03 | เพิ่มสินค้าไม่กรอกชื่อ/หมวด/ราคา/หน่วย | แจ้งเตือนครบถ้วน | ✅ | ✅ | |
| TC-PRD-04 | **กรอก "abc" ในช่องจำนวน** | ควรแจ้งเตือนว่ากรอกตัวเลข | ❌ **ขึ้น `FormatException` ดิบ** | ❌ | V3-015 |
| TC-PRD-05 | เพิ่มสินค้าบาร์โค้ดซ้ำในร้านเดียวกัน | 400 "บาร์โค้ดซ้ำ" | ✅ | ✅ | |
| TC-PRD-06 | **เพิ่มสินค้า 2 ตัวพร้อมกันในร้านเดียวกัน** | `product_code` ต้องไม่ซ้ำ | ❌ **ซ้ำได้ (race condition)** | ❌ | V3-024 |
| TC-PRD-07 | **แก้บาร์โค้ดสินค้าให้ซ้ำกับสินค้าอื่น** | ควร 400 | ❌ **สำเร็จ → สแกนเจอผิดตัว** | ❌ | V3-021 |
| TC-PRD-08 | **แก้ราคาส่งเป็นสตริง `"50"`** | ควร 400 | ❌ **บันทึกประวัติราคาเป็น 0** | ❌ | V3-021 |
| TC-PRD-09 | ลบสินค้าที่ยังไม่เคยขาย | ลบออกจริง (`status: deleted`) | ✅ | ✅ | |
| TC-PRD-10 | ลบสินค้าที่เคยขายแล้ว | ซ่อนแทน (`status: hidden`) | ✅ | ✅ | |
| TC-PRD-11 | **ลบสินค้าของร้านอื่น** | ควร 403 | ❌ **สำเร็จ** | ❌ | V3-008 |
| TC-PRD-12 | สร้าง/แก้/ลบ/กู้คืนหมวดหมู่ | ทำงานครบทุกขั้น | ⚠️ **ทำงานได้ แต่ error ทุกแบบคืน 409** | ⚠️ | V3-041 |
| TC-PRD-13 | ย้ายสินค้าทั้งหมดไปหมวดอื่นก่อนลบหมวด | 200 | ✅ | ✅ | |
| TC-PRD-14 | **เปิดหน้าสินค้าด้วย `?limit=abc`** | ควร fallback เป็น 10 | ❌ **`total_pages` เป็นค่าขยะติดลบ** | ❌ | V3-018 |
| TC-PRD-15 | **ค้นหาด้วยคำว่า `50%`** | ควรหาสินค้าที่ชื่อมี "50%" | ❌ **คืนสินค้าทุกตัวที่มี "50"** | ❌ | V3-036 |
| TC-PRD-16 | **เรียงชื่อไทย ร้านที่มีสินค้า 10,000 ตัว** | ควรดึงแค่ 10 แถวต่อหน้า | ⚠️ **ดึง 10,000 แถวทุกครั้ง** | ⚠️ | V3-035 |

### 4.6 UNIT — หน่วยขายเพิ่มเติม (12 เคส) ⭐ ฟีเจอร์ใหม่รอบนี้

| # | Test Case | ผลที่คาดหวัง | vs main | vs MU | Bug |
|---|---|---|---|---|---|
| TC-UNIT-01 | เพิ่มหน่วย "ลัง" = 12 ขวด ตอนสร้างสินค้า | บันทึกทั้งสินค้าและหน่วย | ❌ **`units[]` หายเงียบ ไม่มี error** | ⚠️ ต้องเรียกทีละหน่วย | V3-001 |
| TC-UNIT-02 | เพิ่มหน่วยจากหน้าแก้ไขสินค้า | 200 | ❌ **404** | ✅ | V3-001 |
| TC-UNIT-03 | แก้ไขหน่วยที่มีอยู่ | 200 | ❌ **404** | ✅ | V3-001 |
| TC-UNIT-04 | ลบหน่วยที่ยังไม่เคยขาย | ลบจริง | ❌ **404** | ✅ `deleted` | V3-001 |
| TC-UNIT-05 | ลบหน่วยที่เคยขายแล้ว | ซ่อนแทน | ❌ **404** | ✅ `hidden` | V3-001 |
| TC-UNIT-06 | กรอก `conversion_qty = 1` | ปฏิเสธ ต้องมากกว่า 1 | ✅ (UI กันทั้ง 2 หน้า) | ✅ (API กันด้วย) | |
| TC-UNIT-07 | กรอก `conversion_qty = 0` | ปฏิเสธ | ✅ (UI) | ✅ (`binding:"gt=1"`) | |
| TC-UNIT-08 | **`conversion_qty = 0` เข้าไปใน DB ทางอื่น แล้วเปิดหน้ารายละเอียดสินค้า** | ไม่ควร crash | ❌ **`IntegerDivisionByZeroException`** | ❌ **เหมือนกัน** — migration ไม่มี CHECK | V3-011 |
| TC-UNIT-09 | **ตั้งชื่อหน่วยซ้ำกับหน่วยฐาน จากหน้าแก้ไข** | ควรแจ้งเตือนทันที | ❌ 404 | ⚠️ **ผ่าน UI แต่ API ปฏิเสธ** | V3-027 |
| TC-UNIT-10 | **ตั้งบาร์โค้ดหน่วยซ้ำกับสินค้าอื่น จากหน้าแก้ไข** | ควรแจ้งเตือนทันที | ❌ 404 | ⚠️ **ผ่าน UI แต่ API ปฏิเสธ** | V3-027 |
| TC-UNIT-11 | **เปิด/ปิดฟอร์มหน่วยขาย 20 ครั้ง** | ไม่ควรมี controller ค้าง | ❌ **100 controller ค้าง** | ❌ | V3-028 |
| TC-UNIT-12 | เพิ่มหน่วยให้สินค้าของร้านอื่น | ควร 403 | ➖ 404 | ❌ **สำเร็จ** — ไม่เช็ค shop | V3-008 |

### 4.7 STOCK — เติมสต็อกและแสดงผล (8 เคส)

| # | Test Case | ผลที่คาดหวัง | vs main | vs MU | Bug |
|---|---|---|---|---|---|
| TC-STK-01 | เติมสต็อก 50 ขวด (หน่วยฐาน) | สต็อก +50 | ✅ | ✅ | |
| TC-STK-02 | **เติมสต็อก 5 ลัง (1 ลัง = 12 ขวด)** | สต็อก +60 ขวด | ❌ **สต็อก +5 ขวด** | ✅ **+60** พร้อมคืน `added_base_amount` | V3-001 |
| TC-STK-03 | ดูตัวอย่างการแปลงหน่วยขณะกรอก ("5 ลัง = 60 ขวด") | แสดงถูกต้อง | ✅ (คำนวณฝั่ง client) | ✅ | |
| TC-STK-04 | **เติมสต็อก 0 (กดบันทึกโดยแก้แต่ราคา)** | ควรผ่าน | ❌ **400 "ข้อมูลไม่ถูกต้อง"** | ❌ | V3-031 |
| TC-STK-05 | **ส่ง `stock: -100`** | ควร 400 | ❌ **สต็อกลด 100** ผ่าน endpoint "เพิ่มสต็อก" | ❌ | V3-031 |
| TC-STK-06 | แสดงสต็อก 125 ขวด (มีหน่วยลัง=12) | "10 ลัง + 5 ขวด" | ⚠️ **แสดง "125 ขวด"** เพราะ `units` ว่างเสมอ | ✅ | V3-001 |
| TC-STK-07 | แก้ราคาหน่วยฐาน + ราคาหน่วยลัง พร้อมกัน | บันทึกทั้งคู่ | ⚠️ ราคาฐานผ่าน / ราคาลัง **404** | ✅ | V3-001 |
| TC-STK-08 | **เติมสต็อกสินค้าของร้านอื่น** | ควร 403 | ❌ **สำเร็จ** | ❌ | V3-008 |

### 4.8 SALE — ขายหน้าร้าน (20 เคส) ⭐ ส่วนสำคัญที่สุด

| # | Test Case | ผลที่คาดหวัง | vs main | vs MU | Bug |
|---|---|---|---|---|---|
| TC-SALE-01 | สแกนบาร์โค้ดสินค้า เพิ่มลงตะกร้า | เพิ่มเป็นหน่วยฐาน 1 ชิ้น | ✅ | ✅ | |
| TC-SALE-02 | **สแกนบาร์โค้ดที่แปะบนลัง (สินค้าอยู่ใน cache)** | เพิ่มเป็น 1 ลัง | ✅ (จับคู่ฝั่ง client) | ✅ | |
| TC-SALE-03 | **สแกนบาร์โค้ดลัง (สินค้าไม่อยู่ใน cache)** | เพิ่มเป็น 1 ลัง | ❌ **"ไม่พบสินค้า"** — API ไม่ค้น `product_units.barcode` | ✅ | V3-001 |
| TC-SALE-04 | สแกนบาร์โค้ดที่ไม่มีในระบบ | dialog "ไม่พบสินค้า" | ✅ | ✅ | |
| TC-SALE-05 | เพิ่มสินค้าเกินสต็อกที่มี | snackbar "ถึงจำนวนสูงสุดแล้ว" | ✅ (กันฝั่ง client) | ✅ (กันทั้ง 2 ฝั่ง) | |
| TC-SALE-06 | **ใส่ตะกร้า 2 ขวด + 1 ลัง สินค้าตัวเดียวกัน** | เพดานสต็อกนับรวมเป็นหน่วยฐาน (2 + 12 = 14) | ✅ `_addToCart:342` | ✅ | |
| TC-SALE-07 | พิมพ์จำนวนตรงๆ เกินสต็อก | clamp + แจ้งจำนวนสูงสุด | ✅ `setQuantity:427` | ✅ | |
| TC-SALE-08 | กด `-` จนเหลือ 0 | ลบรายการออกจากตะกร้า | ✅ | ✅ | |
| TC-SALE-09 | พักบิลแล้วเรียกคืน | ได้ตะกร้าเดิมกลับมาครบ | ✅ | ✅ | |
| TC-SALE-10 | **เรียกคืนบิลที่มี 2 บรรทัดของสินค้าเดียวกัน หลังสต็อกลดลง** | รวมทั้ง 2 บรรทัดต้องไม่เกินสต็อก | ❌ **clamp แยกบรรทัด รวมกันเกินได้** | ❌ | V3-025 |
| TC-SALE-11 | **เลือกสินค้าจากสมุดสินค้าไม่มีบาร์โค้ด** | ควรเลือกหน่วยขายได้ | ❌ **เข้าเป็นหน่วยฐานเสมอ ไม่มีตัวเลือก** | ❌ **เหมือนกัน** — ฝั่ง UI ไม่รองรับ | V3-013 |
| TC-SALE-12 | **สินค้าไม่มีบาร์โค้ดที่ backend ไม่ส่ง `stock`** | ควรใช้สต็อกจริง | ❌ **ได้ 999 ขายได้ไม่จำกัด** | ❌ | V3-012 |
| TC-SALE-13 | **ขาย 1 ลัง (12 ขวด) จากสต็อก 100** | สต็อกเหลือ 88 | ❌ **เหลือ 99** | ✅ **88** | V3-001 |
| TC-SALE-14 | **ขาย 10 ชิ้น จากสต็อกที่เหลือ 3** | ควร 400 สต็อกไม่พอ | ❌ **สำเร็จ สต็อกเหลือ -7** | ✅ 400 | V3-006 |
| TC-SALE-15 | **ยอดสุทธิ 99.50 บาท ดูกล่องยืนยัน** | แสดง "99.50 ฿" | ❌ **แสดง "99 ฿"** | ❌ | V3-029 |
| TC-SALE-16 | **ขาย 2 ลัง ดูจำนวนในกล่องยืนยัน** | ควรสื่อว่า 2 ลัง (24 ขวด) | ❌ **"2 ชิ้น"** | ❌ | V3-030 |
| TC-SALE-17 | **ขายสินค้าราคา 0 บาท (ของแถม)** | ควรบันทึกได้ | ❌ **400** — `binding:"required"` บนราคา | ❌ | V3-031 |
| TC-SALE-18 | จ่ายเงินสด รับเงินมากกว่ายอด | คำนวณเงินทอนถูกต้อง | ✅ | ✅ | |
| TC-SALE-19 | จ่ายเงินสด รับเงินน้อยกว่ายอด | ปฏิเสธ แจ้งเตือน | ✅ `checkout_controller.dart:586` | ✅ | |
| TC-SALE-20 | **commit ล้มเหลวขณะบันทึกบิล** | ควรแจ้ง error และเก็บตะกร้าไว้ | ❌ **แจ้งสำเร็จ + ล้างตะกร้า → บิลหาย** | ❌ | V3-020 |

### 4.9 DEBT — ลูกหนี้และการชำระหนี้ (14 เคส)

| # | Test Case | ผลที่คาดหวัง | vs main | vs MU | Bug |
|---|---|---|---|---|---|
| TC-DEBT-01 | ลงทะเบียนลูกหนี้ครบทุกช่อง | 200 | ✅ | ✅ | |
| TC-DEBT-02 | **ลงทะเบียนลูกหนี้ชื่อว่าง เบอร์ว่าง** | ควร 400 | ❌ **บันทึกสำเร็จ** | ❌ | V3-023 |
| TC-DEBT-03 | **ลงทะเบียนลูกหนี้พร้อม `current_debt: 50000`** | ควรเริ่มที่ 0 เสมอ | ❌ **บันทึกตามที่ส่งมา → รายงานเพี้ยน** | ❌ | V3-023 |
| TC-DEBT-04 | **ลงทะเบียนลูกหนี้ `credit_limit: -5000`** | ควร 400 | ❌ **สำเร็จ** | ❌ | V3-023 |
| TC-DEBT-05 | ลงทะเบียนเบอร์ซ้ำในร้านเดียวกัน | 409 (มี unique index) | ✅ | ✅ | |
| TC-DEBT-06 | ขายเชื่อภายในวงเงิน | 200 หนี้เพิ่มตามยอด | ✅ | ✅ | |
| TC-DEBT-07 | ขายเชื่อเกินวงเงิน | ปฏิเสธ แจ้งวงเงินคงเหลือ | ⚠️ **ปฏิเสธถูก แต่คืน 500 แทน 400** | ⚠️ | V3-041 |
| TC-DEBT-08 | **ขายเชื่อโดยส่ง `pay` = `net_price`** | หนี้ควรเพิ่ม | ❌ **หนี้ไม่เพิ่ม แต่สต็อกถูกตัด** | ❌ | V3-009 |
| TC-DEBT-09 | **ขายเชื่อโดยส่ง `amount: -5`** | ควร 400 | ❌ **สต็อกเพิ่ม 5 โดยไม่ต้องเติมของ** | ❌ | V3-009 |
| TC-DEBT-10 | **ขายเชื่อบิลเปล่า (`sale_items: []`)** | ควร 400 | ❌ **สร้างบิลได้ + เพิ่มหนี้** | ❌ | V3-009 |
| TC-DEBT-11 | ชำระหนี้ด้วย PIN ถูก | 200 หนี้ลดตามยอด | ✅ | ✅ | |
| TC-DEBT-12 | ชำระหนี้ด้วย PIN ผิด | 401 | ✅ | ✅ | |
| TC-DEBT-13 | **ชำระเกินยอดหนี้ (หนี้ 500 จ่าย 5000)** | ควร 400 หรือ clamp ที่ 0 | ❌ **หนี้กลายเป็น -4500** | ❌ | V3-007 |
| TC-DEBT-14 | **ส่ง `amount_paid: -1000`** | ควร 400 | ❌ **หนี้เพิ่ม 1000** ผ่าน endpoint ชำระหนี้ | ❌ | V3-007 |

### 4.10 REPORT — รายงานและแดชบอร์ด (10 เคส)

| # | Test Case | ผลที่คาดหวัง | vs main | vs MU | Bug |
|---|---|---|---|---|---|
| TC-RPT-01 | ดูยอดขายวันนี้บนหน้าหลัก | ตรงกับบิลที่ขายจริง | ✅ | ✅ | |
| TC-RPT-02 | **ดูจำนวนสินค้าที่ขายไป เมื่อขายเป็นลัง** | ควรนับเป็นหน่วยฐาน (1 ลัง = 12) | ❌ **นับเป็น 1** | ✅ `SUM(amount × conversion_qty)` | V3-001 |
| TC-RPT-03 | **ดูกำไรเมื่อขายเป็นลัง** | ต้นทุนต้องคูณ conversion | ❌ **ต้นทุนคิดแค่ 1 ขวด → กำไรเกินจริงมาก** | ✅ `COALESCE(pu.cost_price, conv × cost)` | V3-001 |
| TC-RPT-04 | ดูรายงานขั้นสูง เลือกช่วงวันที่ | แสดงข้อมูลตามช่วง | ✅ | ✅ | |
| TC-RPT-05 | **ส่งวันที่รูปแบบผิด (`date=abc`)** | ควร 400 | ⚠️ **200 แต่ข้อมูลว่าง** ไม่มี validation | ⚠️ | — |
| TC-RPT-06 | **query ล้มเหลว (ตารางหาย/DB ล่ม)** | ควร 500 | ❌ **200 พร้อมเลข 0 ทุกช่อง** | ❌ | V3-034 |
| TC-RPT-07 | ดู aging report แบ่งกลุ่มอายุหนี้ | safe ≤15 / warning 16-30 / danger >30 | ⚠️ นับ `DATEDIFF + 1` อ้างอิงวันนี้ | ⚠️ นับ `DATEDIFF` อ้างอิง `end_date` — **ผลต่างกัน 1 วัน** | ดู §6 |
| TC-RPT-08 | ดู aging detail ของแต่ละบิล | รายการบิลค้างชำระ | ✅ | ✅ (ความหมายเปลี่ยน) | ดู §6 |
| TC-RPT-09 | ร้านที่ไม่มีข้อมูลเลย | แสดง 0 ทุกช่อง ไม่ crash | ✅ | ✅ | |
| TC-RPT-10 | **ดูรายงานของร้านอื่น (เปลี่ยน `shop_id`)** | ควร 403 | ❌ **เห็นยอดขาย กำไร ต้นทุน ทั้งหมด** | ❌ | V3-008 |

### 4.11 ORDER — สั่งซื้อและ PDF (4 เคส)

| # | Test Case | ผลที่คาดหวัง | vs main | vs MU | Bug |
|---|---|---|---|---|---|
| TC-ORD-01 | เลือกสินค้าแล้ว export PDF | ได้ไฟล์ PDF | ✅ | ✅ | |
| TC-ORD-02 | **export PDF ด้วย body ว่าง** | ควร 400 | ⚠️ **PDF เปล่า** — `ExportRequest` ไม่มี binding tag | ⚠️ | — |
| TC-ORD-03 | **รายการสั่งซื้อสินค้าที่มีหน่วยลัง** | ควรสั่งเป็นลัง | ⚠️ `order_list_controller.dart:106` เลือกหน่วยใหญ่เป็นค่าเริ่มต้น แต่ `units` ว่างเสมอ | ✅ | V3-001 |
| TC-ORD-04 | PDF แสดงภาษาไทยถูกต้อง | ฟอนต์ไทยไม่แตก | ✅ | ✅ | |

### 4.12 PROFILE — โปรไฟล์ผู้ใช้ (5 เคส)

| # | Test Case | ผลที่คาดหวัง | vs main | vs MU | Bug |
|---|---|---|---|---|---|
| TC-PRF-01 | ดูโปรไฟล์ตัวเอง | แสดงข้อมูลถูกต้อง | ✅ | ✅ | |
| TC-PRF-02 | **เรียก `GET /api/profile` (ไม่มี slash ปิดท้าย)** | ควร 200 | ❌ **301 → Authorization หาย → 401** | ❌ | V3-038 |
| TC-PRF-03 | แก้ไขชื่อผู้ใช้ | 200 | ✅ | ✅ | |
| TC-PRF-04 | **ส่ง `{"username": 123}`** | ควร 400 | ❌ **panic → 500 body ว่าง** | ❌ | V3-022 |
| TC-PRF-05 | อัปโหลดรูปโปรไฟล์ | อัปขึ้น Cloudinary สำเร็จ | ⚠️ **สำเร็จ แต่ preset เป็น unsigned hardcode** | ⚠️ | V3-043 |

### 4.13 SECURITY — ความปลอดภัย (10 เคส)

| # | Test Case | ผลที่คาดหวัง | vs main | vs MU | Bug |
|---|---|---|---|---|---|
| TC-SEC-01 | ยิง API ที่ต้อง auth โดยไม่มี token | 401 | ✅ | ✅ | |
| TC-SEC-02 | ยิงด้วย token ที่ signature ผิด | 401 | ✅ | ✅ | |
| TC-SEC-03 | ยิงด้วย token `alg: none` | 401 | ✅ (middleware เช็ค HMAC) | ✅ | |
| TC-SEC-04 | **ยิง `/api/auth/refresh` ด้วย token `alg: none`** | ควร 401 | ❌ **`ParseWithClaims` ไม่เช็ค signing method** (`auth_controller.go:292-294`) | ❌ | V3-003 |
| TC-SEC-05 | **ใช้ refresh token เป็น access token** | 401 | ❌ **ผ่านทุก endpoint** | ❌ | V3-003 |
| TC-SEC-06 | **เข้าถึงข้อมูลร้านอื่นด้วยการเปลี่ยน `shop_id`** | 403 | ❌ **สำเร็จทุก endpoint** | ❌ | V3-008 |
| TC-SEC-07 | ลอง SQL injection ในช่องค้นหา (`' OR 1=1--`) | ไม่มีผล | ✅ ใช้ bound parameter ทุกจุด | ✅ | |
| TC-SEC-08 | **ตรวจว่า credential อยู่ใน git ไหม** | ไม่ควรมี | ❌ **DSN + JWT_SECRET + `.exe` 48MB อยู่ใน repo** | ❌ | V3-010, V3-046 |
| TC-SEC-09 | **ตรวจว่า traffic เข้ารหัสไหม** | HTTPS | ❌ **HTTP ทั้งหมดทั้ง 3 environment** | ❌ | V3-043 |
| TC-SEC-10 | **อ่าน token จากเครื่องที่ root** | ควรอ่านไม่ได้ | ❌ **อยู่ใน SharedPreferences XML ธรรมดา** | ❌ | V3-019 |

---

### สรุปผลการทดสอบ

| หมวด | เคสทั้งหมด | ✅ ผ่าน (vs main) | ⚠️ มีเงื่อนไข | ❌ ไม่ผ่าน | ➖ ไม่เกี่ยว |
|---|---|---|---|---|---|
| AUTH | 18 | 11 | 1 | 6 | 0 |
| RESET PASSWORD | 6 | 4 | 0 | 2 | 0 |
| SESSION | 8 | 4 | 0 | 4 | 0 |
| SHOP | 7 | 6 | 0 | 1 | 0 |
| PRODUCT | 16 | 7 | 2 | 7 | 0 |
| UNIT | 12 | 2 | 0 | 9 | 1 |
| STOCK | 8 | 2 | 2 | 4 | 0 |
| SALE | 20 | 10 | 0 | 10 | 0 |
| DEBT | 14 | 5 | 1 | 8 | 0 |
| REPORT | 10 | 4 | 2 | 4 | 0 |
| ORDER | 4 | 2 | 2 | 0 | 0 |
| PROFILE | 5 | 2 | 1 | 2 | 0 |
| SECURITY | 10 | 4 | 0 | 6 | 0 |
| **รวม** | **138** | **63 (46%)** | **11 (8%)** | **63 (46%)** | **1** |

**ถ้า merge backend `feature/multi-unit` แล้ว:** เคสที่ผ่านเพิ่มเป็น **76 เคส (55%)** — แก้เคสที่พลิกเป็นผ่านได้ 13 เคส (UNIT 4 · STOCK 3 · SALE 3 · REPORT 2 · ORDER 1) และเพิ่มการเช็คสต็อกในการขายเงินสด แต่**ไม่ได้แก้** ปัญหา IDOR, auth, validation, และบัคฝั่ง Flutter เลย — ยังเหลือไม่ผ่านอีกราว 50 เคส

---

## 5. ผลจาก flutter analyze

```
305 issues found. (ran in 94.3s)
```

| ระดับ | จำนวน |
|---|---|
| error | **0** |
| warning | 62 |
| info | 243 |

**ไม่มี compile error** — โค้ดคอมไพล์ผ่าน

### แยกตามประเภท

| กฎ | จำนวน | หมายเหตุ |
|---|---|---|
| `avoid_print` | 114 | ดู BUG-V3-042 |
| `deprecated_member_use` | 111 | ส่วนใหญ่คือ `withOpacity` → ควรเปลี่ยนเป็น `.withValues()` |
| `unnecessary_non_null_assertion` | 14 | ใช้ `!` บนค่าที่ไม่มีทางเป็น null |
| `dead_null_aware_expression` | 14 | ใช้ `??` บนค่าที่ไม่มีทางเป็น null |
| `unused_element` | 9 | โค้ดที่เขียนแล้วไม่มีใครเรียก |
| `curly_braces_in_flow_control_structures` | 9 | สไตล์ |
| `unused_import` | 8 | |
| `unnecessary_null_comparison` | 7 | |
| `dead_code` | 7 | |
| `use_build_context_synchronously` | 4 | **ควรดู** — ใช้ `BuildContext` ข้าม async gap |
| `use_super_parameters` | 3 | สไตล์ |
| `prefer_interpolation_to_compose_strings` | 2 | |
| `unused_field` / `unnecessary_cast` / `invalid_null_aware_operator` | 3 | |

### จุดที่ควรดูเป็นพิเศษ

**`use_build_context_synchronously` (4 จุด)** — ใช้ `BuildContext` หลัง `await` โดยไม่เช็ค `mounted` ถ้าผู้ใช้กดย้อนกลับระหว่างรอ API จะเกิด exception:
```
lib\page\product\add_product\add_product.dart:636:40
lib\page\product\add_product\add_product.dart:763:40
lib\page\product\edit_product\edit_product_screen.dart:503:40
lib\page\product\edit_product\edit_product_screen.dart:630:40
```

**โค้ดที่เขียนแล้วไม่ทำงาน:**
```
warning - The declaration '_buildPaginationControls' isn't referenced - lib\page\debt\debtLedger\debt_ledger.dart:64:10
warning - The declaration '_showSaveCheckDialog' isn't referenced - lib\page\product\add_stock\add_stock.dart:661:8
warning - The declaration '_MetricCol' isn't referenced - lib\page\my_blank\sales_account.dart:1588:7
```

**เช็ค null บนค่าที่ประกาศเป็น non-nullable** — บ่งบอกว่าคนเขียนคาดว่าค่านี้เป็น null ได้ แปลว่าความเสี่ยงจริงอยู่ที่ขั้น parse JSON แทน (ดู BUG-V3-039):
```
warning - The operand can't be 'null', so the condition is always 'true' - lib\page\debt\debtSale\debt_sale.dart:232:39
warning - The operand can't be 'null', so the condition is always 'true' - lib\page\debt\debtorDetail\debtor_detail.dart:38:39
warning - The operand can't be 'null', so the condition is always 'true' - lib\page\debt\debtorDetail\debtor_detail.dart:219:72
warning - The operand can't be 'null', so the condition is always 'true' - lib\page\debt\debtorDetail\debtor_detail.dart:481:45
```

**หมายเหตุ:** ไม่ได้รัน `go vet` / `go build` ฝั่ง backend ในรอบนี้

---

## 6. Regression Checklist หลัง merge

เมื่อ merge `origin/feature/multi-unit` เข้า `main` ฝั่ง backend ต้องทดสอบซ้ำตามนี้

### 6.1 ก่อน merge

- [ ] สำรองฐานข้อมูล production ก่อนรัน migration
- [ ] รัน `003_product_units.sql` แล้วยืนยันว่าตาราง `product_units` ถูกสร้าง พร้อม FK `ON DELETE CASCADE` และ unique key `(product_id, unit_name)`
- [ ] รัน `004_sale_items_unit_columns.sql` แล้วยืนยันว่า `sale_items` มีคอลัมน์ `product_unit_id`, `unit_name`, `conversion_qty DEFAULT 1`
- [ ] ยืนยันว่าแถว `sale_items` เดิมทั้งหมดได้ `conversion_qty = 1` (ไม่ใช่ 0 หรือ NULL) — ถ้าเป็น 0 รายงานทุกตัวจะกลายเป็นศูนย์
- [ ] เตรียม `rollback_003_*.sql` และ `rollback_004_*.sql` ไว้ให้พร้อมใช้

### 6.2 ⚠️ ความหมายของ aging report เปลี่ยน — ต้องตรวจเป็นพิเศษ

branch เปลี่ยนสองอย่างพร้อมกันใน `advanced_report_controller.go`

| | `main` (ตอนนี้) | `feature/multi-unit` |
|---|---|---|
| วันอ้างอิง | `asOfDate := time.Now()` (วันนี้เสมอ) | `end_date` ที่ผู้ใช้เลือก |
| การนับวัน | `DATEDIFF(?, created_at) + 1` | `DATEDIFF(?, created_at)` |

**ผลรวม:** บิลที่ค้างมา 15 วัน — บน `main` นับเป็น 16 วันเข้ากลุ่ม `warning` / บน branch นับเป็น 15 วันอยู่กลุ่ม `safe` **ยอดในแต่ละกลุ่มจะเปลี่ยนไปทั้งหมด**

- [ ] จับภาพ aging report ปัจจุบันไว้ก่อน merge เพื่อเทียบ
- [ ] ยืนยันกับเจ้าของธุรกิจว่าการนับแบบใหม่ (ไม่ +1) คือสิ่งที่ต้องการ
- [ ] ทดสอบเลือกช่วงวันที่ย้อนหลัง แล้วดูว่า aging สะท้อนสถานะ ณ วันนั้นจริง (พฤติกรรมใหม่)
- [ ] ทดสอบ `GET /api/dashboard/aging-report-detail` ให้ผลสอดคล้องกับ `advanced-report`

### 6.3 หลัง merge

- [ ] รัน TC-UNIT ทั้ง 12 เคสใหม่หมด
- [ ] รัน TC-STK-02, TC-STK-06, TC-STK-07
- [ ] รัน TC-SALE-03, TC-SALE-13, TC-SALE-14
- [ ] รัน TC-RPT-02, TC-RPT-03 — ยืนยันว่ากำไรที่คำนวณใหม่ตรงกับที่คิดมือ
- [ ] **regression ที่สำคัญที่สุด:** ขายสินค้าที่**ไม่มี**หน่วยขายเพิ่มเติม ต้องได้ผลเหมือนเดิมทุกประการ (`conv = 1`)
- [ ] ยืนยันว่าบิลเก่าก่อน migration ยังแสดงในรายงานถูกต้อง
- [ ] ทดสอบ `DELETE /api/products/:id` กับสินค้าที่มีหน่วยขาย → `product_units` ต้องถูกลบตาม CASCADE
- [ ] ทดสอบ `DELETE /api/products/units/:unitId` กับหน่วยที่เคยขายแล้ว → ต้องได้ `status: hidden` ไม่ใช่ลบจริง

### 6.4 บัคที่ merge แล้วก็ยังอยู่ — อย่าเข้าใจผิดว่าแก้แล้ว

การ merge multi-unit **ไม่ได้แก้** บัคเหล่านี้เลย:

BUG-V3-002 (ยึดบัญชี) · V3-003 (token type) · V3-004 (OTP หมดอายุ) · V3-005 (ทับบัญชี) · V3-007 (ชำระหนี้) · V3-008 (IDOR — **ยังลามไปที่ endpoint หน่วยขายใหม่อีก 3 ตัวด้วย**) · V3-009 (ขายเชื่อ) · V3-010 (credential) · V3-011 ถึง V3-047 ฝั่ง Flutter ทั้งหมด

---

## 7. ลำดับความสำคัญในการแก้

### 🔴 ต้องแก้ก่อน Release — ห้ามข้าม

| ลำดับ | บัค | ทำไมต้องก่อน | ประเมินขนาดงาน |
|---|---|---|---|
| 1 | **V3-002** ยึดบัญชีผ่าน change-email | ใครก็ยึดบัญชีลูกค้าได้ตอนนี้ | เล็ก — เพิ่มการยืนยันรหัสผ่านหรือ OTP เดิม |
| 2 | **V3-001** merge backend multi-unit | ฟีเจอร์ที่ ship ไปแล้วทำสต็อกเพี้ยนทุกบิล | เล็ก — โค้ดเสร็จแล้ว merge + รัน migration |
| 3 | **V3-003** token type ไม่ถูกเช็ค | refresh token 7 วันกลายเป็นกุญแจถาวร | เล็ก — เพิ่ม 3 บรรทัดใน middleware |
| 4 | **V3-006** ขายเงินสดไม่เช็คสต็อก | สต็อกติดลบสะสม | เล็ก — มาพร้อม merge ข้อ 2 |
| 5 | **V3-007** ชำระหนี้ 3 ปัญหา | เงินกับหนี้ไม่ตรง แก้ย้อนหลังยาก | เล็ก |
| 6 | **V3-009** ขายเชื่อ 4 ปัญหา | สต็อกและหนี้เพี้ยนได้หลายทาง | กลาง — ต้องเพิ่ม binding tag + validation |
| 7 | **V3-004** OTP หมดอายุยังใช้ได้ | ยึดบัญชีผ่านการรีเซ็ตรหัส | เล็ก — เพิ่มเช็ค `ExpiresAt` |
| 8 | **V3-005** สมัครทับบัญชีเดิม | ผู้ใช้เสียบัญชีโดยไม่รู้ตัว | เล็ก |
| 9 | **V3-010** credential ใน git | ต้อง rotate รหัสฐานข้อมูลและ JWT secret ทันที | เล็ก แต่ต้องประสานงาน |
| 10 | **V3-008** IDOR ทั้งระบบ | ข้อมูลร้านอื่นเข้าถึงได้หมด | **ใหญ่** — ต้องแก้ทุก controller ให้ใช้ `GetShopIDFromAuth` |

### 🟠 แก้ใน Sprint ถัดไป

**ฝั่ง Flutter**
V3-011 (หารด้วยศูนย์) · V3-012 (สต็อก 999) · V3-013 (สมุดไม่รองรับหน่วย) · V3-014 (`int.parse` ตอนขาย) · V3-015 (`int.parse` ตอนเพิ่มสินค้า) · V3-016 (`jsonDecode` ก่อนเช็ค status) · V3-017 (logout ไม่หมด) · V3-025 (เรียกคืนบิล) · V3-029 (ยอดเงินตัดทศนิยม) · V3-030 (นับจำนวนผิด) · V3-032 (ผูกกับข้อความไทย) · V3-039 (parse JSON ไม่ปลอดภัย)

**ฝั่ง Backend**
V3-018 (`limit` ไม่ใช่ตัวเลข) · V3-020 (`tx.Commit` ไม่เช็ค) · V3-021 (แก้สินค้า) · V3-022 (panic โปรไฟล์) · V3-023 (validation ลูกหนี้) · V3-024 (รหัสสินค้าซ้ำ) · V3-026 (ค้นหาคืนตัวเดียว) · V3-031 (`binding:"required"` บนตัวเลข) · V3-033 (เผยอีเมล) · V3-034 (dashboard คืน 0) · V3-041 (status code)

### 🟡 แก้เมื่อมีเวลา

V3-019 (secure storage) · V3-027 (validation หน่วยขายหน้าแก้ไข) · V3-028 (memory leak) · V3-035 (เรียงไทยดึงทั้งร้าน) · V3-036 (LIKE wildcard) · V3-037 (proactive refresh) · V3-038 (trailing slash) · V3-040 (bcrypt error) · V3-043 (hardcode config)

### 🔵 หนี้ทางเทคนิค

V3-042 (`print`) · V3-044 (swagger) · V3-045 (ไม่มี test) · V3-046 (env ไม่ใช้) · V3-047 (dead code) · `withOpacity` 111 จุด

### ข้อเสนอแนะเชิงกระบวนการ

1. **ตั้ง unique index ในฐานข้อมูล** สำหรับ `products(shop_id, product_code)` และ `products(shop_id, barcode)` — จะแก้ race condition (V3-024) ได้ที่ต้นเหตุโดยไม่ต้องพึ่ง lock ในโค้ด
2. **สร้าง helper กลางสำหรับเรียก API ฝั่ง Flutter** ที่จัดการ auth header, การเช็ค status ก่อน decode, การ retry หลัง refresh, และรูปแบบ error ให้เหมือนกันทุกจุด — จะแก้ V3-016 และ V3-037 พร้อมกัน และตัดโค้ดซ้ำ ~40 จุด
3. **เขียน test ครอบเส้นทางเงินก่อน** — `CreateSale`, `CreateCreditSale`, `PaymentDebt` เป็นสามจุดที่บัคทำให้ข้อมูลผิดถาวรและแก้ย้อนหลังยากที่สุด ตอนนี้ไม่มี test คุ้มเลยแม้แต่บรรทัดเดียว
4. **ทำ `.env` ให้ใช้งานจริง** — ย้าย DSN, JWT secret, Google Apps Script URL, Cloudinary preset ออกจากโค้ด และเพิ่ม `--dart-define` ฝั่ง Flutter สำหรับ base URL

---

*รายงานนี้จัดทำจากการอ่านโค้ดและ `flutter analyze` เท่านั้น ไม่ได้รันแอปบนอุปกรณ์จริงหรือยิง API จริง ทุกบัคที่ระบุมีการอ้างอิงไฟล์และบรรทัดที่ตรวจสอบแล้ว บัคที่สงสัยแต่ยืนยันจากโค้ดไม่ได้ถูกตัดออกจากรายงาน*
