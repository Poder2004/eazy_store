import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../model/response/debtor_response.dart';
import '../../../model/request/debtor_history_model.dart';
import '../../../model/response/debtor_history_model.dart';
import 'debtor_detail_controller.dart';

class DebtorDetailScreen extends StatefulWidget {
  final DebtorResponse debtor;

  const DebtorDetailScreen({super.key, required this.debtor});

  @override
  State<DebtorDetailScreen> createState() => _DebtorDetailScreenState();
}

class _DebtorDetailScreenState extends State<DebtorDetailScreen> {
  final DebtorDetailController _controller = DebtorDetailController();

  @override
  void initState() {
    super.initState();
    _controller.init(widget.debtor);
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showImagePopup() {
    final debtor = _controller.currentDebtor;
    final hasImage = debtor.imgDebtor != null && debtor.imgDebtor!.trim().isNotEmpty;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: () {},
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: hasImage
                      ? InteractiveViewer(
                          child: Image.network(
                            debtor.imgDebtor!,
                            fit: BoxFit.contain,
                            loadingBuilder: (ctx, child, progress) => progress == null
                                ? child
                                : const SizedBox(
                                    width: 200,
                                    height: 200,
                                    child: Center(child: CircularProgressIndicator(color: Colors.white)),
                                  ),
                            errorBuilder: (ctx, _, __) => _buildImagePlaceholder(),
                          ),
                        )
                      : _buildImagePlaceholder(),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 200,
      height: 200,
      color: Colors.grey.shade800,
      child: Icon(Icons.person, size: 80, color: Colors.grey.shade400),
    );
  }

