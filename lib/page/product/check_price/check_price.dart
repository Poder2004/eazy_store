import 'package:eazy_store/page/menu_bar/bottom_navbar.dart';
import 'package:eazy_store/model/response/product_response.dart';
import 'package:eazy_store/page/product/product_detail/product_detail.dart';
import 'package:eazy_store/page/product/check_price/check_price_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CheckPriceScreen extends StatelessWidget {
  const CheckPriceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PriceController controller = Get.put(PriceController());

    const Color primaryColor = Color(0xFF6B8E23);
    const Color backgroundColor = Color(0xFFF7F7F7);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'เช็คราคาสินค้า',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            controller.fetchInitialData(), // เรียกโหลดข้อมูลเริ่มต้นใหม่
        color: primaryColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              _buildSearchBar(controller, primaryColor),
              const SizedBox(height: 15),

              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    );
                  }

                  // 🏷️ กรณีไม่พบข้อมูล หรือยังไม่ได้เริ่มค้นหา
                  if (controller.filteredProducts.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Text(
                            "พิมพ์ชื่อสินค้าหรือสแกนบาร์โค้ด", // ✅ แก้ไขตรงนี้แล้ว
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: controller.filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = controller.filteredProducts[index];

                      return InkWell(
                        onTap: () async {
                          var result = await Get.to(
                            () => const ProductDetailScreen(),
                            arguments: product,
                            transition: Transition.rightToLeft,
                          );

                          if (result == true) {
                            controller.fetchInitialData();
                          }
                        },
                        borderRadius: BorderRadius.circular(15),
                        child: _buildPriceCard(product, primaryColor),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
       bottomNavigationBar: BottomNavBar(
        currentIndex: -1, // ใส่ -1 จะไม่มีปุ่มไหนถูกเลือก (ไม่มีสีแดงโชว์)
        onTap: (index) {
          // ใส่ Logic การเปลี่ยนหน้าตามปกติของคุณ
          print("Tab tapped: $index");
        },
      ),
    );
  }

  Widget _buildSearchBar(PriceController controller, Color primaryColor) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller.searchCtrl,
        decoration: InputDecoration(
          hintText: 'ค้นหาชื่อสินค้า หรือ สแกนบาร์โค้ด...',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: IconButton(
            icon: Icon(Icons.qr_code_scanner_outlined, color: primaryColor),
            onPressed: controller.openScanner,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
        ),
      ),
    );
  }

  Widget _buildPriceCard(ProductResponse product, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              product.imgProduct,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[200],
                width: 70,
                height: 70,
                child: const Icon(Icons.image_outlined, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "รหัส: ${product.productCode ?? '-'}",
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                product.sellPrice.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                ),
              ),
              const Text(
                'บาท',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
