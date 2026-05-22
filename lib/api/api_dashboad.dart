import 'dart:convert';
import 'package:eazy_store/model/response/sales_summary_respone.dart';
import 'package:eazy_store/model/response/dashboard_detail_response.dart';
import 'package:eazy_store/model/response/advanced_report_response.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eazy_store/config/app_config.dart';

class ApiDashboad {
  // ✅ ฟังก์ชัน สำหรับดึงข้อมูลสรุปยอดขาย วัน เดือน ปี
  static Future<SalesSummaryModel?> getSalesSummary(
    int shopId,
    String startDate,
    String endDate,
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // ส่งวันที่ไปใน Query Parameter
      final Uri url = Uri.parse(
        "${AppConfig.baseUrl}/api/dashboard/sales-summary?shop_id=$shopId&start_date=$startDate&end_date=$endDate",
      );

      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        // นำ JSON ที่ได้ไปแปลงผ่าน Model
        return SalesSummaryModel.fromJson(jsonDecode(response.body));
      } else {
        print("Summary API Error: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Summary API Exception: $e");
      return null;
    }
  }

  // ✅ ฟังก์ชันดึงรายละเอียดบิลทั้งหมด
  static Future<List<TransactionDetailModel>> getTransactionsDetail(
    int shopId,
    String startDate,
    String endDate,
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final Uri url = Uri.parse(
        "${AppConfig.baseUrl}/api/dashboard/transactions?shop_id=$shopId&start_date=$startDate&end_date=$endDate",
      );

      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> list = data['transactions'] ?? [];
        return list.map((e) => TransactionDetailModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("Transaction Detail API Exception: $e");
      return [];
    }
  }

  // ✅ ฟังก์ชันดึงรายละเอียดสินค้ายอดขาย/กำไร
  static Future<List<ProductSalesDetailModel>> getProductSalesDetail(
    int shopId,
    String startDate,
    String endDate,
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final Uri url = Uri.parse(
        "${AppConfig.baseUrl}/api/dashboard/product-details?shop_id=$shopId&start_date=$startDate&end_date=$endDate",
      );

      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> list = data['product_details'] ?? [];
        return list.map((e) => ProductSalesDetailModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("Product Sales Detail API Exception: $e");
      return [];
    }
  }

  // ✅ ฟังก์ชันดึงรายงานขั้นสูง
  static Future<AdvancedReportResponse?> getAdvancedReport(
    int shopId,
    String startDate,
    String endDate,
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final Uri url = Uri.parse(
        "${AppConfig.baseUrl}/api/dashboard/advanced-report?shop_id=$shopId&start_date=$startDate&end_date=$endDate",
      );

      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        return AdvancedReportResponse.fromJson(jsonDecode(response.body));
      } else {
        print("Advanced Report API Error: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Advanced Report API Exception: $e");
      return null;
    }
  }
}
