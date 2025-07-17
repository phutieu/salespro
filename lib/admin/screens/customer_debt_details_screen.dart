import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salespro/admin/mock_data.dart';
import 'package:salespro/admin/models/customer.dart';
import 'package:salespro/admin/models/order.dart';
import 'package:salespro/admin/models/payment.dart';
import 'dart:math';

class CustomerDebtDetailsScreen extends StatefulWidget {
  final String customerId;

  const CustomerDebtDetailsScreen({super.key, required this.customerId});

  @override
  _CustomerDebtDetailsScreenState createState() =>
      _CustomerDebtDetailsScreenState();
}

class _CustomerDebtDetailsScreenState extends State<CustomerDebtDetailsScreen> {
  late Customer _customer;
  late List<Order> _customerOrders;

  @override
  void initState() {
    super.initState();
    _customer = mockCustomers.firstWhere((c) => c.id == widget.customerId);
    _customerOrders = mockOrders
        .where((o) =>
            o.customer.id == widget.customerId &&
            o.status != OrderStatus.Cancelled)
        .toList();
  }

  void _addPayment(Order order, double amount) {
    setState(() {
      final newPayment = Payment(
        id: 'TT${Random().nextInt(1000).toString().padLeft(3, '0')}',
        orderId: order.id,
        amount: amount,
        paymentDate: DateTime.now(),
        method: PaymentMethod.Cash, // Default method for now
      );
      order.payments.add(newPayment);
      // In a real app, you would save this to your database
    });
  }

  void _showAddPaymentDialog(Order order) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Payment for Order #${order.id}'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
              labelText: 'Amount',
              hintText:
                  'Max: ${NumberFormat.decimalPattern('vi_VN').format(order.amountDue)} ₫'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0 && amount <= order.amountDue) {
                _addPayment(order, amount);
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.Paid:
        return Colors.green;
      case PaymentStatus.PartiallyPaid:
        return Colors.orange;
      case PaymentStatus.Unpaid:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDebt =
        _customerOrders.fold<double>(0, (sum, order) => sum + order.amountDue);

    return Scaffold(
      appBar: AppBar(
        title: Text('Debt Details - ${_customer.storeName}'),
      ),
      body: SingleChildScrollView(
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
            ..._customerOrders.map((order) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Order #${order.id} - ${DateFormat('dd/MM/yyyy').format(order.orderDate)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Divider(),
                      Text(
                          'Total Amount: ${NumberFormat.decimalPattern('vi_VN').format(order.totalAmount)} ₫'),
                      Text(
                          'Amount Paid: ${NumberFormat.decimalPattern('vi_VN').format(order.amountPaid)} ₫'),
                      Text(
                          'Amount Due: ${NumberFormat.decimalPattern('vi_VN').format(order.amountDue)} ₫',
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  _getPaymentStatusColor(order.paymentStatus),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                                order.paymentStatus.toString().split('.').last,
                                style: const TextStyle(color: Colors.white)),
                          ),
                          if (order.amountDue > 0)
                            ElevatedButton(
                              onPressed: () => _showAddPaymentDialog(order),
                              child: const Text('Add Payment'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
