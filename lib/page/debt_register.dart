import 'package:eazy_store/api/api_service_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // ใช้ Get สำหรับ Snackbar
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:async';
import '../model/request/debtor_request.dart';
import '../api/api_debtor.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- THEME & CONSTANTS ---
const Color _kPrimaryColor = Color(0xFF6B8E23);
const Color _kBackgroundColor = Color(0xFFF7F7F7);
const Color _kFieldFillColor = Color(0xFFFAFFEF);
const Color _kBorderColor = Color(0xFFE0E0E0);

class DebtRegisterScreen extends StatefulWidget {
  const DebtRegisterScreen({super.key});

  @override
  State<DebtRegisterScreen> createState() => _DebtRegisterScreenState();
}

class _DebtRegisterScreenState extends State<DebtRegisterScreen> {
  File? _imageFile; // ตัวแปรเก็บรูปที่เลือก
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressDetailController = TextEditingController();
  final TextEditingController _creditLimitController = TextEditingController();

  // สถานะสำหรับ Dropdown
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedSubdistrict;

  Map<String, dynamic>? _fullAddressData;
  List<String> _districts = [];
  List<String> _subdistricts = [];

  @override
  void initState() {
    super.initState();
    _loadAddressData().then((data) {
      setState(() {
        _fullAddressData = data;
      });
    });
  }

