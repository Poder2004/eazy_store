import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // สำหรับ FilteringTextInputFormatter
import 'package:get/get.dart';
import 'createShop/create_shop_controller.dart';

class SetShopPinPage extends StatefulWidget {
  const SetShopPinPage({Key? key}) : super(key: key);

  @override
  State<SetShopPinPage> createState() => _SetShopPinPageState();
}

class _SetShopPinPageState extends State<SetShopPinPage> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // ดึงคีย์บอร์ดขึ้นมาอัตโนมัติเมื่อเปิดหน้านี้
    Future.delayed(Duration.zero, () {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ดึง Controller ตัวเดิมมาใช้
    final controller = Get.find<CreateShopController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      // GestureDetector เพื่อให้กดที่ว่างๆ บนจอแล้วคีย์บอร์ดไม่หาย หรือเรียกคีย์บอร์ดกลับมาได้
      body: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: Obx(() {
          return Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                "ตั้งค่ารหัส PIN",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                controller.isConfirmPinStep.value
                    ? "โปรดยืนยัน รหัส PIN อีกครั้ง เพื่อความถูกต้อง"
                    : "สร้าง รหัส PIN 6 หลักสำหรับร้านค้า",
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 50),

              // ใช้ Stack เพื่อซ่อน TextField ไว้ด้านหลัง UI จุด PIN
              Stack(
                alignment: Alignment.center,
                children: [
                  // 1. TextField ที่มองไม่เห็น แต่ทำหน้าที่รับค่าจากแป้นพิมพ์ระบบ
                  Opacity(
                    opacity: 0, // ทำให้โปร่งใส 100%
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly], // รับเฉพาะตัวเลข
                      maxLength: 6, // จำกัด 6 ตัว
                      onChanged: (value) {
                        // อัปเดตค่าใน Controller โดยตรง
                        controller.currentPin.value = value;
                      },
                    ),
                  ),

                  // 2. แสดงจุด PIN 6 จุด
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index < controller.currentPin.value.length
                              ? const Color(0xFF00C853) // สีเขียวเมื่อพิมพ์
                              : Colors.grey.shade300,
                        ),
                      );
                    }),
                  ),
                ],
              ),

              const Spacer(),

              // ปุ่มยืนยัน (แสดงเมื่อครบ 6 หลัก)
              if (controller.currentPin.value.length == 6)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  margin: const EdgeInsets.only(bottom: 30),
                  child: ElevatedButton(
                    onPressed: () {
                      controller.confirmCurrentPin();
                      // เคลียร์ TextField หลังจากกดปุ่ม เพื่อรองรับจังหวะสลับไปหน้า "ยืนยันรหัสอีกครั้ง"
                      _textController.clear(); 
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      "ยืนยัน",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}