import 'package:eazy_store/page/add_product.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Eazy Store',
      theme: ThemeData(fontFamily: 'AbhayaLibre'), // เปลี่ยนสี Theme เล็กน้อย
      home: const AddProductScreen(), // เริ่มที่หน้า Login โดยตรง
    );
  }
}