  void _showTopNotification(String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: MediaQuery.of(ctx).padding.top + 12,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isError ? Colors.red.shade700 : Colors.green.shade700,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () => entry.remove());
  }

  void _editDebtorInfo() {
    final nameController = TextEditingController(text: _controller.currentDebtor.name);
    final phoneController = TextEditingController(text: _controller.currentDebtor.phone);
    final addressController = TextEditingController(text: _controller.currentDebtor.address ?? "");
    final creditController = TextEditingController(
      text: _controller.currentDebtor.creditLimit.toStringAsFixed(0),
    );

    File? selectedImage;
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setStateSheet) {
          bool isLoading = false;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 8, 4),
                      child: Row(
                        children: [
                          const Text(
                            "แก้ไขข้อมูลลูกหนี้",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: Icon(Icons.close, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    // Photo picker
                    GestureDetector(
                      onTap: () async {
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setStateSheet(() => selectedImage = File(pickedFile.path));
                        }
                      },
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.blue.shade50,
                            backgroundImage: selectedImage != null
                                ? FileImage(selectedImage!) as ImageProvider
                                : (_controller.currentDebtor.imgDebtor != null &&
                                      _controller.currentDebtor.imgDebtor!.trim().isNotEmpty)
                                ? NetworkImage(_controller.currentDebtor.imgDebtor!)
                                : null,
                            child: (selectedImage == null &&
                                (_controller.currentDebtor.imgDebtor == null ||
                                    _controller.currentDebtor.imgDebtor!.trim().isEmpty))
                                ? Icon(Icons.person, size: 45, color: Colors.blue.shade300)
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Form fields
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        children: [
                          _buildFormField(nameController, "ชื่อ-นามสกุล", Icons.person_outline),
                          const SizedBox(height: 12),
                          _buildFormField(phoneController, "เบอร์โทรศัพท์", Icons.phone_outlined,
                              keyboardType: TextInputType.phone),
                          const SizedBox(height: 12),
                          _buildFormField(addressController, "ที่อยู่", Icons.home_outlined, maxLines: 2),
                          const SizedBox(height: 12),
                          _buildFormField(creditController, "วงเงินเครดิต (บาท)", Icons.credit_card_outlined,
                              keyboardType: TextInputType.number),
                        ],
                      ),
                    ),
                    // Save button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: isLoading
                              ? null
                              : () async {
                                  setStateSheet(() => isLoading = true);
                                  final bool success = await _controller.updateDebtorData(
                                    name: nameController.text,
                                    phone: phoneController.text,
                                    address: addressController.text,
                                    creditLimit: double.tryParse(creditController.text) ?? 0,
                                    imageFile: selectedImage,
                                  );
                                  if (sheetContext.mounted) {
                                    Navigator.pop(sheetContext);
                                  }
                                  if (success) {
                                    _showTopNotification("บันทึกข้อมูลสำเร็จ");
                                  } else {
                                    _showTopNotification("เกิดข้อผิดพลาดในการบันทึก", isError: true);
                                  }
                                },
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  "บันทึก",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade400, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("รายละเอียดลูกหนี้"),
          backgroundColor: Colors.white,
          elevation: 1,
          foregroundColor: Colors.black,
          bottom: const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: "หนี้ค้างชำระ"),
              Tab(text: "ประวัติการคืนเงิน"),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFF7F7F7),
        body: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.textScalerOf(
              context,
            ).clamp(minScaleFactor: 1.0, maxScaleFactor: 1.2),
          ),
          child: Column(
            children: [
              _buildProfileCard(),
              Expanded(
                child: TabBarView(
                  children: [
                    RefreshIndicator(
                      onRefresh: () => _controller.fetchAllData(),
                      child: ListView(
                        children: [
                          _buildSectionHeader(
                            icon: Icons.receipt_long,
                            title: "ประวัติการติดหนี้",
                            count: _controller.historyList.length,
                            color: Colors.orange,
                          ),
                          _buildHistoryList(),
                        ],
                      ),
                    ),
                    RefreshIndicator(
                      onRefresh: () => _controller.fetchAllData(),
                      child: ListView(
                        children: [
                          _buildSectionHeader(
                            icon: Icons.payments_outlined,
                            title: "ประวัติการจ่ายหนี้",
                            count: _controller.paymentList.length,
                            color: Colors.green,
                          ),
                          _buildPaymentHistoryList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          if (!_controller.isLoading && count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "$count รายการ",
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final debtor = _controller.currentDebtor;

    double percentUsed = debtor.creditLimit > 0
        ? (debtor.currentDebt / debtor.creditLimit)
        : 1.0;
    if (percentUsed > 1.0) percentUsed = 1.0;
    double availableCredit = debtor.creditLimit - debtor.currentDebt;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _showImagePopup,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.blue.shade50,
                      backgroundImage:
                          (debtor.imgDebtor != null &&
                              debtor.imgDebtor!.trim().isNotEmpty)
                          ? NetworkImage(debtor.imgDebtor!)
                          : null,
                      child:
                          (debtor.imgDebtor == null ||
                              debtor.imgDebtor!.trim().isEmpty)
                          ? const Icon(Icons.person, size: 40, color: Colors.blue)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(Icons.zoom_in, color: Colors.white, size: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debtor.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text(
                          debtor.phone,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            debtor.address ?? "ไม่ระบุที่อยู่",
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _editDebtorInfo,
                icon: const Icon(Icons.edit, size: 15),
                label: const Text("แก้ไข", style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  backgroundColor: Colors.blue.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.blue.shade200),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const Divider(height: 30),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "ยอดหนี้ปัจจุบัน ",
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      "${debtor.currentDebt.toStringAsFixed(0)} บาท",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentUsed,
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percentUsed > 0.8 ? Colors.red : Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "วงเงิน: ${debtor.creditLimit.toStringAsFixed(0)}",
                    style: TextStyle(color: Colors.grey[600],fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    "เครดิตคงเหลือ: ${availableCredit.toStringAsFixed(0)}",
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // แท็บ 1: ประวัติการติดหนี้
  // ──────────────────────────────────────────────

  Widget _buildHistoryList() {
    if (_controller.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_controller.historyList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                "ไม่พบประวัติการติดหนี้",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _controller.historyList.length,
      itemBuilder: (context, index) {
        final history = _controller.historyList[index];
        final bool isPaid = history.remainingAmount <= 0;
        return _buildDebtCard(history, isPaid);
      },
    );
  }

  Widget _buildDebtCard(DebtorHistoryResponse history, bool isPaid) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStatusBadge(isPaid),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 5),
                  Text(
                    history.date,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildAmountChip(
                    label: "ยอดบิล",
                    amount: history.totalAmount,
                    color: Colors.blue.shade700,
                    bgColor: Colors.blue.shade50,
                    icon: Icons.receipt,
                  ),
                  if (history.paidAmount > 0) ...[
                    const SizedBox(width: 8),
                    _buildAmountChip(
                      label: "จ่ายแล้ว",
                      amount: history.paidAmount,
                      color: Colors.green.shade700,
                      bgColor: Colors.green.shade50,
                      icon: Icons.payments,
                    ),
                  ],
                  if (!isPaid) ...[
                    const SizedBox(width: 8),
                    _buildAmountChip(
                      label: "ค้างบิลนี้",
                      amount: history.remainingAmount,
                      color: Colors.red.shade700,
                      bgColor: Colors.red.shade50,
                      icon: Icons.warning_amber_rounded,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        children: [
          Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "รายการสินค้า (${history.items.length} รายการ)",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...history.items.map((item) {
                  double pricePerUnit =
                      item.qty > 0 ? (item.price / item.qty) : 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade300,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: Text(
                            item.name,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          "${item.qty} ${item.unit}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "${pricePerUnit.toStringAsFixed(0)}฿",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "${item.price.toStringAsFixed(0)} ฿",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "รวมทั้งสิ้น",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "${history.totalAmount.toStringAsFixed(0)} บาท",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isPaid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPaid ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPaid ? Colors.green.shade300 : Colors.red.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPaid ? Icons.check_circle : Icons.access_time,
            size: 12,
            color: isPaid ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            isPaid ? "ชำระแล้ว" : "ค้างชำระ",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isPaid ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountChip({
    required String label,
    required double amount,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 11, color: color),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 10, color: color),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              "${amount.toStringAsFixed(0)}฿",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // แท็บ 2: ประวัติการจ่ายหนี้
  // ──────────────────────────────────────────────

  Widget _buildPaymentHistoryList() {
    if (_controller.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_controller.paymentList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                "ยังไม่มีประวัติการจ่ายหนี้",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _controller.paymentList.length,
      itemBuilder: (context, index) {
        final pay = _controller.paymentList[index];
        return _buildPaymentCard(pay);
      },
    );
  }

  Widget _buildPaymentCard(PaymentHistoryResponse pay) {
    final IconData methodIcon;
    final Color methodColor;

    if (pay.method.contains('โอน') ||
        pay.method.toLowerCase().contains('transfer') ||
        pay.method.toLowerCase().contains('bank')) {
      methodIcon = Icons.account_balance;
      methodColor = Colors.blue;
    } else if (pay.method.contains('สด') ||
        pay.method.toLowerCase().contains('cash')) {
      methodIcon = Icons.payments;
      methodColor = Colors.green;
    } else {
      methodIcon = Icons.payment;
      methodColor = Colors.purple;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ยอดที่ชำระ",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        "${pay.amountPaid.toStringAsFixed(0)} บาท",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            pay.date,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: methodColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: methodColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(methodIcon, size: 13, color: methodColor),
                      const SizedBox(width: 4),
                      Text(
                        pay.method,
                        style: TextStyle(
                          fontSize: 12,
                          color: methodColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        "บันทึกโดย: ${pay.recordedBy}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        "ยอดหนี้หลังชำระ: ",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        "${pay.remainingDebt.toStringAsFixed(0)} ฿",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: pay.remainingDebt > 0
                              ? Colors.orange.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
