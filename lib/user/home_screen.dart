import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';
import 'customer_list_screen.dart';
import 'order_list_screen.dart';
import 'custom_bottom_nav_bar.dart';
import 'screens/orthers_scren.dart';
import 'payment_sreen.dart';
import 'kpi_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = '';
  String userRole = '';
  String checkInStatus = 'IN';
  String checkInTime = '--:--';
  String checkOutTime = '--:--';
  int visitsToday = 0;
  int ordersToday = 0;
  int paymentsToday = 0;
  double totalAmountDue = 0.0;
  int pendingPayments = 0;
  List<Map<String, dynamic>> todayRoutes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await _fetchUserInfo();
    await _fetchCheckIn();
    await _fetchStats();
    await _fetchTodayRoutes();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data() ?? {};
      setState(() {
        userName = data['displayName'] ?? data['name'] ?? user.email ?? '';
        userRole = data['role'] ?? 'Nhân viên';
      });
    }
  }

  Future<void> _fetchCheckIn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final doc = await FirebaseFirestore.instance
        .collection('user_checkins')
        .doc('${user.uid}_$dateStr')
        .get();
    final data = doc.data() ?? {};
    setState(() {
      checkInTime = data['start'] ?? '--:--';
      checkOutTime = data['end'] ?? '--:--';
      checkInStatus = (data['start'] == null) ? 'IN' : 'OUT';
    });
  }

  Future<void> _handleCheckInOut() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final docRef = FirebaseFirestore.instance
        .collection('user_checkins')
        .doc('${user.uid}_$dateStr');
    final doc = await docRef.get();
    if (!doc.exists || (doc.data()?['start'] == null)) {
      // Check-in IN: lưu thời gian bắt đầu
      await docRef.set({'start': timeStr}, SetOptions(merge: true));
      setState(() {
        checkInTime = timeStr;
        checkInStatus = 'OUT';
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Điểm danh IN thành công!')));
    } else {
      // Check-in OUT: lưu thời gian kết thúc
      await docRef.set({'end': timeStr}, SetOptions(merge: true));
      setState(() {
        checkOutTime = timeStr;
        checkInStatus = 'IN';
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Điểm danh OUT thành công!')));
    }
  }

  Future<void> _fetchStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    try {
      final visitsSnap = await FirebaseFirestore.instance
          .collection('visits')
          .where('userId', isEqualTo: user.uid)
          .where('visitDate', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .get();

      final ordersSnap = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .get();

      final paymentsSnap = await FirebaseFirestore.instance
          .collection('payments')
          .where('userId', isEqualTo: user.uid)
          .where('paymentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .get();

      // Tính toán dữ liệu thanh toán
      await _fetchPaymentData();

      setState(() {
        visitsToday = visitsSnap.docs.length;
        ordersToday = ordersSnap.docs.length;
        paymentsToday = paymentsSnap.docs.length;
      });
    } catch (e) {
      debugPrint('Lỗi truy vấn Firestore: $e');
      setState(() {
        visitsToday = 0;
        ordersToday = 0;
        paymentsToday = 0;
      });
    }
  }

  Future<void> _fetchPaymentData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Lấy tất cả orders của user
      final ordersSnap = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .get();

      // Lấy tất cả payments
      final paymentsSnap =
          await FirebaseFirestore.instance.collection('payments').get();

      // Tạo map payments theo orderId
      final paymentsMap = <String, List<Map<String, dynamic>>>{};
      for (final doc in paymentsSnap.docs) {
        final data = doc.data();
        final orderId = data['orderId'] as String?;
        if (orderId != null) {
          paymentsMap.putIfAbsent(orderId, () => []).add(data);
        }
      }

      double totalDue = 0.0;
      int pendingCount = 0;

      // Tính toán số tiền còn nợ
      for (final doc in ordersSnap.docs) {
        final orderData = doc.data();
        final orderId = doc.id;

        // Tính tổng tiền đơn hàng
        double orderTotal = 0.0;
        final items = orderData['items'] as List<dynamic>? ?? [];
        for (final item in items) {
          final quantity = (item['quantity'] ?? 0) as num;
          final unitPrice = (item['unitPrice'] ?? 0) as num;
          orderTotal += quantity * unitPrice;
        }

        // Tính số tiền đã thanh toán
        double paidAmount = 0.0;
        final orderPayments = paymentsMap[orderId] ?? [];
        for (final payment in orderPayments) {
          paidAmount += (payment['amount'] ?? 0) as num;
        }

        // Tính số tiền còn nợ
        final amountDue = orderTotal - paidAmount;
        if (amountDue > 0) {
          totalDue += amountDue;
          pendingCount++;
        }
      }

      setState(() {
        totalAmountDue = totalDue;
        pendingPayments = pendingCount;
      });
    } catch (e) {
      debugPrint('Lỗi tính toán dữ liệu thanh toán: $e');
      setState(() {
        totalAmountDue = 0.0;
        pendingPayments = 0;
      });
    }
  }

  Future<void> _fetchTodayRoutes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final snap = await FirebaseFirestore.instance
        .collection('routes')
        .where('userId', isEqualTo: user.uid)
        .where('date', isEqualTo: dateStr)
        .get();
    setState(() {
      todayRoutes = snap.docs.map((e) => e.data()).toList();
    });
  }

  void _startTrip() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Bắt đầu chuyến đi!')));
    // Thêm logic bắt đầu chuyến đi nếu cần
  }

  int _selectedIndex = 0;
  void _onNavTap(int index) {
    if (index == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CustomerListScreen()),
      );
    } else if (index == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const OrderListScreen()),
      );
    } else if (index == 3) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const OrdersScreen()),
      );
    } else if (index == 4) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const KpiScreen()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget _buildVisitCard() {
    return Expanded(
      child: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('customers')
            .where('visited', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          int count = 0;
          if (snapshot.hasData) {
            count = snapshot.data!.docs.length;
          }
          return InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CustomerListScreen()),
              );
            },
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Icon(Icons.location_on, color: Colors.blue, size: 28),
                    const SizedBox(height: 4),
                    Text(count.toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 2),
                    const Text('Chuyến thăm',
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard() {
    return Expanded(
      child: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          int count = 0;
          if (snapshot.hasData) {
            count = snapshot.data!.docs.length;
          }
          return InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OrderListScreen()),
              );
            },
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Icon(Icons.shopping_cart, color: Colors.orange, size: 28),
                    const SizedBox(height: 4),
                    Text(count.toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 2),
                    const Text('Đơn hàng',
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('', style: TextStyle(color: Colors.black)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // User info
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              _showLogoutDialog();
                            },
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.blue[100],
                              child: const Icon(Icons.person,
                                  size: 32, color: Colors.blue),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(userName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18)),
                                Text(userRole,
                                    style: const TextStyle(color: Colors.grey)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text('$dateStr  $timeStr',
                                        style: const TextStyle(
                                            fontSize: 13, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Check-in/Check-out
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Điểm danh',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text('IN: ',
                                        style: TextStyle(color: Colors.green)),
                                    Text(checkInTime,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 16),
                                    const Text('OUT: ',
                                        style: TextStyle(color: Colors.red)),
                                    Text(checkOutTime,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _handleCheckInOut,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: checkInStatus == 'IN'
                                  ? Colors.green
                                  : Colors.red,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(checkInStatus),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Quick stats
                  Row(
                    children: [
                      _buildVisitCard(),
                      const SizedBox(width: 8),
                      _buildOrderCard(),
                      const SizedBox(width: 8),
                      _buildPaymentCard(),
                    ],
                  ),
                ],
              ),
            ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(value.toString(),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Expanded(
      child: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .snapshots(),
        builder: (context, orderSnapshot) {
          if (!orderSnapshot.hasData) {
            return _buildPaymentCardContent(0, 0);
          }
          return StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('payments')
                .where('userId',
                    isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, paymentSnapshot) {
              if (!paymentSnapshot.hasData) {
                return _buildPaymentCardContent(0, 0);
              }
              // Tạo map payments theo orderId
              final paymentsMap = <String, double>{};
              for (final doc in paymentSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final orderId = data['orderId'] as String?;
                final amount = (data['amount'] ?? 0) as num;
                if (orderId != null) {
                  paymentsMap[orderId] = (paymentsMap[orderId] ?? 0) + amount;
                }
              }
              double totalDue = 0.0;
              int pendingCount = 0;
              for (final doc in orderSnapshot.data!.docs) {
                final orderData = doc.data() as Map<String, dynamic>;
                final orderId = doc.id;
                double orderTotal = 0.0;
                final items = orderData['items'] as List<dynamic>? ?? [];
                for (final item in items) {
                  final quantity = (item['quantity'] ?? 0) as num;
                  final unitPrice = (item['unitPrice'] ?? 0) as num;
                  orderTotal += quantity * unitPrice;
                }
                final paidAmount = paymentsMap[orderId] ?? 0.0;
                final amountDue = orderTotal - paidAmount;
                if (amountDue > 0) {
                  totalDue += amountDue;
                  pendingCount++;
                }
              }
              return _buildPaymentCardContent(totalDue, pendingCount);
            },
          );
        },
      ),
    );
  }

  Widget _buildPaymentCardContent(double totalAmountDue, int pendingPayments) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PaymentScreen()),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(Icons.payments,
                  color: totalAmountDue > 0 ? Colors.red : Colors.green,
                  size: 28),
              const SizedBox(height: 4),
              Text(
                totalAmountDue > 0
                    ? '${(totalAmountDue / 1000).toStringAsFixed(0)}K'
                    : '0',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: totalAmountDue > 0 ? Colors.red : Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Thanh toán',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              if (pendingPayments > 0) ...[
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child:
                  const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

Widget _buildSalesRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        const Icon(Icons.chevron_right, size: 18),
      ],
    ),
  );
}