  @override
  void dispose() {
    // ล้าง Memory เมื่อปิดหน้าจอ
    _nameController.dispose();
    _phoneController.dispose();
    _addressDetailController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  // 📌 2. Logic การโหลดข้อมูลที่อยู่
  Future<Map<String, dynamic>> _loadAddressData() async {
    try {
      const assetPath = 'assets/data_address/province_with_district_and_sub_district.json';
      final String response = await rootBundle.loadString(assetPath);
      final List<dynamic> rawData = jsonDecode(response);

      final Map<String, dynamic> structuredData = {};
      for (var province in rawData) {
        String provinceName = province['name_th'] as String? ?? 'ไม่ระบุจังหวัด';
        structuredData[provinceName] = province;
      }
      return structuredData;
    } catch (e) {
      debugPrint("🚨 Error loading address data: $e");
      return {};
    }
  }

  // 📌 3. Logic การส่งข้อมูลไป API
 Future<void> _submitDebtorData() async {
  // 1. Check validation เบื้องต้น
  if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
    Get.snackbar("แจ้งเตือน", "กรุณากรอกชื่อและเบอร์โทรศัพท์",
        backgroundColor: Colors.orange, colorText: Colors.white);
    return;
  }

  // 2. แสดง Loading ทันทีเพื่อกันผู้ใช้กดซ้ำ
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(color: _kPrimaryColor),
    ),
  );

  try {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int shopId = prefs.getInt('shopId') ?? 0; // ต้องมั่นใจว่าตอน Login ได้เก็บค่านี้ไว้

    if (shopId == 0) {
       Get.snackbar("ผิดพลาด", "ไม่พบข้อมูลร้านค้า กรุณาล็อกอินใหม่", 
           backgroundColor: Colors.red, colorText: Colors.white);
       return;
    }

    String imageUrl = ""; // ตัวแปรสำหรับเก็บ URL จาก Cloudinary

    // 3. เริ่มขั้นตอนอัปโหลดรูปภาพ (ถ้ามีการเลือกรูปไว้)
    if (_imageFile != null) {
      final uploadService = ImageUploadService();
      // อัปโหลดและรอรับ URL
      String? uploadedUrl = await uploadService.uploadImage(_imageFile!);
      
      if (uploadedUrl != null) {
        imageUrl = uploadedUrl;
      } else {
        // ถ้าอัปโหลดรูปไม่สำเร็จ ให้หยุดและแจ้งเตือน
        Navigator.pop(context); // ปิด loading
        Get.snackbar("ผิดพลาด", "ไม่สามารถอัปโหลดรูปภาพได้ กรุณาลองใหม่",
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
    }

    // 4. รวมที่อยู่เป็น String
    String fullAddress = "${_addressDetailController.text} "
        "ต.${_selectedSubdistrict ?? '-'} "
        "อ.${_selectedDistrict ?? '-'} "
        "จ.${_selectedProvince ?? '-'}";

    // 5. สร้าง Request Model โดยใส่ imageUrl ที่ได้มาจริง
    DebtorRequest newDebtor = DebtorRequest(
      shopId: shopId,
      name: _nameController.text,
      phone: _phoneController.text,
      address: fullAddress,
      imgDebtor: imageUrl, // ใส่ URL ที่ได้จาก Cloudinary
      creditLimit: double.tryParse(_creditLimitController.text) ?? 0.0,
      currentDebt: 0.0,
    );

    // 6. เรียกใช้ API ของเราเพื่อบันทึกลงฐานข้อมูล Go
    var result = await ApiDebtor.createDebtor(newDebtor);

    Navigator.pop(context); // ปิด Loading เมื่อ API ทำงานเสร็จ

    if (result['success']) {
      Get.snackbar("สำเร็จ", result['message'],
          backgroundColor: Colors.green, colorText: Colors.white);
      
      // หน่วงเวลาเล็กน้อยก่อนปิดหน้าจอ เพื่อให้ User เห็น Snackbar
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context); 
      });
    } else {
      Get.snackbar("ผิดพลาด", result['message'],
          backgroundColor: Colors.red, colorText: Colors.white);
    }

  } catch (e) {
    Navigator.pop(context); // ปิด Loading ถ้าเกิด Error ที่คาดไม่ถึง
    Get.snackbar("Error", "เกิดข้อผิดพลาด: $e",
        backgroundColor: Colors.red, colorText: Colors.white);
  }
}

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 80, // ลดขนาดไฟล์เพื่อประหยัดพื้นที่ Database
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // --- Cascading Logic สำหรับที่อยู่ ---
  void _onProvinceChanged(String? newValue) {
    if (newValue == null) return;
    setState(() {
      _selectedProvince = newValue;
      _selectedDistrict = null;
      _selectedSubdistrict = null;
      _subdistricts = [];
      final provinceData = _fullAddressData![newValue];
      final List<dynamic>? rawDistricts = provinceData?['districts'] as List<dynamic>?;
      _districts = rawDistricts?.map((d) => d['name_th'] as String).toList() ?? [];
    });
  }

  void _onDistrictChanged(String? newValue) {
    if (newValue == null) return;
    setState(() {
      _selectedDistrict = newValue;
      _selectedSubdistrict = null;
      final provinceData = _fullAddressData![_selectedProvince!];
      final List<dynamic> rawDistricts = provinceData?['districts'];
      final selectedDistrictData = rawDistricts.firstWhere((d) => d['name_th'] == newValue);
      final List<dynamic>? rawSubs = selectedDistrictData['sub_districts'] as List<dynamic>?;
      _subdistricts = rawSubs?.map((s) => s['name_th'] as String).toList() ?? [];
    });
  }

  void _showImageSourceSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("เลือกรูปภาพลูกหนี้", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerButton(
                  icon: Icons.camera_alt_rounded,
                  label: "ถ่ายภาพ",
                  color: Colors.blueAccent,
                  onTap: () {
                    Get.back();
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildPickerButton(
                  icon: Icons.photo_library_rounded,
                  label: "คลังรูปภาพ",
                  color: Colors.purpleAccent,
                  onTap: () {
                    Get.back();
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> provinces = _fullAddressData?.keys.toList() ?? [];

    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        title: const Text('สมัครบัญชีลูกหนี้', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        centerTitle: true,
        backgroundColor: _kBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileImageUploader(),
            const SizedBox(height: 30),

            _buildInputField(label: 'ชื่อคนค้างชำระ', hint: 'ชื่อคนค้างชำระ', controller: _nameController),
            _buildInputField(label: 'เบอร์โทรศัพท์', hint: 'เบอร์โทรศัพท์', controller: _phoneController, keyboardType: TextInputType.phone),

            const Padding(
              padding: EdgeInsets.only(top: 15.0),
              child: Text('ที่อยู่', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),

            if (_fullAddressData == null)
              const LinearProgressIndicator(color: _kPrimaryColor)
            else ...[
              _buildAddressDropdown(hint: 'จังหวัด', selectedValue: _selectedProvince, items: provinces, onChanged: _onProvinceChanged),
              _buildAddressDropdown(hint: 'อำเภอ', selectedValue: _selectedDistrict, items: _districts, onChanged: _onDistrictChanged, disabled: _selectedProvince == null),
              _buildAddressDropdown(hint: 'ตำบล', selectedValue: _selectedSubdistrict, items: _subdistricts, onChanged: (v) => setState(() => _selectedSubdistrict = v), disabled: _selectedDistrict == null),
            ],

            _buildInputField(hint: 'บ้านเลขที่/ซอย/ถนน', label: '', isAddress: true, controller: _addressDetailController),

            _buildInputField(label: 'วงเงินค้างชำระ', hint: 'วงเงินค้างชำระ', controller: _creditLimitController, keyboardType: TextInputType.number),
            
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _submitDebtorData, // เรียกใช้ฟังก์ชันส่งข้อมูล
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
              ),
              child: const Text('เพิ่ม', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- Reusable Widgets ---

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool isAddress = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isAddress)
          Padding(
            padding: const EdgeInsets.only(top: 15.0, bottom: 5.0),
            child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          ),
        Container(
          height: 50,
          margin: EdgeInsets.only(top: isAddress ? 10.0 : 0),
          decoration: BoxDecoration(
            color: _kFieldFillColor,
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: _kBorderColor),
          ),
          child: TextField(
            controller: controller, // เชื่อมต่อ Controller
            keyboardType: keyboardType,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 15),
              hintText: hint,
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressDropdown({
    required String hint,
    required String? selectedValue,
    required List<String> items,
    required void Function(String?) onChanged,
    bool disabled = false,
  }) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 10.0),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: disabled ? Colors.grey.shade200 : _kFieldFillColor,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: _kBorderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint, style: TextStyle(color: disabled ? Colors.grey : Colors.grey.shade600)),
          value: selectedValue,
          onChanged: disabled ? null : onChanged,
          items: items.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
        ),
      ),
    );
  }

  Widget _buildProfileImageUploader() {
    return Center(
      child: GestureDetector(
        onTap: _showImageSourceSheet, // กดแล้วเด้งเมนูเลือก
        child: Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            color: _kFieldFillColor,
            border: Border.all(color: _kPrimaryColor.withOpacity(0.5), width: 2),
            borderRadius: BorderRadius.circular(15.0),
            image: _imageFile != null
                ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                : null,
          ),
          child: _imageFile == null
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined, color: _kPrimaryColor, size: 40),
                    Text('เพิ่มรูปภาพ', style: TextStyle(fontSize: 14, color: _kPrimaryColor)),
                  ],
                )
              : null, // ถ้ามีรูปแล้วจะไม่แสดง Icon
        ),
      ),
    );
  }

  Widget _buildPickerButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}