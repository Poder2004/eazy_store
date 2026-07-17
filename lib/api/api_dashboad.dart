import 'dart:convert';
import 'package:eazy_store/model/response/sales_summary_respone.dart';
import 'package:eazy_store/model/response/dashboard_detail_response.dart';
import 'package:eazy_store/model/response/advanced_report_response.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eazy_store/config/app_config.dart';
import 'package:eazy_store/utils/auth_guard.dart';

class ApiDashboad {
  // ✅ ฟังก์ชัน สำหรับดึงข้อมูลสรุปยอดขาย วัน เดือน ปี
  static Future<SalesSummaryModel?> getSalesSummary(
    int shopId,
    String startDate,
    String endDate,
  ) async {
    try {
      await AuthGuard.checkAndRefreshIfNeeded();
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
        return SalesSummaryModel.fromJson(jsonDecode(response.body));
      } else {
        if (AuthGuard.isUnauthorized(response.statusCode)) {
          await AuthGuard.handleUnauthorized();
        }
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
      await AuthGuard.checkAndRefreshIfNeeded();
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
      } else {
        if (AuthGuard.isUnauthorized(response.statusCode)) {
          await AuthGuard.handleUnauthorized();
        }
        return [];
      }
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
      await AuthGuard.checkAndRefreshIfNeeded();
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
      } else {
        if (AuthGuard.isUnauthorized(response.statusCode)) {
          await AuthGuard.handleUnauthorized();
        }
        return [];
      }
    } catch (e) {
      print("Product Sales Detail API Exception: $e");
      return [];
    }
  }

  // ✅ ฟังก์ชันดึงรายการสินค้าในบิล (รอ backend)
  static Future<SaleDetailModel?> getSaleItems(
    int shopId,
    int saleId,
  ) async {
    try {
      await AuthGuard.checkAndRefreshIfNeeded();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final Uri url = Uri.parse(
        "${AppConfig.baseUrl}/api/dashboard/sale-items?shop_id=$shopId&sale_id=$saleId",
      );

      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        return SaleDetailModel.fromJson(jsonDecode(response.body));
      } else {
        if (AuthGuard.isUnauthorized(response.statusCode)) {
          await AuthGuard.handleUnauthorized();
        }
        print("Sale Items API Error: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Sale Items API Exception: $e");
      return null;
    }
  }

  // ✅ ฟังก์ชันดึงรายงานขั้นสูง
  static Future<AdvancedReportResponse?> getAdvancedReport(
    int shopId,
    String startDate,
    String endDate,
  ) async {
    try {
      await AuthGuard.checkAndRefreshIfNeeded();
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
        if (AuthGuard.isUnauthorized(response.statusCode)) {
          await AuthGuard.handleUnauthorized();
        }
        print("Advanced Report API Error: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Advanced Report API Exception: $e");
      return null;
    }
  }

  // ✅ ฟังก์ชันดึงรายชื่อลูกหนี้แยกตามสถานะอายุหนี้ (สำหรับ popup กดดูรายละเอียด)
  static Future<AgingReportDetail?> getAgingReportDetail(
    int shopId,
    String endDate,
  ) async {
    try {
      await AuthGuard.checkAndRefreshIfNeeded();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final Uri url = Uri.parse(
        "${AppConfig.baseUrl}/api/dashboard/aging-report-detail?shop_id=$shopId&end_date=$endDate",
      );

      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return AgingReportDetail.fromJson(data['aging_report_detail'] ?? {});
      } else {
        if (AuthGuard.isUnauthorized(response.statusCode)) {
          await AuthGuard.handleUnauthorized();
        }
        print("Aging Report Detail API Error: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Aging Report Detail API Exception: $e");
      return null;
    }
  }
}
