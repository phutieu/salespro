import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:salespro/admin/models/order.dart' as modelOrder;
import 'package:salespro/admin/models/payment.dart';
import 'custom_bottom_nav_bar.dart' as nav;
import 'home_screen.dart';
import 'customer_list_screen.dart';
import 'order_list_screen.dart';
import 'screens/orthers_scren.dart';
import 'kpi_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  User? user;
  int _selectedIndex = 4;

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
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    user = FirebaseAuth.instance.currentUser;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        return 'Đã trả';
    }
  }

  String _getPaymentMethodText(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.Cash:
        return 'Tiền mặt';
      case PaymentMethod.BankTransfer:
        return 'Chuyển khoản';
      case PaymentMethod.Other:
        return 'Khác';
    }
  }

  void _showPaymentDialog(modelOrder.Order order) {
    double paymentAmount = 0.0;
    PaymentMethod selectedMethod = PaymentMethod.Cash;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Thanh toán'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Khách hàng: ${order.customer.storeName}'),
              Text(
                  'Tổng tiền: ${NumberFormat.decimalPattern('vi_VN').format(order.totalAmount)} ₫'),
              Text(
                  'Đã trả: ${NumberFormat.decimalPattern('vi_VN').format(order.amountPaid)} ₫'),
              Text(
                  'Còn nợ: ${NumberFormat.decimalPattern('vi_VN').format(order.amountDue)} ₫'),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Số tiền thanh toán',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  paymentAmount = double.tryParse(value) ?? 0.0;
                },
              ),
              const SizedBox(height: 16),
              const Text('Phương thức thanh toán:'),
              RadioListTile<PaymentMethod>(
                title: const Text('Tiền mặt'),
                value: PaymentMethod.Cash,
                groupValue: selectedMethod,
                onChanged: (PaymentMethod? value) {
                  setState(() {
                    selectedMethod = value!;
                  });
                },
              ),
              RadioListTile<PaymentMethod>(
                title: const Text('Chuyển khoản'),
                value: PaymentMethod.BankTransfer,
                groupValue: selectedMethod,
                onChanged: (PaymentMethod? value) {
                  setState(() {
                    selectedMethod = value!;
                  });
                },
              ),
              RadioListTile<PaymentMethod>(
                title: const Text('Khác'),
                value: PaymentMethod.Other,
                groupValue: selectedMethod,
                onChanged: (PaymentMethod? value) {
                  setState(() {
                    selectedMethod = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (paymentAmount > 0 && paymentAmount <= order.amountDue) {
                  try {
                    final paymentRef = await firestore
                        .FirebaseFirestore.instance
                        .collection('payments')
                        .add({
                      'orderId': order.id,
                      'amount': paymentAmount,
                      'paymentDate': firestore.FieldValue.serverTimestamp(),
                      'method': selectedMethod.index,
                      'userId': user?.uid,
                    });
                    await paymentRef.update({'id': paymentRef.id});
                    print('Payment saved: ${paymentRef.id}');
                    print('Payment data: ${await paymentRef.get()}');
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thanh toán thành công!')),
                    );
                  } catch (e) {
                    print('Error saving payment: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Số tiền không hợp lệ!')),
                  );
                }
              },
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chưa thanh toán'),
            Tab(text: 'Đã thanh toán'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUnpaidOrders(),
          _buildPaidOrders(),
        ],
      ),
      bottomNavigationBar: nav.CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildUnpaidOrders() {
    return StreamBuilder<firestore.QuerySnapshot>(
      stream:
          firestore.FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, orderSnapshot) {
        if (!orderSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<firestore.QuerySnapshot>(
          stream: firestore.FirebaseFirestore.instance
              .collection('payments')
              .snapshots(),
          builder: (context, paymentSnapshot) {
            if (!paymentSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
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

            final orders = orderSnapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return modelOrder.Order.fromMap(data);
            }).where((order) {
              final doc =
                  orderSnapshot.data!.docs.firstWhere((d) => d.id == order.id);
              final originalData = doc.data() as Map<String, dynamic>;
              return originalData['userId'] == user?.uid;
            }).where((order) {
              final paidAmount = paymentsMap[order.id] ?? 0.0;
              final amountDue = order.totalAmount - paidAmount;
              return amountDue > 0;
            }).toList();

            if (orders.isEmpty) {
              return const Center(
                child: Text('Không có đơn hàng nào chưa thanh toán'),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orders[index];
                final paidAmount = paymentsMap[order.id] ?? 0.0;
                final amountDue = order.totalAmount - paidAmount;

                return Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                order.customer.storeName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(order.status),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getStatusText(order.status),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Ngày đặt: ${DateFormat('dd/MM/yyyy').format(order.orderDate)}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${order.items.length} sản phẩm',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Tổng tiền:'),
                                  Text(
                                    '${NumberFormat.decimalPattern('vi_VN').format(order.totalAmount)} ₫',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Đã trả:'),
                                  Text(
                                    '${NumberFormat.decimalPattern('vi_VN').format(paidAmount)} ₫',
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Còn nợ:'),
                                  Text(
                                    '${NumberFormat.decimalPattern('vi_VN').format(amountDue)} ₫',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _showPaymentDialog(order),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Thanh toán'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPaidOrders() {
    return StreamBuilder<firestore.QuerySnapshot>(
      stream:
          firestore.FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, orderSnapshot) {
        if (!orderSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<firestore.QuerySnapshot>(
          stream: firestore.FirebaseFirestore.instance
              .collection('payments')
              .snapshots(),
          builder: (context, paymentSnapshot) {
            if (!paymentSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
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

            final orders = orderSnapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return modelOrder.Order.fromMap(data);
            }).where((order) {
              final doc =
                  orderSnapshot.data!.docs.firstWhere((d) => d.id == order.id);
              final originalData = doc.data() as Map<String, dynamic>;
              return originalData['userId'] == user?.uid;
            }).where((order) {
              final paidAmount = paymentsMap[order.id] ?? 0.0;
              final amountDue = order.totalAmount - paidAmount;
              return amountDue <= 0 && paidAmount > 0;
            }).toList();

            if (orders.isEmpty) {
              return const Center(
                child: Text('Không có đơn hàng nào đã thanh toán'),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = orders[index];
                final paidAmount = paymentsMap[order.id] ?? 0.0;

                return Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                order.customer.storeName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Đã thanh toán',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Ngày đặt: ${DateFormat('dd/MM/yyyy').format(order.orderDate)}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${order.items.length} sản phẩm',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Tổng tiền:'),
                                  Text(
                                    '${NumberFormat.decimalPattern('vi_VN').format(order.totalAmount)} ₫',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Đã trả:'),
                                  Text(
                                    '${NumberFormat.decimalPattern('vi_VN').format(paidAmount)} ₫',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Còn nợ:'),
                                  Text(
                                    '0 ₫',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
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
              },
            );
          },
        );
      },
    );
  }
}
