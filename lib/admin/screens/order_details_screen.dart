import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salespro/admin/mock_data.dart';
import 'package:salespro/admin/models/order.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late Order _order;

  @override
  void initState() {
    super.initState();
    // In a real app, you would fetch the order from a database/API
    _order = mockOrders.firstWhere((o) => o.id == widget.orderId);
  }

  void _updateOrderStatus(OrderStatus newStatus) {
    setState(() {
      _order.status = newStatus;
      // In a real app, you would also save this change to your backend.
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details - #${_order.id}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Customer Information'),
            Text('Name: ${_order.customer.storeName}'),
            Text('Address: ${_order.customer.address}'),
            Text('Phone: ${_order.customer.phoneNumber}'),
            const Divider(height: 30),
            _buildSectionTitle('Order Summary'),
            Text(
                'Order Date: ${DateFormat('dd/MM/yyyy HH:mm').format(_order.orderDate)}'),
            Text('Status: ${_order.status.toString().split('.').last}'),
            const Divider(height: 30),
            _buildSectionTitle('Items'),
            DataTable(
              columns: const [
                DataColumn(label: Text('Product')),
                DataColumn(label: Text('Quantity')),
                DataColumn(label: Text('Unit Price')),
                DataColumn(label: Text('Total')),
              ],
              rows: _order.items.map((item) {
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
                'Grand Total: ${_order.totalAmount.toStringAsFixed(0)} ₫',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            if (_order.status == OrderStatus.Pending) ...[
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _updateOrderStatus(OrderStatus.Cancelled),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel Order'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _updateOrderStatus(OrderStatus.Confirmed),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Confirm Order'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
