import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
// **Imports ที่เพิ่มเข้ามาสำหรับการโหลดไฟล์**
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:async';

// --- THEME & CONSTANTS ---
const Color _kPrimaryColor = Color(0xFF6B8E23); // สีเขียวมะกอก/ทหาร
const Color _kBackgroundColor = Color(0xFFF7F7F7); // สีพื้นหลังอ่อน
const Color _kFieldFillColor = Color(0xFFFAFFEF); // สีอ่อนสำหรับช่องกรอกข้อมูล
const Color _kBorderColor = Color(0xFFE0E0E0); // สีขอบอ่อน



// 📌 1. เปลี่ยนเป็น StatefulWidget เพื่อจัดการสถานะการโหลดข้อมูลและ Dropdown
class DebtRegisterScreen extends StatefulWidget {
  const DebtRegisterScreen({super.key});

  @override
  State<DebtRegisterScreen> createState() =>
      _DebtRegisterScreenState();
}

class _DebtRegisterScreenState extends State<DebtRegisterScreen> {
  // สถานะสำหรับ Dropdown
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedSubdistrict;

  // สถานะสำหรับข้อมูลที่อยู่ทั้งหมดที่โหลดมา
  // Map<ชื่อจังหวัด, ข้อมูลจังหวัดทั้งหมด (รวมอำเภอ, ตำบล)>
  Map<String, dynamic>? _fullAddressData;

  // รายการสำหรับ Dropdown อำเภอ/ตำบล ที่ถูกกรองแล้ว (เก็บเป็นชื่อเท่านั้น)
  List<String> _districts = [];
  List<String> _subdistricts = [];

  // 📌 2. Logic การโหลดไฟล์ JSON
  Future<Map<String, dynamic>> _loadAddressData() async {
    try {
      // ตรวจสอบ Asset Path ให้ตรงกับที่คุณตั้งใน pubspec.yaml
      const assetPath =
          'assets/data_address/province_with_district_and_sub_district.json';
      final String response = await rootBundle.loadString(assetPath);

      final List<dynamic> rawData = jsonDecode(response);

      final Map<String, dynamic> structuredData = {};
      // จัดโครงสร้างข้อมูล: ใช้ชื่อจังหวัด (name_th) เป็น Key หลัก
      for (var province in rawData) {
        String provinceName =
            province['name_th'] as String? ?? 'ไม่ระบุจังหวัด';
        structuredData[provinceName] = province;
      }

      return structuredData;
    } catch (e) {
      print(
        "🚨 Error loading address data. Did you forget to add the file to assets in pubspec.yaml? Error: $e",
      );
      return {};
    }
  }

  @override
  void initState() {
    super.initState();
    // โหลดข้อมูลเมื่อ Widget ถูกสร้าง
    _loadAddressData().then((data) {
      setState(() {
        _fullAddressData = data;
      });
    });
  }

  // 📌 3. Logic การจัดการการเปลี่ยนแปลง (Cascading Logic)

  void _resetDistrictAndSubdistrict() {
    setState(() {
      _selectedDistrict = null;
      _selectedSubdistrict = null;
      _districts = [];
      _subdistricts = [];
    });
  }

  void _resetSubdistrict() {
    setState(() {
      _selectedSubdistrict = null;
      _subdistricts = [];
    });
  }

  void _onProvinceChanged(String? newValue) {
    if (newValue == null || _fullAddressData == null) {
      _resetDistrictAndSubdistrict();
      return;
    }

    _resetDistrictAndSubdistrict();
    setState(() {
      _selectedProvince = newValue;

      // กรองและดึงรายการอำเภอจากจังหวัดที่เลือก
      final provinceData = _fullAddressData![newValue];
      final List<dynamic>? rawDistricts =
          provinceData?['districts'] as List<dynamic>?;

      if (rawDistricts != null) {
        _districts = rawDistricts
            .map((district) => district['name_th'] as String? ?? 'ไม่ระบุอำเภอ')
            .toList();
      }
    });
  }

  void _onDistrictChanged(String? newValue) {
    if (newValue == null ||
        _selectedProvince == null ||
        _fullAddressData == null) {
      _resetSubdistrict();
      return;
    }

    _resetSubdistrict();
    setState(() {
      _selectedDistrict = newValue;

      final provinceData = _fullAddressData![_selectedProvince!];
      final List<dynamic>? rawDistricts =
          provinceData?['districts'] as List<dynamic>?;

      if (rawDistricts != null) {
        // ค้นหาอำเภอที่ตรงกับที่เลือก
        final selectedDistrictData = rawDistricts.firstWhere(
          (d) => d['name_th'] == newValue,
          orElse: () => null,
        );

        // ดึงรายการตำบลจากอำเภอนั้น
        final List<dynamic>? rawSubdistricts =
            selectedDistrictData?['sub_districts'] as List<dynamic>?;

        if (rawSubdistricts != null) {
          _subdistricts = rawSubdistricts
              .map((sub) => sub['name_th'] as String? ?? 'ไม่ระบุตำบล')
              .toList();
        }
      }
    });
  }

