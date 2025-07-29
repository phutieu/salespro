import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:intl/intl.dart';
import '../../admin/models/order.dart' as modelOrder;
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/pdf_service.dart';
import '../custom_bottom_nav_bar.dart' as nav;
import '../home_screen.dart';
import '../customer_list_screen.dart';
import '../order_list_screen.dart';
import '../kpi_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _searchQuery = '';
  modelOrder.OrderStatus? _selectedStatus;
  final user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 3;

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

  Color _getStatusColor(modelOrder.OrderStatus status) {
    switch (status) {
      case modelOrder.OrderStatus.Pending:
        return Colors.orange;
      case modelOrder.OrderStatus.Confirmed:
        return Colors.blue;
      case modelOrder.OrderStatus.Delivered:
        return Colors.green;
      case modelOrder.OrderStatus.Cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(modelOrder.OrderStatus status) {
    switch (status) {
      case modelOrder.OrderStatus.Pending:
        return 'Chờ xác nhận';
      case modelOrder.OrderStatus.Confirmed:
        return 'Đã xác nhận';
      case modelOrder.OrderStatus.Delivered:
        return 'Đã giao';
      case modelOrder.OrderStatus.Cancelled:
        return 'Đã hủy';
    }
  }

  void _showOrderDetail(modelOrder.Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết đơn hàng'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thông tin khách hàng
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customer.storeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Địa chỉ: ${order.customer.address}'),
                    Text('SĐT: ${order.customer.phoneNumber}'),
                    Text(
                        'Ngày đặt: ${DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate)}'),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(order.status),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Danh sách sản phẩm
              const Text(
                'Danh sách sản phẩm:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...order.items.map((item) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                'Số lượng: ${item.quantity} ${item.product.unit}'),
                            Text(
                                'Giá: ${NumberFormat('#,###').format(item.unitPrice)}đ'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Thành tiền:'),
                            Text(
                              '${NumberFormat('#,###').format(item.quantity * item.unitPrice)}đ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
              const Divider(),
              // Tổng tiền
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng tiền:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '${NumberFormat('#,###').format(order.totalAmount)}đ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đang tạo hóa đơn PDF...')),
                );
                await PdfService.generateInvoice(order);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xuất hóa đơn thành công!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi xuất hóa đơn: $e')),
                );
              }
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Xuất hóa đơn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách đơn hàng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [],
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm và lọc
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm đơn hàng...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Tất cả'),
                        selected: _selectedStatus == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ...modelOrder.OrderStatus.values.map((status) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(_getStatusText(status)),
                              selected: _selectedStatus == status,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedStatus = selected ? status : null;
                                });
                              },
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Danh sách đơn hàng
          Expanded(
            child: StreamBuilder<firestore.QuerySnapshot>(
              stream: firestore.FirebaseFirestore.instance
                  .collection('orders')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Debug: in ra số lượng documents và user ID
                print('User ID: ${user?.uid}');
                print('Found ${snapshot.data!.docs.length} orders');

                // Debug: in ra tất cả documents để kiểm tra
                for (final doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  print('Document ID: ${doc.id}');
                  print('Document data: $data');
                  print('User ID in document: ${data['userId']}');
                  print('Current user ID: ${user?.uid}');
                  print('---');
                }

                // Kiểm tra nếu không có orders, thử query tất cả orders để debug
                if (snapshot.data!.docs.isEmpty) {
                  print('No orders found for user, checking all orders...');
                  return FutureBuilder<firestore.QuerySnapshot>(
                    future: firestore.FirebaseFirestore.instance
                        .collection('orders')
                        .get(),
                    builder: (context, allOrdersSnapshot) {
                      if (allOrdersSnapshot.hasData) {
                        print(
                            'Total orders in collection: ${allOrdersSnapshot.data!.docs.length}');
                        for (final doc in allOrdersSnapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          print('Order data: $data');
                        }
                      }
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Chưa có đơn hàng nào',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey)),
                          ],
                        ),
                      );
                    },
                  );
                }

                final orders = snapshot.data!.docs
                    .map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      print('Processing order: $data');
                      // Đảm bảo có id trong data
                      data['id'] = doc.id;
                      try {
                        return modelOrder.Order.fromMap(data);
                      } catch (e) {
                        print('Error parsing order: $e');
                        print('Order data: $data');
                        return null;
                      }
                    })
                    .where((order) => order != null)
                    .cast<modelOrder.Order>()
                    .toList();

                // Lọc theo user ID
                final userOrders = orders.where((order) {
                  // Kiểm tra nếu có userId trong data gốc
                  final doc =
                      snapshot.data!.docs.firstWhere((d) => d.id == order.id);
                  final originalData = doc.data() as Map<String, dynamic>;
                  final matches = originalData['userId'] == user?.uid;
                  print(
                      'Order ${order.id}: userId=${originalData['userId']}, currentUser=${user?.uid}, matches=$matches');
                  return matches;
                }).toList();

                print('Total orders: ${orders.length}');
                print('User orders: ${userOrders.length}');

                // Lọc theo tìm kiếm và trạng thái
                final filteredOrders = userOrders.where((order) {
                  final matchesSearch = _searchQuery.isEmpty ||
                      order.id.toLowerCase().contains(_searchQuery) ||
                      order.customer.storeName
                          .toLowerCase()
                          .contains(_searchQuery);
                  final matchesStatus = _selectedStatus == null ||
                      order.status == _selectedStatus;
                  return matchesSearch && matchesStatus;
                }).toList();

                if (userOrders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('Chưa có đơn hàng nào',
                            style: TextStyle(fontSize: 18, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text('User ID: ${user?.uid ?? "Chưa đăng nhập"}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                if (filteredOrders.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Không tìm thấy đơn hàng phù hợp',
                            style: TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredOrders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () => _showOrderDetail(order),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    order.customer.storeName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(order.status),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getStatusText(order.status),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Địa chỉ: ${order.customer.address}',
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm')
                                    .format(order.orderDate),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              // Hiển thị danh sách sản phẩm
                              if (order.items.isNotEmpty) ...[
                                Text(
                                  'Sản phẩm:',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ...order.items.take(2).map((item) => Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '• ${item.product.name} (${item.quantity} ${item.product.unit})',
                                              style:
                                                  const TextStyle(fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            '${NumberFormat('#,###').format(item.quantity * item.unitPrice)}đ',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                                if (order.items.length > 2)
                                  Text(
                                    '... và ${order.items.length - 2} sản phẩm khác',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                              ],
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Tổng cộng:',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${NumberFormat('#,###').format(order.totalAmount)}đ',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
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
}
