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

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  final user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 3;
  late TabController _tabController;
  final List<modelOrder.OrderStatus?> _tabStatus = [
    modelOrder.OrderStatus.Pending,
    modelOrder.OrderStatus.Confirmed,
    modelOrder.OrderStatus.Delivered,
    modelOrder.OrderStatus.Return,
    modelOrder.OrderStatus.Cancelled,
  ];
  final List<String> _tabTitles = [
    'Chờ xác nhận',
    'Chờ lấy hàng', // Có thể map Confirmed thành Chờ lấy hàng
    'Chờ giao hàng', // Có thể map Delivered thành Chờ giao hàng nếu cần
    'Đã trả hàng',
    'Đã hủy',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabStatus.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      case modelOrder.OrderStatus.Return:
        return Colors.purple;
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
      case modelOrder.OrderStatus.Return:
        return 'Đã trả hàng';
    }
  }

  void _showOrderDetail(modelOrder.Order order) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Chi tiết đơn hàng',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Hàng nút xuất hóa đơn + trả hàng
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (order.status == modelOrder.OrderStatus.Delivered)
                          TextButton.icon(
                            icon: const Icon(Icons.assignment_return,
                                color: Colors.black),
                            label: const Text('Trả hàng',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black)),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showReturnDialog(order);
                            },
                          ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: () async {
                                try {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Đang tạo hóa đơn PDF...')),
                                  );
                                  await PdfService.generateInvoice(order);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Đã xuất hóa đơn thành công!')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Lỗi xuất hóa đơn: $e')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.picture_as_pdf,
                                  color: Colors.black),
                              label: const Text('Xuất hóa đơn',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
                            ),
                            if (order.status == modelOrder.OrderStatus.Return)
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Text('Đơn trả hàng',
                                    style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                          const SizedBox(height: 4),
                          Text(
                            _getStatusText(order.status),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Danh sách sản phẩm
                    const Text(
                      'Danh sách sản phẩm:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      'Số lượng: ${item.quantity} ${item.product.unit}'),
                                  Text(
                                      'Giá: ${NumberFormat('#,###').format(item.unitPrice)}đ'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Thành tiền:'),
                                  Text(
                                    '${NumberFormat('#,###').format(item.quantity * item.unitPrice)}đ',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
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
                      // Xóa decoration để không còn màu nền, không viền
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tổng tiền:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            '${NumberFormat('#,###').format(order.totalAmount)}đ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black, // Đậm, không còn màu xanh
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReturnDialog(modelOrder.Order order) {
    showDialog(
      context: context,
      builder: (context) {
        final Map<String, int> returnQuantities = {
          for (var item in order.items) item.product.id: 0
        };
        final Map<String, TextEditingController> qtyControllers = {
          for (var item in order.items)
            item.product.id: TextEditingController(text: '0')
        };
        final reasonController = TextEditingController();
        final _formKey = GlobalKey<FormState>();
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Trả hàng'),
            content: SizedBox(
              width: 400,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: order.items.length,
                      itemBuilder: (context, idx) {
                        final item = order.items[idx];
                        final maxQty = item.quantity;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.product.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text('Đã mua: $maxQty',
                                  style: const TextStyle(color: Colors.grey)),
                              Row(
                                children: [
                                  const Text('Số lượng trả:'),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 60,
                                    child: TextFormField(
                                      controller:
                                          qtyControllers[item.product.id],
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 8, horizontal: 8),
                                      ),
                                      onChanged: (v) {
                                        int val = int.tryParse(v) ?? 0;
                                        if (val > maxQty) val = maxQty;
                                        setState(() {
                                          qtyControllers[item.product.id]!
                                              .text = val.toString();
                                          qtyControllers[item.product.id]!
                                                  .selection =
                                              TextSelection.fromPosition(
                                                  TextPosition(
                                                      offset: qtyControllers[
                                                              item.product.id]!
                                                          .text
                                                          .length));
                                          returnQuantities[item.product.id] =
                                              val;
                                        });
                                      },
                                      validator: (v) {
                                        int val = int.tryParse(v ?? '') ?? 0;
                                        if (val < 0) return 'Không hợp lệ';
                                        if (val > maxQty)
                                          return 'Tối đa $maxQty';
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Lý do trả hàng',
                        isDense: true,
                      ),
                      validator: (v) {
                        final hasReturn =
                            returnQuantities.values.any((q) => q > 0);
                        if (hasReturn && (v == null || v.trim().isEmpty)) {
                          return 'Nhập lý do trả hàng';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  final user = FirebaseAuth.instance.currentUser;
                  final items = order.items
                      .where((item) =>
                          (returnQuantities[item.product.id] ?? 0) > 0)
                      .map((item) => {
                            'productId': item.product.id,
                            'productName': item.product.name,
                            'quantity': returnQuantities[item.product.id],
                            'reason': reasonController.text,
                          })
                      .toList();
                  if (items.isEmpty) return;
                  await firestore.FirebaseFirestore.instance
                      .collection('returns')
                      .add({
                    'orderId': order.id,
                    'userId': user?.uid,
                    'customerId': order.customer.id,
                    'items': items,
                    'createdAt': firestore.FieldValue.serverTimestamp(),
                  });
                  await firestore.FirebaseFirestore.instance
                      .collection('orders')
                      .doc(order.id)
                      .update({'status': 'Return'});
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã ghi nhận trả hàng!')));
                },
                child: const Text('Xác nhận',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Danh sách đơn hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _OrderSearchDelegate(user: user),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabTitles.map((title) => Tab(text: title)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabStatus.map((status) {
          return _buildOrderList(status);
        }).toList(),
      ),
      bottomNavigationBar: nav.CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildOrderList(modelOrder.OrderStatus? status) {
    return StreamBuilder<firestore.QuerySnapshot>(
      stream: firestore.FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snapshot.data!.docs
            .map((doc) => modelOrder.Order.fromMap(
                {...doc.data() as Map<String, dynamic>, 'id': doc.id}))
            .where((order) => status == null || order.status == status)
            .toList();
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('Bạn chưa có đơn hàng nào cả',
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return GestureDetector(
              onTap: () => _showOrderDetail(order),
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(order.customer.storeName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(_getStatusText(order.status),
                                style: const TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                          'Ngày đặt: ${DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate)}'),
                      // ... Thêm các thông tin khác nếu cần ...
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Delegate cho tìm kiếm đơn hàng
class _OrderSearchDelegate extends SearchDelegate {
  final User? user;
  _OrderSearchDelegate({this.user});

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) {
    return StreamBuilder<firestore.QuerySnapshot>(
      stream: firestore.FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snapshot.data!.docs
            .map((doc) => modelOrder.Order.fromMap(
                {...doc.data() as Map<String, dynamic>, 'id': doc.id}))
            .where((order) => order.customer.storeName
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
        if (orders.isEmpty) {
          return Center(child: Text('Không tìm thấy đơn hàng nào!'));
        }
        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return ListTile(
              title: Text(order.customer.storeName),
              subtitle: Text(
                  'Ngày đặt: ${DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate)}'),
              onTap: () {
                close(context, null);
                // Hiển thị chi tiết đơn hàng
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('Chi tiết đơn hàng'),
                    content: Text('Thông tin đơn hàng: ${order.id}'),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}
