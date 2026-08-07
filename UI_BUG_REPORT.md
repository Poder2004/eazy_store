# EazyStore — UI/Logic Bug Report

ตรวจสอบวันที่: 2026-08-07
ขอบเขต: ไล่อ่านทุกไฟล์หน้าจอ (page) และ controller ใน `lib/page/**` ทั้งหมด แบ่งเป็น 4 กลุ่ม (auth/โปรไฟล์/ร้านค้า, จัดการสินค้า, ขายสินค้า/สแกน, หนี้/ใบสั่งซื้อ/รายงาน) — เป็นการรีวิวโค้ดแบบอ่านเท่านั้น ยังไม่ได้แก้อะไร

สัญลักษณ์ความรุนแรง: 🔴 สูง (เงิน/ข้อมูลผิด หรือแอปแครช) · 🟠 กลาง (พฤติกรรมผิดที่ผู้ใช้เจอได้บ่อย) · 🟡 ต่ำ (edge case / คุณภาพโค้ด)

---

## ⭐ Top ควรแก้ก่อน (กระทบเงิน/ทำให้แครช) — ✅ แก้ครบ 6 ข้อแล้ว (2026-08-07)

1. ✅ 🔴 **ยอดชำระที่แสดงบนจอตัดทศนิยมทิ้ง แต่ตอนเช็คยอดเงินใช้ค่าเต็ม** — [checkout_page.dart:337,581,654,822,933](lib/page/sale_producct/sale/checkout_page.dart) แสดง `totalPrice.toInt()` (ปัดทิ้งเศษ) แต่ `confirmPayment` ที่ [checkout_controller.dart:526](lib/page/sale_producct/sale/checkout_controller.dart#L526) เทียบด้วยค่าทศนิยมเต็ม → แคชเชียร์จ่ายตามตัวเลขที่เห็นบนจอพอดีแล้วโดนฟ้อง "ยอดเงินไม่พอ" ถ้าสินค้ามีราคามีเศษสตางค์
   **แก้แล้ว:** เพิ่ม `totalPriceRounded` getter ใช้แสดงผล+เช็คยอดเงิน+คำนวณเงินทอนแบบเดียวกันทั้งหมด ([checkout_controller.dart](lib/page/sale_producct/sale/checkout_controller.dart))
2. ✅ 🔴 **ยอดที่ส่งไป backend อาจไม่ตรงกับยอดที่โชว์บนจอ** — [checkout_controller.dart:758-777](lib/page/sale_producct/sale/checkout_controller.dart#L758-L777) ตอนกลุ่มสินค้าเดียวกันหลายชิ้นเข้าด้วยกันเพื่อยิง API ใช้ราคาของชิ้นสุดท้ายคูณจำนวน แทนที่จะรวมราคาจริงของแต่ละชิ้น ถ้าราคาสินค้าเปลี่ยนกลางทางที่ตะกร้ายังมีของเก่าอยู่ ยอดที่ตัดเงินจริงจะเพี้ยนจากยอดที่แคชเชียร์เห็น
   **แก้แล้ว:** เปลี่ยนเป็นรวมราคาจริงของทุกชิ้น (`existingItem.totalPrice + item.price`) แทนการคูณราคาชิ้นล่าสุด
3. ✅ 🔴 **บันทึกค้างชำระซ้ำได้ถ้ากดยืนยันเร็วๆ สองที** — [debt_sale_controller.dart](lib/page/debt/debtSale/debt_sale_controller.dart) ปุ่ม "ยืนยัน" ในไดอะล็อกสรุปยอดค้างชำระไม่มี flag กันกดซ้ำ (ต่างจากหน้า debtPayment ที่มี `isSubmitting`) → ดับเบิลแท็บเร็วๆ อาจยิง POST สร้างรายการค้างชำระซ้ำสองครั้ง
   **แก้แล้ว:** เพิ่ม `isSubmitting` guard พร้อม `finally` reset ให้ `submitDebt()`
4. ✅ 🔴 **เพิ่มจำนวนสินค้าในตะกร้าเกินสต็อกจริงได้** — [checkout_controller.dart:343-410](lib/page/sale_producct/sale/checkout_controller.dart#L343-L410) เช็คสต็อกเทียบกับ snapshot ตอนหยิบใส่ตะกร้าครั้งแรก ไม่ refresh ตามสต็อกปัจจุบัน ถ้าของหมดระหว่างขาย ระบบยังให้เพิ่มจำนวนต่อได้
   **แก้แล้ว:** เพิ่ม `_currentMaxStock()` ดึงสต็อกสดจาก `allProducts` มาใช้เช็คใน `increaseItem`/`setItemQuantity` แทนค่า snapshot เดิม
5. ✅ 🔴 **เปิดหน้ารายละเอียด/แก้ไขสินค้าโดยไม่มีข้อมูลส่งมาแล้วแอปแครช** — [edit_product_controller.dart:44-70](lib/page/product/edit_product/edit_product_controller.dart#L44-L70) และ [product_detail_controller.dart:17-25](lib/page/product/product_detail/product_detail_controller.dart#L17-L25) ใช้ `late` field ที่ยังไม่ถูก assign ก่อน build ครั้งแรกอ่านค่า → `LateInitializationError` ทำแอปเด้งแทนที่จะเด้งกลับหน้าเดิมแบบสุภาพ
   **แก้แล้ว:** ตั้งค่า default ที่ปลอดภัยให้ `late` field ทั้งสองไฟล์ก่อน schedule `Get.back()` กันแครชระหว่างรอเด้งกลับ
6. ✅ 🔴 **สแกนบาร์โค้ดค้าง (กล้องไม่ทำงาน) หลังกลับจากหน้ารายการสินค้าแบบไม่มีบาร์โค้ด** — [scan_barcode_controller.dart:190-194](lib/page/sale_producct/scanBarcode/scan_barcode_controller.dart#L190-L194) หยุดกล้องก่อนเปิดหน้ารายการ แต่ไม่มี logic สั่งเปิดกล้องใหม่ตอนกลับมาหน้าสแกน ทำให้จอสแกนค้างดำ ต้องออกแล้วเข้าใหม่เท่านั้น
   **แก้แล้ว:** `goToListPage()` รอผลของ `Get.to()` แล้วสั่ง `cameraController.start()` ใหม่ตอนกลับมาหน้าสแกน (ถ้ายังมีสิทธิ์กล้อง)

---

## หมวด 1: Auth / โปรไฟล์ / ร้านค้า

**สถานะ: ✅ แก้ครบทั้ง 21 ข้อแล้ว (2026-08-07)**

| ไฟล์ | จุด | ปัญหา | ผลกระทบ | แก้แล้ว |
|---|---|---|---|---|
| 🟠 [login.dart:208](lib/page/auth/login.dart#L208) | `Get.put(LoginController())` ใน `build()` | controller ไม่ถูกลบเมื่อออกจากหน้า | กลับมาหน้า login รอบสองอาจเจอ email/password เก่าค้างอยู่ในช่อง | ✅ ย้ายไป `initState`/`dispose` (แปลงเป็น StatefulWidget) |
| 🟠 [register.dart:31-54](lib/page/auth/register.dart#L31-L54) | ไม่เช็ครูปแบบอีเมล (`GetUtils.isEmail`) ก่อนยิง API | อีเมลผิดรูปแบบหลุดผ่าน validation ฝั่ง client ไปโผล่เป็น error จาก backend แทน | ✅ เพิ่มเช็ค `GetUtils.isEmail` |
| 🟡 [forgot_password.dart:87-90](lib/page/auth/forgot_password.dart#L87-L90) | `setState` หลัง `await` ไม่เช็ค `mounted` | กดย้อนกลับระหว่างรอ API อาจ error "setState after dispose" | ✅ เพิ่ม `if (!mounted) return;` |
| 🟡 [forgot_password.dart:77-85](lib/page/auth/forgot_password.dart#L77-L85) | เช็คแค่ email ไม่ว่าง ไม่เช็ครูปแบบ | เหมือนข้อข้างบน | ✅ เพิ่มเช็ค `GetUtils.isEmail` |
| 🟠 [reset_password.dart:35-52](lib/page/auth/reset_password.dart#L35-L52) | รหัสผ่านใหม่เช็คแค่ไม่ว่าง+ตรงกัน (ไม่บังคับ ≥6 ตัวเหมือนตอนสมัคร) | ตั้งรหัสผ่าน 1 ตัวอักษรได้ กฎความปลอดภัยไม่สอดคล้องกับหน้าสมัคร | ✅ เพิ่มเช็คความยาว ≥6 |
| 🟡 [reset_password.dart:54-61](lib/page/auth/reset_password.dart#L54-L61) | `setState` หลัง `await` ไม่เช็ค `mounted` | เหมือนข้อข้างบน | ✅ เพิ่ม `if (!mounted) return;` |
| 🟡 [verify_otp_page.dart:64-123](lib/page/auth/verify_otp_page.dart#L64-L123) | `setState` หลัง `await` ไม่เช็ค `mounted` (ทั้ง resend และ verify) | เสี่ยง error ถ้าออกจากหน้าระหว่างรอ API | ✅ เพิ่ม `if (!mounted) return;` ทั้งสองจุด |
| 🟡 [verify_register.dart:169](lib/page/auth/verify_register.dart#L169) | สร้าง `TextEditingController` ใหม่ทุกครั้งที่เปิดไดอะล็อกแก้อีเมล ไม่ dispose | memory leak เล็กน้อยถ้ากดแก้อีเมลหลายรอบ | ✅ `.whenComplete(() => controller.dispose())` |
| 🟡 [verify_register.dart:229-241](lib/page/auth/verify_register.dart#L229-L241) | แก้อีเมลเช็คแค่ไม่ว่าง ไม่เช็ครูปแบบ | พิมพ์อะไรก็ได้เป็นอีเมลปลายทาง OTP | ✅ เพิ่มเช็ค `GetUtils.isEmail` |
| 🟠 [edit_profile_controller.dart:39-45](lib/page/edit_profile/edit_profile_controller.dart#L39-L45) | `Get.put` ใน `StatelessWidget.build()`, โหลดข้อมูลแค่ครั้งเดียวใน `onInit` | เปิดหน้าแก้ไขโปรไฟล์รอบสองในเซสชันเดียวกันอาจเห็นข้อมูลเก่าค้าง รวมถึงรหัสผ่านที่เคยพิมพ์ไว้ | ✅ แปลงหน้าเป็น StatefulWidget + `Get.put`/`Get.delete` ผูกกับ `initState`/`dispose` |
| 🟡 [edit_profile_controller.dart:140-160](lib/page/edit_profile/edit_profile_controller.dart#L140-L160) | ไม่เช็ครูปแบบอีเมล/เบอร์โทร | validation หลวมกว่าหน้าสมัครสมาชิก | ✅ เพิ่มเช็คอีเมล+เบอร์โทร 10 หลัก |
| 🟠 [profile_controller.dart:106-114](lib/page/profile/profile_controller.dart#L106-L114) | `_getInitials` ตัดชื่อด้วย space แล้ว index `[0]` ตรงๆ | ชื่อที่มีเว้นวรรคติดกัน 2 ครั้ง (เช่น "John  Doe") ทำแอป crash ด้วย `RangeError` | ✅ ใช้ `RegExp(r'\s+')` + กรองค่าว่างก่อน index |
| 🟡 [profile_page.dart:13-15](lib/page/profile/profile_page.dart#L13-L15) | เรียก `loadProfileData()` ใน `addPostFrameCallback` ทุกครั้งที่ build ใหม่ (จอสั่นจาก keyboard/rotation ก็ทริกเกอร์) | ยิง API โหลดโปรไฟล์ซ้ำโดยไม่จำเป็น | ✅ ลบออก (`onInit` ของ controller โหลดให้อยู่แล้ว) |
| 🟡 [create_shop_controller.dart:167](lib/page/shop/createShop/create_shop_controller.dart#L167) | เช็คชื่อร้านว่างแบบไม่ `.trim()` | ตั้งชื่อร้านเป็นช่องว่างล้วนได้ | ✅ เพิ่ม `.trim()` |
| 🟠 [create_shop_controller.dart:426-433](lib/page/shop/createShop/create_shop_controller.dart#L426-L433) | หา shop ที่สร้างใหม่โดย match จากชื่อร้าน | ถ้ามีร้านชื่อซ้ำกัน อาจได้ `shopId` ผิดร้านมาเก็บเป็นร้านปัจจุบัน | ✅ ลบ logic match-by-name ทิ้ง ใช้ `shopId` ที่ `ApiShop().createShop()` เซฟจาก response ให้เองอยู่แล้ว |
| 🟠 [edit_shop_controller.dart:100-189](lib/page/shop/editShop/edit_shop_controller.dart#L100-L189) | ไม่เช็คความยาว PIN ให้ครบ 6 หลักตอนบันทึก และไม่มีให้พิมพ์ยืนยัน PIN ซ้ำ (ต่างจากตอนสร้างร้าน) | แก้ไข PIN ให้สั้นกว่า 6 หลักได้ หรือพิมพ์ผิดแล้วไม่รู้ตัว | ✅ เพิ่มเช็ค PIN ต้องเป็นตัวเลข 6 หลักก่อนบันทึก |
| 🟠 [myshop_controller.dart:34-42](lib/page/shop/myShop/myshop_controller.dart#L34-L42) | `fetchShops()` ไม่มี `catch` (มีแต่ `finally`) | error เครือข่ายกลายเป็นจอ "ยังไม่มีร้านค้า" เงียบๆ โดยไม่บอกว่าจริงๆ คือโหลดพัง | ✅ เพิ่ม `catch` พร้อม snackbar แจ้ง error |
| 🟡 [myshop_controller.dart:66-77](lib/page/shop/myShop/myshop_controller.dart#L66-L77) | ลบร้านค้าเดียวใช้ flag `isLoading` ตัวเดียวกับโหลดทั้งลิสต์ | ลบ 1 แถวแต่จอเด้งเป็น spinner เต็มจอ | ✅ เปลี่ยนไปใช้ loading dialog แยกต่างหาก |
| 🟡 [splash_screen.dart](lib/page/checkToken/splash_screen.dart) | `AnimationController` ไม่มี `dispose()` เลย | animation ticker leak | ✅ เพิ่ม `dispose()` |
| 🟡 [home_controller.dart:67-69](lib/page/homepage/home_controller.dart#L67-L69) | `currentIndex.obs` ไม่มีใครฟังจริง (ไม่มี Obx ใช้งาน) | เรียก `changeTab(2)` หลังสแกนบาร์โค้ดแล้วไม่มีผลอะไรกับ UI (dead state) | ✅ ลบ field/method ที่ตายแล้วออก (CheckoutPage ใช้ `currentNavIndex` ของตัวเองอยู่แล้ว ซึ่งถูกต้องอยู่แล้ว) |
| 🟠 [bottom_navbar.dart:161-190](lib/page/menu_bar/bottom_navbar.dart#L161-L190) | สลับแท็บใช้ `Get.to()` (push) ทุกครั้งแทนที่จะ replace | สลับแท็บไปมาหลายรอบ stack หน้าโป่งไม่จำกัด กดย้อนกลับต้องกดหลายที และ controller ซ้ำซ้อนสะสมในหน่วยความจำ | ✅ เปลี่ยนเป็น `Get.off()` ทั้ง 4 แท็บ |

---

## หมวด 2: จัดการสินค้า

**สถานะ: ✅ แก้ครบทั้ง 10 ข้อแล้ว (2026-08-07)**

| ไฟล์ | จุด | ปัญหา | ผลกระทบ | แก้แล้ว |
|---|---|---|---|---|
| 🔴 [edit_product_controller.dart:44-70](lib/page/product/edit_product/edit_product_controller.dart#L44-L70) | `late originalProduct` ยังไม่ assign ตอน build ครั้งแรก | เปิดหน้าแก้ไขสินค้าโดยไม่มี arguments ส่งมา → แอป crash แทนที่จะเด้งกลับ | ✅ แก้ไปแล้วในรอบก่อนหน้า (ตั้งค่า default ปลอดภัย) |
| 🔴 [product_detail_controller.dart:17-25](lib/page/product/product_detail/product_detail_controller.dart#L17-L25) | เหมือนข้อข้างบน | เปิดหน้ารายละเอียดสินค้าแบบไม่มี arguments → crash | ✅ แก้ไปแล้วในรอบก่อนหน้า |
| 🟠 [edit_product_screen.dart:332-335](lib/page/product/edit_product/edit_product_screen.dart#L332-L335), [add_product.dart:396-399](lib/page/product/add_product/add_product.dart#L396-L399) | callback หลังปิดใช้งานหมวดหมู่ reset `selectedCategory` แบบไม่มีเงื่อนไข | ปิดใช้งานหมวดหมู่ที่ *ไม่เกี่ยวกับ* ฟอร์มที่กำลังกรอกอยู่ ก็ทำให้หมวดหมู่ที่เลือกไว้ในฟอร์มหลุดออกไปด้วย | ✅ เช็คก่อนว่าหมวดหมู่ที่ปิดตรงกับที่เลือกในฟอร์มไหม ค่อยรีเซ็ต |
| 🟠 [add_stock_controller.dart:301-302](lib/page/product/add_stock/add_stock_controller.dart#L301-L302) + [add_stock.dart:52,244-254](lib/page/product/add_stock/add_stock.dart#L244-L254) | บันทึกราคาอย่างเดียวแล้วอัปเดตแค่ `TextEditingController.text` ไม่ได้ reassign `foundProduct.value` ที่ `Obx` ผูกไว้ | บันทึกราคาสำเร็จแล้ว แต่ตัวเลขราคาบนการ์ดยังโชว์ค่าเก่า จนกว่าจะค้นหาใหม่ | ✅ เพิ่ม `foundProduct.refresh()` บังคับ Obx รีบิลด์หลังบันทึกราคา |
| 🟡 [add_stock.dart:267-289](lib/page/product/add_stock/add_stock.dart#L267-L289) | รูปสินค้าโหลดพัง ใช้ `onError: (e,s) {}` ว่างเปล่า | โหลดรูปไม่ได้กลายเป็นกล่องขาวเปล่า ไม่มี fallback icon เหมือนจุดอื่นในแอป | ✅ เปลี่ยนเป็น `Image.network` + `errorBuilder` ให้ตรงกับจุดอื่นในแอป |
| 🟡 [add_stock.dart:601-700](lib/page/product/add_stock/add_stock.dart#L601-L700) | มี flow บันทึกสำรอง (`_showSaveCheckDialog`/`executeSave`) ที่ไม่ได้ใช้จริงแล้ว (ปุ่มจริงเรียก `_showConfirmDialog`/`saveAll`) | โค้ดซ้ำซ้อนที่ตกยุค ไม่จัดการ "ราคาที่เปลี่ยน" เหมือน flow จริง เสี่ยงมีคนเผลอเรียกใช้ในอนาคต | ✅ ลบ `_showSaveCheckDialog`/`executeSave`/`_buildConfirmRow` ที่ตายแล้วออกทั้งหมด |
| 🟡 [add_product_controller.dart:75-83](lib/page/product/add_product/add_product_controller.dart#L75-L83) | `pickImage` ไม่มี `try/catch` (ต่างจาก edit_product ที่มี) | เลือกรูปพังแบบเงียบๆ ไม่มี error แจ้งผู้ใช้ | ✅ เพิ่ม `try/catch` + snackbar แจ้ง error |
| 🟡 [add_product_controller.dart:95-107](lib/page/product/add_product/add_product_controller.dart#L95-L107) | ราคาทุน/ราคาขายเช็คแค่ไม่ว่าง ไม่เช็ค `> 0` | บันทึกสินค้าราคา 0 ได้โดยไม่มีคำเตือน | ✅ เพิ่มเช็คราคาต้อง `> 0` |
| 🟠 [check_stock_controller.dart:79](lib/page/product/checkStock/check_stock_controller.dart#L79) | `fetchStockData()` hardcode `search: ""` เสมอ | เปลี่ยนหน้า/ตัวกรอง/เรียงลำดับระหว่างมีคำค้นหาอยู่ → คำค้นหาหายไปเงียบๆ ทั้งที่ช่องค้นหายังโชว์ข้อความอยู่ | ✅ เปลี่ยนเป็น `searchCtrl.text.trim()` |
| 🟡 [check_price_controller.dart:79](lib/page/product/check_price/check_price_controller.dart#L79) | เรียงผลลัพธ์ด้วย `compareTo` ธรรมดา ไม่ใช้ `thaiSortKey` เหมือนหน้าอื่น | เรียงชื่อสินค้าภาษาไทยผิดลำดับเมื่อเทียบกับหน้าอื่นๆ ในแอป | ✅ เปลี่ยนไปใช้ `thaiSortKey` |

---

## หมวด 3: ขายสินค้า / สแกนบาร์โค้ด (จุดเสี่ยงเรื่องเงินสูงสุด)

**สถานะ: ✅ แก้ครบทั้ง 10 ข้อแล้ว (2026-08-07)**

| ไฟล์ | จุด | ปัญหา | ผลกระทบ | แก้แล้ว |
|---|---|---|---|---|
| 🔴 [checkout_page.dart](lib/page/sale_producct/sale/checkout_page.dart) / [checkout_controller.dart:526](lib/page/sale_producct/sale/checkout_controller.dart#L526) | ยอดที่โชว์ปัดทศนิยมทิ้ง แต่เช็คด้วยค่าเต็ม | ดูรายละเอียดในหัวข้อ Top ด้านบน | ✅ แก้ไปแล้วในรอบก่อนหน้า |
| 🔴 [checkout_controller.dart:758-777](lib/page/sale_producct/sale/checkout_controller.dart#L758-L777) | คำนวณยอดต่อรายการตอนยิง API ผิดถ้าราคาสินค้าเดียวกันเปลี่ยนกลางทาง | ยอดที่ตัดเงินจริงกับยอดที่แคชเชียร์เห็นไม่ตรงกัน | ✅ แก้ไปแล้วในรอบก่อนหน้า |
| 🔴 [checkout_controller.dart:343-410](lib/page/sale_producct/sale/checkout_controller.dart#L343-L410) | เพิ่มจำนวนสินค้าเทียบกับสต็อก snapshot เก่า ไม่ refresh | ขายเกินสต็อกจริงได้ | ✅ แก้ไปแล้วในรอบก่อนหน้า |
| 🟠 [checkout_controller.dart:201-241](lib/page/sale_producct/sale/checkout_controller.dart#L201-L241) + [checkout_page.dart:107-119](lib/page/sale_producct/sale/checkout_page.dart#L107-L119) | `isSearching` ไม่ถูกเซ็ตกลับ `false` เมื่อค้นหาแล้วไม่เจอผลลัพธ์ | ค้นหาสินค้า/บาร์โค้ดที่ไม่มีในระบบ → จอค้างเป็น spinner ตลอดกาล ไม่มีทางรู้ว่าค้นหาจบแล้ว | ✅ ครอบทั้งฟังก์ชันด้วย `try/finally` ให้ `isSearching = false` เสมอตอนจบ |
| 🟠 [checkout_controller.dart:448-479](lib/page/sale_producct/sale/checkout_controller.dart#L448-L479) (`resumeOrder`) | เคลียร์ตะกร้าปัจจุบันก่อนเช็คว่าเจอออเดอร์ที่พักไว้จริงไหม และ auto-clamp จำนวนตามสต็อกปัจจุบันแบบไม่แจ้งเตือน | กู้ออเดอร์ที่พักไว้อาจได้จำนวนสินค้าน้อยกว่าที่พักไว้จริง โดยไม่มีข้อความแจ้งว่าโดนปรับลด | ✅ เช็คก่อนว่าเจอออเดอร์จริงค่อยเคลียร์ตะกร้า + เพิ่ม snackbar แจ้งถ้าสต็อกไม่พอ |
| 🟡 [checkout_page.dart:146-149](lib/page/sale_producct/sale/checkout_page.dart#L146-L149) | ชื่อสินค้าในผลค้นหาไม่มี `maxLines`/`overflow` | ชื่อสินค้ายาวล้นแถว | ✅ เพิ่ม `maxLines: 1` + `overflow: ellipsis` |
| 🔴 [scan_barcode_controller.dart:190-194](lib/page/sale_producct/scanBarcode/scan_barcode_controller.dart#L190-L194) | หยุดกล้องก่อนเปิดหน้ารายการสินค้าไม่มีบาร์โค้ด แต่ไม่เปิดกล้องกลับตอนย้อนมาหน้าสแกน | กลับมาหน้าสแกนแล้วจอกล้องค้าง/ดำ สแกนต่อไม่ได้ ต้องออกแล้วเข้าใหม่ | ✅ แก้ไปแล้วในรอบก่อนหน้า |
| 🟠 [book_list_no_barcode_controller.dart:348-352](lib/page/sale_producct/bookListNoBarcode/book_list_no_barcode_controller.dart#L348-L352) | เช็ค `Get.previousRoute.contains('CheckoutPage')` ซึ่งแทบไม่มีทางเป็นจริง (ไม่ได้ใช้ named routes) | เกือบทุกครั้ง push หน้า Checkout ซ้ำซ้อนแทนที่จะย้อนกลับไปหน้าตะกร้าเดิม → หน้าซ้อนกันสะสม | ✅ พบสาเหตุจริง: `ManualListPage` เกิดบนหน้าสแกนเสมอ (ไม่ใช่บน CheckoutPage โดยตรง) เช็ค `previousRoute` ที่นี่จึงเจอแต่หน้าสแกนไม่มีทางเจอ CheckoutPage — แก้โดยให้ `ScanBarcodeController` เช็คและส่ง flag `cameFromCheckout` มาให้ตั้งแต่ก่อน push แล้วใช้ `Get.close(2)` ปิด 2 หน้าย้อนกลับ CheckoutPage เดิมแทน |
| 🟡 [book_list_no_barcode_controller.dart:326-345](lib/page/sale_producct/bookListNoBarcode/book_list_no_barcode_controller.dart#L326-L345) | เคลียร์ selection ทันทีแม้เพิ่มสินค้าล้มเหลวทุกตัว | ผู้ใช้ต้องเลือกสินค้าใหม่ทั้งหมดแทนที่จะแก้ไขแค่ตัวที่พลาด | ✅ ย้าย `selectedIds.clear()` ไปเรียกเฉพาะตอนเพิ่มสำเร็จอย่างน้อย 1 ชิ้น |
| 🟡 [book_list_no_barcode.dart:238-244](lib/page/sale_producct/bookListNoBarcode/book_list_no_barcode.dart#L238-L244) | ชื่อสินค้าไม่มี `maxLines`/`overflow` | ชื่อยาวล้นการ์ด | ✅ เพิ่ม `maxLines: 1` + `overflow: ellipsis` |

**ส่วนที่เช็คแล้วไม่มีปัญหา:** กันกดจ่ายเงินซ้ำ (`isProcessingPayment`), เคลียร์ตะกร้าหลังขายสำเร็จเท่านั้น (ไม่เคลียร์ก่อน API ตอบ), การพักออเดอร์/ดึงกลับมา (`park_order_controller.dart`, `parked_orders_sheet.dart`)

---

## หมวด 4: หนี้ / ใบสั่งซื้อ / รายงาน

**สถานะ: ✅ แก้ครบทั้ง 8 ข้อแล้ว (2026-08-07)**

| ไฟล์ | จุด | ปัญหา | ผลกระทบ | แก้แล้ว |
|---|---|---|---|---|
| 🔴 [debt_sale_controller.dart](lib/page/debt/debtSale/debt_sale_controller.dart) | ปุ่มยืนยันบันทึกค้างชำระไม่มี flag กันกดซ้ำ | ดับเบิลแท็บ → บันทึกค้างชำระซ้ำ 2 รายการ (ดูหัวข้อ Top) | ✅ แก้ไปแล้วในรอบก่อนหน้า (`isSubmitting` guard) |
| 🟠 [debt_sale_controller.dart:285-291](lib/page/debt/debtSale/debt_sale_controller.dart#L285-L291) | เช็ควงเงินคงเหลือจากข้อมูลลูกหนี้ที่ cache ไว้ฝั่ง client | ตัวเลขวงเงินที่โชว์อาจไม่ทันข้อมูลล่าสุดถ้ามีการบันทึกหนี้จากเครื่อง/เซสชันอื่นพร้อมกัน (server เช็คซ้ำอีกที แต่ข้อความที่แคชเชียร์เห็นก่อนหน้าอาจทำให้เข้าใจผิด) | ✅ เพิ่มการยิง `ApiDebtor.searchDebtor()` รีเฟรชข้อมูลลูกหนี้ก่อนเช็ควงเงินทุกครั้งที่กดยืนยัน |
| 🟠 [order_list.dart:165-167](lib/page/order_products/order_List/order_list.dart#L165-L167) → [order_list_controller.dart:374-390](lib/page/order_products/order_List/order_list_controller.dart#L374-L390) | พิมพ์ "0" ในช่องจำนวนแล้วกดยกเลิกไดอะล็อกลบ ระบบ reset เป็น "1" เสมอ ไม่ใช่ค่าที่แท้จริงก่อนแก้ | แก้จำนวนจาก 10 เป็น 0 โดยไม่ตั้งใจ แล้วกดยกเลิก → ได้ค่า 1 แทนที่จะเป็น 10 เดิม | ✅ เพิ่ม `lastValidQuantity` เก็บค่าที่ถูกต้องล่าสุดไว้แยกต่างหาก ใช้คืนค่าตอนยกเลิกแทนการอ่าน `.text` ที่ถูกแก้ไปแล้ว |
| 🟠 [order_list.dart:260-288](lib/page/order_products/order_List/order_list.dart#L260-L288) | ช่องกรอกจำนวนไม่มี `inputFormatters` กันเลขติดลบ/อักษร | จำนวนสั่งของเพี้ยนตอน export PDF ได้ | ✅ เพิ่ม `FilteringTextInputFormatter.digitsOnly` |
| 🟠 [buy_products_controller.dart:54-100](lib/page/order_products/buyProducts/buy_products_controller.dart#L54-L100) | เปลี่ยนตัวกรอง/เรียงลำดับ/ค้นหา → โหลดสินค้าใหม่ทั้งหมด ทำให้สถานะ `isSelected` ที่เคยติ๊กไว้หายหมด | เลือกสินค้าค้างไว้หลายรายการ พอกรองหมวดหมู่/ค้นหาใหม่ การเลือกหายเงียบๆ โดยไม่มีคำเตือน (ขัดกับ comment ในโค้ดที่บอกว่าออกแบบให้เลือกข้ามหน้าได้) | ✅ จำ id สินค้าที่เลือกไว้ก่อนโหลดใหม่ แล้ว apply `isSelected = true` กลับให้ตัวที่ตรงกันใน object ชุดใหม่ |
| 🟡 [sales_account.dart:38](lib/page/my_blank/sales_account.dart#L38) | เรียก `fetchSummaryData()` ซ้ำใน `addPostFrameCallback` ทุกครั้งที่ build (จาก `onInit` ก็เรียกอยู่แล้ว) | ยิง API รายงานซ้ำโดยไม่จำเป็นทุกครั้งที่จอ rebuild (คีย์บอร์ดเปิด/ปิด ฯลฯ) | ✅ ลบออก (`onInit` ของ controller โหลดให้อยู่แล้ว) |
| 🟡 [debt_ledger.dart:64-185](lib/page/debt/debtLedger/debt_ledger.dart#L64-L185) | มีเมธอด pagination ที่ไม่ถูกเรียกใช้เลย (dead code) และสร้าง `TextEditingController` ใหม่ทุก rebuild โดยไม่ dispose | ไม่กระทบผู้ใช้ตอนนี้ แต่เป็นกับดักถ้ามีคนเอากลับมาใช้ทีหลัง ควรลบทิ้ง | ✅ ลบเมธอดที่ตายแล้วทิ้งทั้งหมด (ตัวจริงใช้ widget `PaginationControls` ที่ dispose ถูกต้องอยู่แล้ว) |
| 🟡 [advanced_report_page.dart:1165-1183](lib/page/my_blank/advanced_report_page.dart#L1165-L1183) | กราฟแท่ง aging ใช้ `flex: data.safe.toInt()` โดยเช็คแค่ `> 0` | ยอดเศษสตางค์ต่ำกว่า 1 บาท (เช่น 0.50) จะ `.toInt()` เป็น 0 แล้ว `Expanded(flex: 0)` throw assertion error ในโหมด debug | ✅ เปลี่ยนเป็น `.ceil()` กันปัดเป็น 0 |

**ส่วนที่เช็คแล้วไม่มีปัญหา:** `debt_payment_controller.dart` (มี `isSubmitting` กันกดซ้ำแล้ว), `debtor_detail_controller.dart`, `debt_register_controller.dart`, `debt_ledger_controller.dart` (pagination/search มี generation-guard ถูกต้อง), `advanced_report_controller.dart` (คำนวณช่วงวันที่ถูกต้อง)

---

## สรุปจำนวนที่พบ

- 🔴 สูง: 9 จุด (ส่วนใหญ่อยู่ในหน้าขายสินค้า/หนี้ ซึ่งกระทบเงินโดยตรง หรือทำแอป crash)
- 🟠 กลาง: 15 จุด
- 🟡 ต่ำ: 15 จุด

แนะนำให้ไล่แก้กลุ่ม 🔴 ก่อนทั้งหมด โดยเฉพาะ 3 จุดในหน้าขายสินค้า (checkout) เพราะกระทบยอดเงินที่ตัดจริงโดยตรง
