import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Imports API และ Model ---
import '../../../api/api_debtor.dart';
import '../../../model/response/debtor_response.dart';
import 'package:eazy_store/page/debt/debtPayment/debt_payment.dart';

class DebtLedgerController extends GetxController {
  // --- ตัวแปร State ---
  var selectedIndex = 3.obs;
  final searchController = TextEditingController();

  var originalDebtors = <DebtorResponse>[].obs; 
  var allDebtors = <DebtorResponse>[].obs; 
  var searchResults = <DebtorResponse>[].obs;

  var isSearchEmpty = true.obs;
  var isLoading = true.obs;
  var isSearching = false.obs;
  var showDropdown = false.obs;
  var currentShopId = 1.obs;

  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var itemsPerPage = 10.obs;
  var totalItems = 0.obs;

   var currentIndex = 0.obs;
  
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    initialData();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    searchController.dispose();
    super.onClose();
  }

  Future<void> initialData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    currentShopId.value = prefs.getInt('shopId') ?? 1;
    fetchAllDebtors();
  }

  // --- ฟังก์ชันดึงลูกหนี้ทั้งหมด ---
  Future<void> fetchAllDebtors() async {
    isLoading.value = true;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      currentShopId.value = prefs.getInt('shopId') ?? 1;

      // ส่งค่า page, limit และ search ไปที่ API
      var result = await ApiDebtor.getDebtorsByShop(
        currentShopId.value,
        page: currentPage.value,
        limit: itemsPerPage.value,
        search: searchController.text, 
      );

      if (result is DebtorPagedResponse) {
        allDebtors.assignAll(result.items);
        totalPages.value = result.totalPages;
        totalItems.value = result.totalItems;
      } else if (result is List<DebtorResponse>) {
        allDebtors.assignAll(result);
      }
    } catch (e) {
      print("Error loading debtors: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> goToPaymentScreen(DebtorResponse debtor) async {
    final result = await Get.to(() => DebtPaymentScreen(debtor: debtor));

    if (result == true) {
      print("Payment Success! Refreshing list...");
      searchController.clear(); 
      fetchAllDebtors(); 
    }
  }

  void changePage(int page) {
    if (page >= 1 && page <= totalPages.value) {
      currentPage.value = page;
      fetchAllDebtors();
    }
  }

  void updateLimit(int limit) {
    itemsPerPage.value = limit;
    currentPage.value = 1; // รีเซ็ตไปหน้าแรก
    fetchAllDebtors();
  }

  // --- ฟังก์ชันค้นหา (Search) ---
  void onSearchChanged(String keyword) {
    isSearchEmpty.value = keyword.isEmpty;
    
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      currentPage.value = 1; // เริ่มค้นหาจากหน้าแรกเสมอ
      fetchAllDebtors();
    });
  }

  void selectFromDropdown(DebtorResponse debtor) {
    searchController.text = debtor.name; 
    allDebtors.assignAll([debtor]); 
    showDropdown.value = false; 
    FocusManager.instance.primaryFocus?.unfocus(); // หุบคีย์บอร์ด
  }

  void clearSearch() {
    searchController.clear();
    onSearchChanged(""); 
    isSearchEmpty.value = true;
  }

  void onItemTapped(int index) {
    selectedIndex.value = index;
  }

  void changeTab(int index) {
    currentIndex.value = index;
  }
}