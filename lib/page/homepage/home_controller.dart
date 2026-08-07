import 'package:eazy_store/api/api_dashboad.dart';
import 'package:eazy_store/model/response/advanced_report_response.dart';
import 'package:eazy_store/model/response/sales_summary_respone.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeController extends GetxController {
 var currentIndex = 0.obs;
  var shopName = "กำลังโหลด...".obs;
  var shopId = 0.obs;

  // ตัวแปรสำหรับยอดขาย
  var dailyTotal = 0.0.obs; // เก็บเป็นตัวเลขเพื่อเปรียบเทียบ
  var actualPaid = "0".obs;
  var debtAmount = "0".obs;
  var isSalesLoading = true.obs;

  // Logic สำหรับสีและทิศทางยอดขาย
  var isTrendUp = true.obs; 

  @override
  void onInit() {
    super.onInit();
    loadShopData();
  }

  void loadShopData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    shopId.value = prefs.getInt('shopId') ?? 0;
    shopName.value = prefs.getString('shopName') ?? "ยังไม่ได้เลือกร้าน";
    if (shopId.value != 0) fetchTodaySales();
  }

  Future<void> fetchTodaySales() async {
    isSalesLoading.value = true;
    try {
      DateTime now = DateTime.now();
      String todayStr = DateFormat('yyyy-MM-dd').format(now);

      // ดึงข้อมูลยอดขาย + รายงานหนี้ (เพื่อหักลบยอดที่ลูกหนี้จ่ายคืนแล้ว)
      final SalesSummaryModel? summary = await ApiDashboad.getSalesSummary(
        shopId.value,
        todayStr,
        todayStr,
      );
      final AdvancedReportResponse? advancedData =
          await ApiDashboad.getAdvancedReport(shopId.value, todayStr, todayStr);

      if (summary != null) {
        final f = NumberFormat('#,##0');
        dailyTotal.value = summary.totalRevenue;
        actualPaid.value = f.format(summary.actualPaid);

        // ยอดค้างชำระ = ยอดหนี้คงค้างทั้งหมดของร้านนี้ (รวมทุกลูกหนี้ ไม่จำกัดแค่วันนี้)
        // ใช้ debtSummary.totalOutstanding ซึ่งดึงจาก SUM(debtors.current_debt) ตรงๆ
        // เป็นยอดที่อัปเดตแบบเรียลไทม์ทุกครั้งที่มีการขายค้างชำระหรือลูกหนี้มาจ่ายคืน
        // (ไม่ใช้ summary.debtAmount เพราะเป็นแค่ยอดหนี้ที่เกิดใหม่วันนี้ ไม่ใช่ยอดรวมทั้งหมด)
        double totalDebt = advancedData?.debtSummary.totalOutstanding ?? summary.debtAmount;
        debtAmount.value = f.format(totalDebt);

        // --- Logic เปรียบเทียบ ---
        // สมมติ: ถ้าวันนี้มียอด > 0 และไม่มีหนี้ค้างอยู่ ให้ถือว่าเป็นเทรนด์ขาขึ้น (สีเขียว)
        // หรือคุณสามารถนำไปเทียบกับค่าเฉลี่ย/ยอดเมื่อวานได้ที่นี่
        isTrendUp.value = summary.totalRevenue > 0 && totalDebt == 0;
      }
    } catch (e) {
      print("Error fetching sales: $e");
    } finally {
      isSalesLoading.value = false;
    }
  }

  // Getter สำหรับแสดงผลยอดขายแบบ Format แล้ว
  String get formattedTotal => NumberFormat('#,##0').format(dailyTotal.value);

  void changeTab(int index) {
    currentIndex.value = index;
  }
}