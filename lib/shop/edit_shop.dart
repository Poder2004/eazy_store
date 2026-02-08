import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../api/api_shop.dart';
import '../model/response/shop_response.dart';

class EditShopScreen extends StatefulWidget {
  final ShopResponse shop; // รับข้อมูลร้านค้าเดิมเข้ามา

  const EditShopScreen({super.key, required this.shop});

  @override
  State<EditShopScreen> createState() => _EditShopScreenState();
}

class _EditShopScreenState extends State<EditShopScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiShop _apiShop = ApiShop();
  bool _isUpdating = false; // เอาไว้หมุนๆ ตอนกดบันทึก

  // ตัวแปรเก็บค่า Text
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _pinCodeController;

  @override
  void initState() {
    super.initState();
    // ดึงค่าเดิมมาใส่ในช่องกรอก
    _nameController = TextEditingController(text: widget.shop.name);
    _phoneController = TextEditingController(text: widget.shop.phone);
    _addressController = TextEditingController(text: widget.shop.address);
    // แปลง PinCode เป็น String (ถ้า Model เป็น int ก็ต้อง .toString())
    _pinCodeController = TextEditingController(text: widget.shop.pinCode);
  }

  @override
  void dispose() {
    // คืน memory เมื่อปิดหน้า
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }

  // ฟังก์ชันกดบันทึก
  void _submitUpdate() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUpdating = true; // เริ่มหมุน
      });

      // เตรียมข้อมูลส่งไป Backend (Key ต้องตรงกับ struct UpdateShopInput ใน Go)
      Map<String, dynamic> updateData = {
        "name": _nameController.text,
        "phone": _phoneController.text,
        "address": _addressController.text,
        "pin_code": _pinCodeController.text,
        // รูปภาพ: ถ้าไม่ได้แก้ ส่งเป็น null หรือค่าเดิม (ในที่นี้เรายังไม่ทำ upload รูปใหม่ในหน้านี้)
        "img_shop": widget.shop.imgShop, 
        "img_qrcode": widget.shop.imgQrcode,
      };

      // เรียก API
      bool success = await _apiShop.updateShop(widget.shop.shopId, updateData);

      setState(() {
        _isUpdating = false; // หยุดหมุน
      });

      if (success) {
        // แจ้งเตือน และ ปิดหน้า
        Get.back(result: true); // ส่ง true กลับไปบอกหน้า List ว่า "มี update นะ"
        Get.snackbar(
          "สำเร็จ", 
          "บันทึกข้อมูลเรียบร้อยแล้ว",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          "ผิดพลาด", 
          "ไม่สามารถบันทึกข้อมูลได้",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("แก้ไขข้อมูลร้านค้า"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- ชื่อร้าน ---
              _buildLabel("ชื่อร้านค้า"),
              TextFormField(
                controller: _nameController,
                decoration: _buildInputDecoration("กรอกชื่อร้าน"),
                validator: (val) => val!.isEmpty ? "กรุณากรอกชื่อร้าน" : null,
              ),
              const SizedBox(height: 15),

              // --- เบอร์โทร ---
              _buildLabel("เบอร์โทรศัพท์"),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _buildInputDecoration("กรอกเบอร์โทร"),
                validator: (val) => val!.isEmpty ? "กรุณากรอกเบอร์โทร" : null,
              ),
              const SizedBox(height: 15),

              // --- ที่อยู่ ---
              _buildLabel("ที่อยู่ร้าน"),
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: _buildInputDecoration("กรอกที่อยู่ร้านอย่างละเอียด"),
                validator: (val) => val!.isEmpty ? "กรุณากรอกที่อยู่" : null,
              ),
              const SizedBox(height: 15),

              // --- Pin Code ---
              _buildLabel("Pin Code (6 หลัก)"),
              TextFormField(
                controller: _pinCodeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: _buildInputDecoration("เช่น 123456"),
                validator: (val) {
                  if (val!.isEmpty) return "กรุณากรอก Pin Code";
                  if (val.length != 6) return "Pin Code ต้องมี 6 หลัก";
                  return null;
                },
              ),
              
              const SizedBox(height: 30),

              // --- ปุ่มบันทึก ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUpdating ? null : _submitUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853), // สีเขียวธีมเดิม
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isUpdating
                      ? const SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Text(
                          "บันทึกการเปลี่ยนแปลง",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget สำหรับ Label
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  // Helper สำหรับ Decoration ของ Input
  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }
}