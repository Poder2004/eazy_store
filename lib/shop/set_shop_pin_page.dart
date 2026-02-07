import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../shop/create_shop.dart'; // Import controller ตัวเดิม

class SetShopPinPage extends StatelessWidget {
  const SetShopPinPage({Key? key}) : super(key: key);

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
      body: Obx(() {
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
            
            // แสดงจุด PIN 6 จุด
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
                        ? const Color(0xFF00C853) // สีเขียวเมื่อกด
                        : Colors.grey.shade300,
                  ),
                );
              }),
            ),
            
            const Spacer(),

            // ปุ่มยืนยัน (แสดงเมื่อครบ 6 หลัก)
            if (controller.currentPin.value.length == 6)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 40),
                margin: const EdgeInsets.only(bottom: 20),
                child: ElevatedButton(
                  onPressed: () {
                    controller.confirmCurrentPin();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text("ยืนยัน", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),

            // Numpad
            Container(
              color: const Color(0xFFF9F9F9),
              padding: const EdgeInsets.only(bottom: 30, top: 20),
              child: Column(
                children: [
                  _buildNumRow(controller, ["1", "2", "3"]),
                  _buildNumRow(controller, ["4", "5", "6"]),
                  _buildNumRow(controller, ["7", "8", "9"]),
                  _buildNumRow(controller, ["", "0", "del"]),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildNumRow(CreateShopController controller, List<String> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: keys.map((key) {
          if (key.isEmpty) return const SizedBox(width: 80, height: 80);
          
          return InkWell(
            onTap: () {
              if (key == "del") {
                controller.deletePinDigit();
              } else {
                controller.addPinDigit(key);
              }
            },
            borderRadius: BorderRadius.circular(40),
            child: Container(
              width: 80,
              height: 80,
              alignment: Alignment.center,
              decoration: key == "del" 
                  ? null 
                  : const BoxDecoration(shape: BoxShape.circle, color: Colors.white), 
              child: key == "del"
                  ? const Icon(Icons.backspace_outlined, size: 30)
                  : Text(key, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ),
          );
        }).toList(),
      ),
    );
  }
}