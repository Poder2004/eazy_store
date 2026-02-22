import 'dart:convert';
import 'package:eazy_store/model/response/sales_summary_respone.dart';
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
}
