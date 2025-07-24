import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';
import 'customer_list_screen.dart';
import 'order_list_screen.dart';

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
      // Chuyến thăm
      final visitsSnap = await FirebaseFirestore.instance
          .collection('visits')
          .where('userId', isEqualTo: user.uid)
          .where('visitDate', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .get();

      // Đơn hàng
      final ordersSnap = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .get();

      // Thanh toán (dùng collection 'payment' thay vì 'payments' nếu đúng với app của bạn)
      final paymentsSnap = await FirebaseFirestore.instance
          .collection('payment')
          .where('userId', isEqualTo: user.uid)
          .where('paymentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .get();

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
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
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
        title: const Text('Trang chủ', style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
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
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.blue[100],
                            child: const Icon(Icons.person,
                                size: 32, color: Colors.blue),
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
                      _buildStatCard('Chuyến thăm', visitsToday,
                          Icons.location_on, Colors.blue),
                      const SizedBox(width: 8),
                      _buildStatCard('Đơn hàng', ordersToday,
                          Icons.shopping_cart, Colors.orange),
                      const SizedBox(width: 8),
                      _buildStatCard('Thanh toán', paymentsToday,
                          Icons.payments, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Today's route list
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tuyến hôm nay',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          todayRoutes.isEmpty
                              ? const Text('Không có tuyến nào cho hôm nay.',
                                  style: TextStyle(color: Colors.grey))
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: todayRoutes.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, i) {
                                    final route = todayRoutes[i];
                                    return ListTile(
                                      leading: const Icon(Icons.store,
                                          color: Colors.blue),
                                      title: Text(route['customerName'] ??
                                          'Khách hàng'),
                                      subtitle: Text(route['address'] ?? ''),
                                      trailing: Text(route['status'] ?? '',
                                          style: const TextStyle(
                                              color: Colors.grey)),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Start trip button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _startTrip,
                      icon: const Icon(Icons.directions_run),
                      label: const Text('Bắt đầu chuyến đi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
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

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const CustomBottomNavBar(
      {super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: const Color(0xFF2563EB),
      unselectedItemColor: Colors.black,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.apps), label: 'Trang chủ'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Khách hàng'),
        BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard), label: 'Đơn hàng'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'KPI'),
        BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Thêm'),
      ],
      type: BottomNavigationBarType.fixed,
    );
  }
}
  }
}
