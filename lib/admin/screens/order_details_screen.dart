import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:salespro/admin/models/order.dart';

class OrderDetailsScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details - #$orderId'),
      ),
      body: FutureBuilder<firestore.DocumentSnapshot>(
        future: firestore.FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final order = Order.fromMap(data..['id'] = orderId);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Customer Information'),
                Text('Name: ${order.customer.storeName}'),
                Text('Address: ${order.customer.address}'),
                Text('Phone: ${order.customer.phoneNumber}'),
                const Divider(height: 30),
                _buildSectionTitle('Order Summary'),
                Text(
                    'Order Date: ${DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate)}'),
                Text('Status: ${order.status.toString().split('.').last}'),
                const Divider(height: 30),
                _buildSectionTitle('Items'),
                DataTable(
                  columns: const [
                    DataColumn(label: Text('Product')),
                    DataColumn(label: Text('Quantity')),
                    DataColumn(label: Text('Unit Price')),
                    DataColumn(label: Text('Total')),
                  ],
                  rows: order.items.map((item) {
                    return DataRow(cells: [
                      DataCell(Text(item.product.name)),
                      DataCell(Text(item.quantity.toString())),
                      DataCell(Text('${item.unitPrice.toStringAsFixed(0)} ₫')),
                      DataCell(Text('${item.totalPrice.toStringAsFixed(0)} ₫')),
                    ]);
                  }).toList(),
                ),
                const Divider(height: 30),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Grand Total: ${order.totalAmount.toStringAsFixed(0)} ₫',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }
}
