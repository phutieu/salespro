import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:salespro/admin/models/order.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  _OrderListScreenState createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  OrderStatus? _selectedStatus;

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.Pending:
        return Colors.orange;
      case OrderStatus.Confirmed:
        return Colors.blue;
      case OrderStatus.Delivered:
        return Colors.green;
      case OrderStatus.Cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(OrderStatus status) {
    return status.toString().split('.').last;
  }

  Future<void> _updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      await firestore.FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus.toString().split('.').last});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating order status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Orders',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8.0,
            children: OrderStatus.values.map((status) {
              return ChoiceChip(
                label: Text(_getStatusText(status)),
                selected: _selectedStatus == status,
                onSelected: (selected) {
                  setState(() {
                    _selectedStatus = selected ? status : null;
                  });
                },
                selectedColor: _getStatusColor(status).withOpacity(0.3),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<firestore.QuerySnapshot>(
              stream: firestore.FirebaseFirestore.instance
                  .collection('orders')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                final orders = docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Order.fromMap(data..['id'] = doc.id);
                }).toList();
                final filteredOrders = _selectedStatus == null
                    ? orders
                    : orders
                        .where((order) => order.status == _selectedStatus)
                        .toList();
                return DataTable(
                  columns: const [
                    DataColumn(label: Text('Order ID')),
                    DataColumn(label: Text('Customer')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Total')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: filteredOrders.map((order) {
                    return DataRow(cells: [
                      DataCell(Text(order.id)),
                      DataCell(Text(order.customer.storeName)),
                      DataCell(Text(
                          DateFormat('dd/MM/yyyy').format(order.orderDate))),
                      DataCell(
                          Text('${order.totalAmount.toStringAsFixed(0)} ₫')),
                      DataCell(
                        DropdownButton<OrderStatus>(
                          value: order.status,
                          items: OrderStatus.values.map((status) {
                            return DropdownMenuItem<OrderStatus>(
                              value: status,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getStatusText(status),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (OrderStatus? newStatus) {
                            if (newStatus != null) {
                              _updateOrderStatus(order.id, newStatus);
                            }
                          },
                        ),
                      ),
                      DataCell(IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.grey),
                        onPressed: () {
                          context.go('/admin/orders/${order.id}');
                        },
                      )),
                    ]);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
