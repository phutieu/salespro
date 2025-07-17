import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salespro/admin/mock_data.dart';
import 'package:salespro/admin/models/purchase_order.dart';

class PurchaseOrderListScreen extends StatefulWidget {
  const PurchaseOrderListScreen({super.key});

  @override
  _PurchaseOrderListScreenState createState() =>
      _PurchaseOrderListScreenState();
}

class _PurchaseOrderListScreenState extends State<PurchaseOrderListScreen> {
  late List<PurchaseOrder> _purchaseOrders;

  @override
  void initState() {
    super.initState();
    _purchaseOrders = List.from(mockPurchaseOrders);
  }

  void _receiveOrder(PurchaseOrder order) {
    if (order.status == PurchaseOrderStatus.Ordered) {
      setState(() {
        order.status = PurchaseOrderStatus.Received;
        for (var item in order.items) {
          final product =
              mockProducts.firstWhere((p) => p.id == item.product.id);
          product.stockQuantity += item.quantity;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Stock updated successfully!'),
            backgroundColor: Colors.green),
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
            'Stock In / Purchases',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          // In a real app, a button to create a new purchase order would go here
          Expanded(
            child: ListView.builder(
              itemCount: _purchaseOrders.length,
              itemBuilder: (context, index) {
                final order = _purchaseOrders[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ExpansionTile(
                    leading: Icon(
                      order.status == PurchaseOrderStatus.Received
                          ? Icons.check_circle
                          : Icons.pending,
                      color: order.status == PurchaseOrderStatus.Received
                          ? Colors.green
                          : Colors.orange,
                    ),
                    title: Text('Order #${order.id} from ${order.supplier}'),
                    subtitle: Text(
                        'Date: ${DateFormat('dd/MM/yyyy').format(order.orderDate)}'),
                    trailing: order.status == PurchaseOrderStatus.Ordered
                        ? ElevatedButton(
                            onPressed: () => _receiveOrder(order),
                            child: const Text('Mark as Received'),
                          )
                        : null,
                    children: order.items.map((item) {
                      return ListTile(
                        title: Text(item.product.name),
                        trailing: Text(
                            '${item.quantity} x ${NumberFormat.decimalPattern('vi_VN').format(item.purchasePrice)} ₫'),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
