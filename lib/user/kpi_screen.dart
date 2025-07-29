import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class KpiScreen extends StatefulWidget {
  const KpiScreen({super.key});

  @override
  State<KpiScreen> createState() => _KpiScreenState();
}

class _KpiScreenState extends State<KpiScreen> {
  String userName = '';
  int totalVisits = 0;
  int totalOrders = 0;
  double totalRevenue = 0.0;
  double totalPaid = 0.0;
  double totalDue = 0.0;
  List<Map<String, dynamic>> weeklyData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKpiData();
  }

  Future<void> _loadKpiData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Lấy thông tin user
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data() ?? {};
      userName =
          userData['displayName'] ?? userData['name'] ?? user.email ?? '';

      // Lấy dữ liệu visits
      final visitsSnap = await FirebaseFirestore.instance
          .collection('customers')
          .where('visited', isEqualTo: true)
          .get();

      // Lấy dữ liệu orders
      final ordersSnap = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .get();

      // Lấy dữ liệu payments
      final paymentsSnap = await FirebaseFirestore.instance
          .collection('payments')
          .where('userId', isEqualTo: user.uid)
          .get();

      // Tính toán dữ liệu
      totalVisits = visitsSnap.docs.length;
      totalOrders = ordersSnap.docs.length;

      // Tính tổng doanh thu và thanh toán
      double revenue = 0.0;
      double paid = 0.0;

      // Tính doanh thu từ orders
      for (final doc in ordersSnap.docs) {
        final orderData = doc.data();
        final items = orderData['items'] as List<dynamic>? ?? [];
        for (final item in items) {
          final quantity = (item['quantity'] ?? 0) as num;
          final unitPrice = (item['unitPrice'] ?? 0) as num;
          revenue += quantity * unitPrice;
        }
      }

      // Tính số tiền đã thanh toán
      for (final doc in paymentsSnap.docs) {
        final paymentData = doc.data();
        paid += (paymentData['amount'] ?? 0) as num;
      }

      // Tạo dữ liệu tuần
      await _generateWeeklyData();

      setState(() {
        totalRevenue = revenue;
        totalPaid = paid;
        totalDue = revenue - paid;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading KPI data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _generateWeeklyData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    List<Map<String, dynamic>> weekly = [];

    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      // Lấy orders cho ngày này
      final ordersSnap = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(date))
          .where('orderDate',
              isLessThan: Timestamp.fromDate(date.add(const Duration(days: 1))))
          .get();

      double dayRevenue = 0.0;
      for (final doc in ordersSnap.docs) {
        final orderData = doc.data();
        final items = orderData['items'] as List<dynamic>? ?? [];
        for (final item in items) {
          final quantity = (item['quantity'] ?? 0) as num;
          final unitPrice = (item['unitPrice'] ?? 0) as num;
          dayRevenue += quantity * unitPrice;
        }
      }

      weekly.add({
        'date': date,
        'day': DateFormat('E', 'vi_VN').format(date),
        'revenue': dayRevenue,
        'orders': ordersSnap.docs.length,
      });
    }

    setState(() {
      weeklyData = weekly;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('KPI', style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadKpiData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xin chào, $userName!',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Thống kê hiệu suất của bạn',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tổng quan
                  Row(
                    children: [
                      Expanded(
                        child: _buildKpiCard(
                          'Chuyến thăm',
                          totalVisits.toString(),
                          Icons.location_on,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildKpiCard(
                          'Đơn hàng',
                          totalOrders.toString(),
                          Icons.shopping_cart,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildKpiCard(
                          'Doanh thu',
                          '${NumberFormat.decimalPattern('vi_VN').format(totalRevenue)} ₫',
                          Icons.trending_up,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildKpiCard(
                          'Còn nợ',
                          '${NumberFormat.decimalPattern('vi_VN').format(totalDue)} ₫',
                          Icons.account_balance_wallet,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Biểu đồ doanh thu tuần
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Doanh thu tuần',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: weeklyData.isEmpty
                                    ? 100
                                    : weeklyData
                                            .map((e) => e['revenue'] as double)
                                            .reduce((a, b) => a > b ? a : b) *
                                        1.2,
                                barTouchData: BarTouchData(enabled: false),
                                titlesData: FlTitlesData(
                                  show: true,
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        if (value.toInt() >= 0 &&
                                            value.toInt() < weeklyData.length) {
                                          return Text(
                                            weeklyData[value.toInt()]['day'],
                                            style:
                                                const TextStyle(fontSize: 12),
                                          );
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          '${(value / 1000).toStringAsFixed(0)}K',
                                          style: const TextStyle(fontSize: 10),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups:
                                    weeklyData.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final data = entry.value;
                                  return BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY: data['revenue'] as double,
                                        color: Colors.blue,
                                        width: 20,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(4),
                                          topRight: Radius.circular(4),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Chi tiết tuần
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chi tiết tuần',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...weeklyData.map((dayData) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        dayData['day'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        '${NumberFormat.decimalPattern('vi_VN').format(dayData['revenue'])} ₫',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${dayData['orders']} đơn',
                                        style:
                                            TextStyle(color: Colors.grey[600]),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
