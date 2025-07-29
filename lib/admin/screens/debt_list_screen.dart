import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:salespro/admin/models/customer.dart';
import 'package:salespro/admin/models/order.dart';
import 'package:intl/intl.dart';
import 'package:salespro/admin/models/payment.dart';

class DebtListScreen extends StatefulWidget {
  const DebtListScreen({super.key});

  @override
  State<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends State<DebtListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý công nợ'),
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
          _buildUnpaidCustomers(),
          _buildPaidCustomers(),
        ],
      ),
    );
  }

  Widget _buildUnpaidCustomers() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<firestore.QuerySnapshot>(
              stream: firestore.FirebaseFirestore.instance
                  .collection('orders')
                  .snapshots(),
              builder: (context, orderSnapshot) {
                if (!orderSnapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final orderDocs = orderSnapshot.data!.docs;
                final orders = orderDocs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Order.fromMap(data..['id'] = doc.id);
                }).toList();
                return StreamBuilder<firestore.QuerySnapshot>(
                  stream: firestore.FirebaseFirestore.instance
                      .collection('customers')
                      .snapshots(),
                  builder: (context, customerSnapshot) {
                    if (!customerSnapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final customerDocs = customerSnapshot.data!.docs;
                    final customers = customerDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return Customer.fromMap(data..['id'] = doc.id);
                    }).toList();
                    return StreamBuilder<firestore.QuerySnapshot>(
                      stream: firestore.FirebaseFirestore.instance
                          .collection('payments')
                          .snapshots(),
                      builder: (context, paymentSnapshot) {
                        if (!paymentSnapshot.hasData)
                          return const Center(
                              child: CircularProgressIndicator());
                        final paymentDocs = paymentSnapshot.data!.docs;
                        final payments = paymentDocs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return Payment.fromMap(data..['id'] = doc.id);
                        }).toList();
                        // Tính công nợ cho từng khách hàng
                        final Map<Customer, double> customerDebts = {};
                        for (var order in orders) {
                          if (order.status != OrderStatus.Cancelled) {
                            // Tính số tiền đã thanh toán từ payments collection
                            final paid = payments
                                .where((p) => p.orderId == order.id)
                                .fold(0.0, (sum, p) => sum + p.amount);
                            final amountDue = order.totalAmount - paid;
                            if (amountDue > 0) {
                              customerDebts.update(
                                order.customer,
                                (value) => value + amountDue,
                                ifAbsent: () => amountDue,
                              );
                            }
                          }
                        }
                        final debts = customerDebts.entries.toList();
                        if (debts.isEmpty) {
                          return const Center(
                            child:
                                Text('Không có khách hàng nào chưa thanh toán'),
                          );
                        }
                        return DataTable(
                          columns: const [
                            DataColumn(label: Text('Khách hàng')),
                            DataColumn(label: Text('Số điện thoại')),
                            DataColumn(label: Text('Tổng nợ')),
                            DataColumn(label: Text('Thao tác')),
                          ],
                          rows: debts.map((entry) {
                            final customer = entry.key;
                            final totalDebt = entry.value;
                            return DataRow(cells: [
                              DataCell(Text(customer.storeName)),
                              DataCell(Text(customer.phoneNumber)),
                              DataCell(
                                Text(
                                  '${NumberFormat.decimalPattern('vi_VN').format(totalDebt)} ₫',
                                  style: TextStyle(
                                    color: totalDebt > 0
                                        ? Colors.red
                                        : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(IconButton(
                                icon: const Icon(Icons.receipt_long,
                                    color: Colors.blue),
                                onPressed: () {
                                  _showCustomerDebtDetails(
                                      context, customer, orders, payments);
                                },
                              )),
                            ]);
                          }).toList(),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaidCustomers() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<firestore.QuerySnapshot>(
              stream: firestore.FirebaseFirestore.instance
                  .collection('orders')
                  .snapshots(),
              builder: (context, orderSnapshot) {
                if (!orderSnapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final orderDocs = orderSnapshot.data!.docs;
                final orders = orderDocs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Order.fromMap(data..['id'] = doc.id);
                }).toList();
                return StreamBuilder<firestore.QuerySnapshot>(
                  stream: firestore.FirebaseFirestore.instance
                      .collection('customers')
                      .snapshots(),
                  builder: (context, customerSnapshot) {
                    if (!customerSnapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final customerDocs = customerSnapshot.data!.docs;
                    final customers = customerDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return Customer.fromMap(data..['id'] = doc.id);
                    }).toList();
                    return StreamBuilder<firestore.QuerySnapshot>(
                      stream: firestore.FirebaseFirestore.instance
                          .collection('payments')
                          .snapshots(),
                      builder: (context, paymentSnapshot) {
                        if (!paymentSnapshot.hasData)
                          return const Center(
                              child: CircularProgressIndicator());
                        final paymentDocs = paymentSnapshot.data!.docs;
                        final payments = paymentDocs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return Payment.fromMap(data..['id'] = doc.id);
                        }).toList();
                        // Tính tổng thanh toán cho từng khách hàng
                        final Map<Customer, double> customerPayments = {};
                        for (var order in orders) {
                          if (order.status != OrderStatus.Cancelled) {
                            // Tính số tiền đã thanh toán từ payments collection
                            final paid = payments
                                .where((p) => p.orderId == order.id)
                                .fold(0.0, (sum, p) => sum + p.amount);
                            if (paid > 0) {
                              customerPayments.update(
                                order.customer,
                                (value) => value + paid,
                                ifAbsent: () => paid,
                              );
                            }
                          }
                        }
                        final paidCustomers = customerPayments.entries.toList();
                        if (paidCustomers.isEmpty) {
                          return const Center(
                            child:
                                Text('Không có khách hàng nào đã thanh toán'),
                          );
                        }
                        return DataTable(
                          columns: const [
                            DataColumn(label: Text('Khách hàng')),
                            DataColumn(label: Text('Số điện thoại')),
                            DataColumn(label: Text('Tổng đã trả')),
                            DataColumn(label: Text('Thao tác')),
                          ],
                          rows: paidCustomers.map((entry) {
                            final customer = entry.key;
                            final totalPaid = entry.value;
                            return DataRow(cells: [
                              DataCell(Text(customer.storeName)),
                              DataCell(Text(customer.phoneNumber)),
                              DataCell(
                                Text(
                                  '${NumberFormat.decimalPattern('vi_VN').format(totalPaid)} ₫',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(IconButton(
                                icon: const Icon(Icons.receipt_long,
                                    color: Colors.blue),
                                onPressed: () {
                                  _showCustomerDebtDetails(
                                      context, customer, orders, payments);
                                },
                              )),
                            ]);
                          }).toList(),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomerDebtDetails(BuildContext context, Customer customer,
      List<Order> orders, List<Payment> payments) {
    // Lọc đơn hàng của khách hàng này
    final customerOrders =
        orders.where((order) => order.customer.id == customer.id).toList();

    // Tính toán chi tiết thanh toán cho từng đơn hàng
    final orderDetails = customerOrders.map((order) {
      final orderPayments =
          payments.where((p) => p.orderId == order.id).toList();
      final totalPaid = orderPayments.fold(0.0, (sum, p) => sum + p.amount);
      final amountDue = order.totalAmount - totalPaid;

      return {
        'order': order,
        'payments': orderPayments,
        'totalPaid': totalPaid,
        'amountDue': amountDue,
      };
    }).toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Chi tiết: ${customer.storeName}'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thông tin khách hàng
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thông tin khách hàng',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text('Tên: ${customer.storeName}'),
                        Text('SĐT: ${customer.phoneNumber}'),
                        Text('Địa chỉ: ${customer.address}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Danh sách đơn hàng
                Expanded(
                  child: ListView.builder(
                    itemCount: orderDetails.length,
                    itemBuilder: (context, index) {
                      final detail = orderDetails[index];
                      final order = detail['order'] as Order;
                      final orderPayments = detail['payments'] as List<Payment>;
                      final totalPaid = detail['totalPaid'] as double;
                      final amountDue = detail['amountDue'] as double;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Đơn hàng #${order.id.substring(0, 8)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: amountDue > 0
                                          ? Colors.orange
                                          : Colors.green,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      amountDue > 0
                                          ? 'Chưa thanh toán'
                                          : 'Đã thanh toán',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                  'Ngày đặt: ${DateFormat('dd/MM/yyyy').format(order.orderDate)}'),
                              Text(
                                  'Tổng tiền: ${NumberFormat.decimalPattern('vi_VN').format(order.totalAmount)} ₫'),
                              Text(
                                  'Đã trả: ${NumberFormat.decimalPattern('vi_VN').format(totalPaid)} ₫'),
                              Text(
                                'Còn nợ: ${NumberFormat.decimalPattern('vi_VN').format(amountDue)} ₫',
                                style: TextStyle(
                                  color:
                                      amountDue > 0 ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (orderPayments.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const Text('Lịch sử thanh toán:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                ...orderPayments.map((payment) => Padding(
                                      padding: const EdgeInsets.only(
                                          left: 16, top: 4),
                                      child: Text(
                                        '${DateFormat('dd/MM/yyyy HH:mm').format(payment.paymentDate)} - ${NumberFormat.decimalPattern('vi_VN').format(payment.amount)} ₫ (${_getPaymentMethodText(payment.method)})',
                                      ),
                                    )),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
}
