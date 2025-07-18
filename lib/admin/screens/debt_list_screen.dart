import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:salespro/admin/models/customer.dart';
import 'package:salespro/admin/models/order.dart';
import 'package:intl/intl.dart';

class DebtListScreen extends StatelessWidget {
  const DebtListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Debt & Payment Management',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
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
                    // Tính công nợ cho từng khách hàng
                    final Map<Customer, double> customerDebts = {};
                    for (var order in orders) {
                      if (order.status != OrderStatus.Cancelled) {
                        customerDebts.update(
                          order.customer,
                          (value) => value + order.amountDue,
                          ifAbsent: () => order.amountDue,
                        );
                      }
                    }
                    final debts = customerDebts.entries.toList();
                    return DataTable(
                      columns: const [
                        DataColumn(label: Text('Customer')),
                        DataColumn(label: Text('Phone Number')),
                        DataColumn(label: Text('Total Debt')),
                        DataColumn(label: Text('Actions')),
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
                                color:
                                    totalDebt > 0 ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(IconButton(
                            icon: const Icon(Icons.receipt_long,
                                color: Colors.blue),
                            onPressed: () {
                              context.go('/admin/debt/${customer.id}');
                            },
                          )),
                        ]);
                      }).toList(),
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
}
