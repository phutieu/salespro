import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'custom_bottom_nav_bar.dart' as nav;
import 'home_screen.dart';
import 'customer_list_screen.dart';
import 'checkout_screen.dart';

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

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final Map<String, int> _quantities = {};
  final Map<String, String> _units = {};
  String _search = '';
  int _selectedIndex = 2;

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
      appBar: AppBar(
        title: const Text('Danh sách hàng hoá'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF6F6F6),
      body: Column(
        children: [
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm ...',
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
                setState(() {
                  _search = value.trim().toLowerCase();
                });
              },
            ),
          ),
          // Danh sách sản phẩm
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final code = (data['id'] ?? '').toString().toLowerCase();
                  return _search.isEmpty ||
                      name.contains(_search) ||
                      code.contains(_search);
                }).toList();
                if (docs.isEmpty) {
                  return const Center(child: Text('Không có sản phẩm nào'));
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;
                          final id = docs[index].id;
                          final price = (data['salePrice'] ?? 0) as num;
                          final quantity = _quantities[id] ?? 0;
                          final unit = _units[id] ?? (data['unit'] ?? 'HỘP');
                          final total = price * quantity;
                          return Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${data['name'] ?? ''} - ${data['id'] ?? ''}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      DropdownButton<String>(
                                        value: unit,
                                        items: [
                                          (data['unit'] ?? 'HỘP') as String
                                        ]
                                            .map((u) =>
                                                DropdownMenuItem<String>(
                                                    value: u, child: Text(u)))
                                            .toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _units[id] = value!;
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 12),
                                      const Text('Số lượng:'),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.remove_circle_outline),
                                        onPressed: quantity > 0
                                            ? () => setState(() =>
                                                _quantities[id] = quantity - 1)
                                            : null,
                                      ),
                                      Container(
                                        width: 32,
                                        alignment: Alignment.center,
                                        child: Text('$quantity',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.add_circle_outline),
                                        onPressed: () => setState(() =>
                                            _quantities[id] = quantity + 1),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Text('Tồn kho NPP:'),
                                      const SizedBox(width: 4),
                                      Text('${data['stockQuantity'] ?? 0}'),
                                      const Spacer(),
                                      const Text('Nhập giá:'),
                                      const SizedBox(width: 4),
                                      Container(
                                        width: 100,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.grey[400]!),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          NumberFormat('#,###').format(price),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  Row(
                                    children: [
                                      const Text('Tổng tiền:',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      Text(NumberFormat('#,###').format(total)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Thanh dưới cùng
                    Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24)),
                              ),
                              onPressed: () {
                                final cartItems = <Map<String, dynamic>>[];
                                for (final entry in _quantities.entries) {
                                  if (entry.value > 0) {
                                    final doc = docs
                                        .firstWhere((d) => d.id == entry.key);
                                    final data =
                                        doc.data() as Map<String, dynamic>;
                                    cartItems.add({
                                      'id': doc.id,
                                      'name': data['name'],
                                      'price': data['salePrice'],
                                      'quantity': entry.value,
                                    });
                                  }
                                }
                                if (cartItems.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Vui lòng chọn ít nhất 1 sản phẩm!')),
                                  );
                                  return;
                                }
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CheckoutScreen(cartItems: cartItems),
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                      '${_quantities.values.fold<int>(0, (sum, q) => sum + (q > 0 ? 1 : 0))} Sản phẩm'),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.shopping_cart_outlined),
                                  const SizedBox(width: 8),
                                  Text(
                                      '${_quantities.values.fold<int>(0, (sum, q) => sum + q)}'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
}
