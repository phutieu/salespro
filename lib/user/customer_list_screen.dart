import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'custom_bottom_nav_bar.dart' as nav;
import 'home_screen.dart';
import 'order_list_screen.dart';
import 'dialogs/add_customer_dialog.dart';
import 'screens/customer_detail_screen.dart';
import 'screens/orthers_scren.dart';
import 'kpi_screen.dart';

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

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  int _selectedIndex = 1;

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
        screen = const OrdersScreen();
        break;
      case 4:
        screen = const KpiScreen();
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
      appBar: AppBar(
        title: const Text('Danh sách khách hàng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.green),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const AddCustomerDialog(),
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF6F6F6),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm khách hàng ...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                // TODO: Lọc danh sách theo tên/mã
              },
            ),
          ),
          // Tổng số khách hàng
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('customers').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tổng ${docs.length} KH',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              );
            },
          ),
          // Danh sách khách hàng
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('customers')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('Chưa có khách hàng nào'));
                }
                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildCustomerCard(data);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: nav.CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> data) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerDetailScreen(
              customerId: data['id'] ?? '',
              customerData: data,
            ),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Ảnh đại diện
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.store, size: 32, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              // Thông tin khách hàng
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          data['storeName'] ?? 'Tên KH',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          data['code'] != null ? '- ${data['code']}' : '',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            data['address'] ?? '',
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          data['phoneNumber'] ?? '',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black87),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Nút/thông tin phụ
              Column(
                children: [
                  InkWell(
                    onTap: () async {
                      try {
                        final docId = data['id'] ?? '';
                        if (docId.isNotEmpty) {
                          final visited = data['visited'] ?? false;
                          await FirebaseFirestore.instance
                              .collection('customers')
                              .doc(docId)
                              .update({'visited': !visited});
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (data['visited'] ?? false)
                            ? Colors.green[100]
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (data['visited'] ?? false) ? 'Đã thăm' : 'Chưa thăm',
                        style: TextStyle(
                          fontSize: 12,
                          color: (data['visited'] ?? false)
                              ? Colors.green[800]
                              : Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(Icons.navigation, color: Color(0xFF2563EB), size: 24),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
