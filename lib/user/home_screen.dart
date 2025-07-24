import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'customer_list_screen.dart';
import 'order_list_screen.dart';
import 'custom_bottom_nav_bar.dart';
import 'login.dart';

// Dummy screens for navigation
class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text('Đơn hàng')));
}

class KPIScreen extends StatelessWidget {
  const KPIScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text('KPI')));
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: const Text('Thêm')));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;

  // Dữ liệu động
  int salesToday = 0;
  int customersVisited = 0;
  int customersOnRoute = 0;
  int ordersCreated = 0;
  int totalCustomers = 0;
  String lastUpdate = '';
  String userName = 'Chào bạn';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          userName =
              data['displayName'] ?? data['name'] ?? user.email ?? 'Chào bạn';
        });
      } else {
        setState(() {
          userName = user.email ?? 'Chào bạn';
        });
      }
    }
  }

  Future<void> _fetchData() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final ordersSnap = await FirebaseFirestore.instance
        .collection('orders')
        .where('orderDate', isGreaterThanOrEqualTo: today.toIso8601String())
        .get();
    setState(() {
      ordersCreated = ordersSnap.docs.length;
      salesToday = ordersSnap.docs.fold(0, (sum, doc) {
        final data = doc.data() as Map<String, dynamic>;
        return sum + ((data['totalAmount'] ?? 0) as num).toInt();
      });
      lastUpdate =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    });
    final customersSnap =
        await FirebaseFirestore.instance.collection('customers').get();
    setState(() {
      totalCustomers = customersSnap.docs.length;
      customersVisited = customersSnap.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['visitedToday'] == true;
      }).length;
      customersOnRoute = customersSnap.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['onRouteAndOrdered'] == true;
      }).length;
    });
  }

  void _onNavTap(int index) {
    if (index == _selectedIndex) return;
    Widget screen;
    switch (index) {
      case 0:
        screen = const HomeScreen();
        break;
      case 1:
        screen = const CustomerListScreen();
        break;
      case 2:
        screen = const OrderListScreen();
        break;
      case 3:
        screen = const KPIScreen();
        break;
      case 4:
        screen = const MoreScreen();
        break;
      default:
        screen = const HomeScreen();
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A6CF1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
      body: Column(
        children: [
          // Card thông tin user + check-in
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Expanded(
                            child: Text(
                                'Check-in đầu ngày / cuối ngày  --:-- / --:--')),
                      ],
                    ),
                    Row(
                      children: const [
                        Expanded(
                            child: Text(
                                'Ghé thăm KH đầu / KH cuối  --:-- / --:--')),
                      ],
                    ),
                    Row(
                      children: const [
                        Expanded(child: Text('Thời gian CSKH (Phút)')),
                        Text('0'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Check-in'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Card chỉ số bán hàng
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Chỉ số bán hàng',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh,
                              color: Color(0xFF2563EB)),
                          onPressed: _fetchData,
                        ),
                      ],
                    ),
                    TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFF2563EB),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.black,
                      tabs: const [
                        Tab(child: Text('Hôm nay')),
                        Tab(child: Text('Tháng này')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Dữ liệu cập nhật đến: $lastUpdate'),
                    const SizedBox(height: 8),
                    _buildSalesIndex(),
                  ],
                ),
              ),
            ),
          ),
          // Card KPI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Tiến độ thực hiện KPI',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Xem chi tiết'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.insert_chart,
                              size: 60, color: Colors.grey[300]),
                          const SizedBox(height: 8),
                          const Text('Chưa có dữ liệu KPI',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildSalesIndex() {
    return Column(
      children: [
        _buildSalesRow('Doanh số đặt hàng từ SFA', salesToday.toString()),
        _buildSalesRow('KH đã ghé thăm', '$customersVisited/$totalCustomers'),
        _buildSalesRow(
            'KH đúng tuyến có mua hàng', customersOnRoute.toString()),
        _buildSalesRow('Đơn hàng tạo từ SFA', ordersCreated.toString()),
      ],
    );
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
