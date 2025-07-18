import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:salespro/admin/models/customer.dart';
import 'package:salespro/admin/models/order.dart';
import 'package:salespro/admin/models/payment.dart';

class CustomerDebtDetailsScreen extends StatelessWidget {
  final String customerId;

  const CustomerDebtDetailsScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt Details'),
      ),
      body: StreamBuilder<firestore.QuerySnapshot>(
        stream: firestore.FirebaseFirestore.instance
            .collection('customers')
            .where('id', isEqualTo: customerId)
            .snapshots(),
        builder: (context, customerSnapshot) {
          if (!customerSnapshot.hasData ||
              customerSnapshot.data!.docs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final customerData =
              customerSnapshot.data!.docs.first.data() as Map<String, dynamic>;
          final customer = Customer.fromMap(customerData);
          return StreamBuilder<firestore.QuerySnapshot>(
            stream: firestore.FirebaseFirestore.instance
                .collection('orders')
                .where('customer.id', isEqualTo: customerId)
                .snapshots(),
            builder: (context, orderSnapshot) {
              if (!orderSnapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final orderDocs = orderSnapshot.data!.docs;
              final customerOrders = orderDocs
                  .map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Order.fromMap(data..['id'] = doc.id);
                  })
                  .where((o) => o.status != OrderStatus.Cancelled)
                  .toList();
              final totalDebt =
                  customerOrders.fold<double>(0, (sum, o) => sum + o.amountDue);
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Total Debt: ${NumberFormat.decimalPattern('vi_VN').format(totalDebt)} ₫',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: Colors.red)),
                    const SizedBox(height: 20),
                    ...customerOrders.map((order) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Order #${order.id}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text(
                                  'Date: ${DateFormat('dd/MM/yyyy').format(order.orderDate)}'),
                              Text(
                                  'Total: ${NumberFormat.decimalPattern('vi_VN').format(order.totalAmount)} ₫'),
                              Text(
                                  'Paid: ${NumberFormat.decimalPattern('vi_VN').format(order.amountPaid)} ₫'),
                              Text(
                                  'Due: ${NumberFormat.decimalPattern('vi_VN').format(order.amountDue)} ₫',
                                  style: const TextStyle(color: Colors.red)),
                              const Divider(),
                              Text('Payments:',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              ...order.payments.map((p) => Text(
                                    '- ${NumberFormat.decimalPattern('vi_VN').format(p.amount)} ₫ (${DateFormat('dd/MM/yyyy').format(p.paymentDate)})',
                                  )),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
