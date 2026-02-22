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
      final result = await ApiDebtor.getDebtorsByShop(currentShopId.value);
      originalDebtors.assignAll(result); 
      allDebtors.assignAll(result); 
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

  // --- ฟังก์ชันค้นหา (Search) ---
  void onSearchChanged(String keyword) {
     isSearchEmpty.value = keyword.isEmpty;
    if (keyword.isEmpty) {
      searchResults.clear();
      showDropdown.value = false;
      allDebtors.assignAll(originalDebtors); 
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      isSearching.value = true;
      try {
        final results = await ApiDebtor.searchDebtor(keyword);
        searchResults.assignAll(results);
        showDropdown.value = true;
      } catch (e) {
        print("Error searching: $e");
        searchResults.clear();
      } finally {
        isSearching.value = false;
      }
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
}