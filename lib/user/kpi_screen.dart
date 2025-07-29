import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class KpiScreen extends StatefulWidget {
  const KpiScreen({Key? key}) : super(key: key);

  @override
  State<KpiScreen> createState() => _KpiScreenState();
}

class _KpiScreenState extends State<KpiScreen> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  // Chỉ tiêu mặc định
  final double targetRevenue = 200000000;
  final int targetOrderCount = 200;
  final int targetAso = 180;

  // Dữ liệu động
  double achievedRevenue = 0;
  int achievedOrderCount = 0;
  int achievedAso = 0;
  int uniqueCustomerCount = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchKpiData();
  }

  Future<void> _fetchKpiData() async {
    setState(() => isLoading = true);
    achievedRevenue = 0;
    achievedOrderCount = 0;
    achievedAso = 0;
    uniqueCustomerCount = 0;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final start = DateTime(selectedYear, selectedMonth, 1);
      final end = DateTime(selectedYear, selectedMonth + 1, 1)
          .subtract(const Duration(seconds: 1));
      final ordersSnap = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('orderDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();
      achievedOrderCount = ordersSnap.docs.length;
      final customerIds = <String>{};
      double totalRevenue = 0;
      for (final doc in ordersSnap.docs) {
        final data = doc.data();
        final items = data['items'] as List<dynamic>? ?? [];
        for (final item in items) {
          final quantity = (item['quantity'] ?? 0) as num;
          final unitPrice = (item['unitPrice'] ?? 0) as num;
          totalRevenue += quantity * unitPrice;
        }
        if (data['customerId'] != null) {
          customerIds.add(data['customerId'].toString());
        } else if (data['customer'] != null && data['customer'] is Map) {
          final customer = data['customer'] as Map;
          if (customer['id'] != null)
            customerIds.add(customer['id'].toString());
        }
      }
      achievedRevenue = totalRevenue;
      uniqueCustomerCount = customerIds.length;
      achievedAso = uniqueCustomerCount > 0
          ? (achievedRevenue ~/ uniqueCustomerCount)
          : 0;
    } catch (e) {
      debugPrint('Lỗi lấy dữ liệu KPI: $e');
    }
    setState(() => isLoading = false);
  }

  Future<void> _pickMonthYear() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(selectedYear, selectedMonth),
      firstDate: DateTime(now.year - 5, 1),
      lastDate: DateTime(now.year + 1, 12),
      helpText: 'Chọn tháng/năm',
      fieldLabelText: 'Tháng/Năm',
      fieldHintText: 'mm/yyyy',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      selectableDayPredicate: (date) => date.day == 1,
    );
    if (picked != null) {
      setState(() {
        selectedMonth = picked.month;
        selectedYear = picked.year;
      });
      _fetchKpiData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: const Text('Tổng quan KPI',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: _pickMonthYear,
            icon: const Icon(Icons.calendar_today, color: Colors.black),
            label: Text(
              'Tháng ${selectedMonth.toString().padLeft(2, '0')}/$selectedYear',
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Text(
                      'Tháng ${selectedMonth.toString().padLeft(2, '0')} - $selectedYear',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(height: 16),
                _buildKpiCard(
                  title: 'Doanh số tháng $selectedMonth',
                  percent: achievedRevenue / targetRevenue > 1
                      ? 1
                      : achievedRevenue / targetRevenue,
                  percentText:
                      '${((achievedRevenue / targetRevenue) * 100).toStringAsFixed(0)}%',
                  color: Colors.orange,
                  target: NumberFormat('#,###').format(targetRevenue),
                  achieved: NumberFormat('#,###').format(achievedRevenue),
                  remain: NumberFormat('#,###').format(
                      targetRevenue - achievedRevenue < 0
                          ? 0
                          : targetRevenue - achievedRevenue),
                ),
                _buildKpiCard(
                  title: 'Sản lượng tháng $selectedMonth',
                  percent: achievedOrderCount / targetOrderCount > 1
                      ? 1
                      : achievedOrderCount / targetOrderCount,
                  percentText:
                      '${((achievedOrderCount / targetOrderCount) * 100).toStringAsFixed(0)}%',
                  color: Colors.orange,
                  target: NumberFormat('#,###').format(targetOrderCount),
                  achieved: NumberFormat('#,###').format(achievedOrderCount),
                  remain: NumberFormat('#,###').format(
                      targetOrderCount - achievedOrderCount < 0
                          ? 0
                          : targetOrderCount - achievedOrderCount),
                ),
                _buildKpiCard(
                  title: 'ASO tháng $selectedMonth',
                  percent:
                      achievedAso / targetAso > 1 ? 1 : achievedAso / targetAso,
                  percentText:
                      '${((achievedAso / targetAso) * 100).toStringAsFixed(0)}%',
                  color: Colors.orange,
                  target: NumberFormat('#,###').format(targetAso),
                  achieved: NumberFormat('#,###').format(achievedAso),
                  remain: NumberFormat('#,###').format(
                      targetAso - achievedAso < 0
                          ? 0
                          : targetAso - achievedAso),
                ),
              ],
            ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required double percent,
    required String percentText,
    required Color color,
    required String target,
    required String achieved,
    required String remain,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircularPercentIndicator(
              radius: 38,
              lineWidth: 7,
              percent: percent,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(percentText,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: color)),
                  Text('Tiến độ',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              progressColor: color,
              backgroundColor: Colors.grey[200]!,
              circularStrokeCap: CircularStrokeCap.round,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: Text('Chỉ tiêu')),
                      Text(target,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: Text('Thực đạt')),
                      Text(achieved,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: Text('Còn lại')),
                      Text(remain,
                          style: TextStyle(fontWeight: FontWeight.bold)),
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