  // 4. Widget สำหรับช่องกรอกข้อมูล
  Widget _buildInputField({
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool isAddress = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isAddress)
          Padding(
            padding: const EdgeInsets.only(top: 15.0, bottom: 5.0),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ),
        Container(
          height: 50,
          margin: EdgeInsets.only(top: isAddress ? 10.0 : 0),
          decoration: BoxDecoration(
            color: _kFieldFillColor,
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: _kBorderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: TextField(
            keyboardType: keyboardType,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 15),
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey),
              border: InputBorder.none,
            ),
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  // 📌 5. Widget สำหรับ Dropdown ที่อยู่แบบ Cascading (ย้ายมาใน State Class)
  Widget _buildAddressDropdown<T>({
    required String hint,
    required T? selectedValue,
    required List<T> items,
    required void Function(T?) onChanged,
    bool disabled = false,
  }) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 10.0),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: disabled ? _kFieldFillColor.withOpacity(0.6) : _kFieldFillColor,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: _kBorderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          hint: Text(
            hint,
            style: TextStyle(
              color: disabled ? Colors.grey.shade400 : Colors.grey,
            ),
          ),
          value: selectedValue,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: disabled ? Colors.grey.shade400 : Colors.grey,
          ),
          onChanged: disabled ? null : onChanged,
          items: items.map((T value) {
            return DropdownMenuItem<T>(
              value: value,
              child: Text(
                value.toString(),
                style: const TextStyle(color: Colors.black87),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // 📌 6. Widget สำหรับช่องอัปโหลดรูปภาพ (ย้ายมาใน State Class)
  Widget _buildProfileImageUploader() {
    return Center(
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('จำลอง: กำลังเปิดกล้อง/คลังรูปภาพ...'),
            ),
          );
        },
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: _kFieldFillColor,
            border: Border.all(
              color: _kPrimaryColor.withOpacity(0.5),
              style: BorderStyle.solid,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                color: _kPrimaryColor.withOpacity(0.7),
                size: 30,
              ),
              const SizedBox(height: 5),
              Text(
                'แตะเพื่อเพิ่ม\nรูปคนค้างชำระ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: _kPrimaryColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // รายการจังหวัดทั้งหมด (Keys ของ Map ข้อมูลที่จัดโครงสร้างแล้ว)
    final List<String> provinces = _fullAddressData?.keys.toList() ?? [];

    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'สมัครบัญชีลูกหนี้',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color(0xFF333333),
          ),
        ),
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
            // 1. ช่องอัปโหลดรูปภาพ
            _buildProfileImageUploader(),
            const SizedBox(height: 30),

            // 2. ชื่อคนค้างชำระ
            _buildInputField(label: 'ชื่อคนค้างชำระ', hint: 'นาย ก'),

            // 3. เบอร์โทรศัพท์
            _buildInputField(
              label: 'เบอร์โทรศัพท์',
              hint: '098-555-5446',
              keyboardType: TextInputType.phone,
            ),

            // 4. ที่อยู่ (Dropdowns และ Text Field)
            const Text(
              'ที่อยู่',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
                height: 2.0,
              ),
            ),

            // ➡️ ใช้ Conditional Rendering เพื่อแสดง Loading หรือ Dropdown
            if (_fullAddressData == null)
              const Center(
                heightFactor: 5,
                child: CircularProgressIndicator(color: _kPrimaryColor),
              )
            else ...[
              // Dropdown จังหวัด
              _buildAddressDropdown<String>(
                hint: 'จังหวัด',
                selectedValue: _selectedProvince,
                items: provinces,
                onChanged: _onProvinceChanged,
                disabled: provinces.isEmpty,
              ),

              // Dropdown อำเภอ (ปรากฏเมื่อเลือกจังหวัดแล้ว)
              _buildAddressDropdown<String>(
                hint: 'อำเภอ',
                selectedValue: _selectedDistrict,
                items: _districts,
                onChanged: _onDistrictChanged,
                disabled: _selectedProvince == null || _districts.isEmpty,
              ),

              // Dropdown ตำบล (ปรากฏเมื่อเลือกอำเภอแล้ว)
              _buildAddressDropdown<String>(
                hint: 'ตำบล',
                selectedValue: _selectedSubdistrict,
                items: _subdistricts,
                onChanged: (newValue) {
                  setState(() {
                    _selectedSubdistrict = newValue;
                  });
                },
                disabled: _selectedDistrict == null || _subdistricts.isEmpty,
              ),
            ],

            // ช่อง บ้านเลขที่
            _buildInputField(hint: 'บ้านเลขที่', label: '', isAddress: true),

            // 5. วงเงินค้างชำระ
            _buildInputField(
              label: 'วงเงินค้างชำระ',
              hint: '2000',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 40),

            // 6. ปุ่ม "เพิ่ม"
            ElevatedButton(
              onPressed: () {
                // จำลองการบันทึก
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('บันทึกบัญชีลูกหนี้เรียบร้อย!'),
                    backgroundColor: _kPrimaryColor,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                elevation: 3,
              ),
              child: const Text(
                'เพิ่ม',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
