import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salespro/admin/models/purchase_order.dart';

class PurchaseOrderListScreen extends StatefulWidget {
  const PurchaseOrderListScreen({super.key});

  @override
  _PurchaseOrderListScreenState createState() =>
      _PurchaseOrderListScreenState();
}

class _PurchaseOrderListScreenState extends State<PurchaseOrderListScreen> {
  void _receiveOrder(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final order = PurchaseOrder.fromMap(data..['id'] = doc.id);
    if (order.status == PurchaseOrderStatus.Ordered) {
      await FirebaseFirestore.instance
          .collection('purchase_orders')
          .doc(doc.id)
          .update({
        'status': 'Received',
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('purchase_orders')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final order = PurchaseOrder.fromMap(data..['id'] = doc.id);
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
                        title:
                            Text('Order #${order.id} from ${order.supplier}'),
                        subtitle: Text(
                            'Date: ${DateFormat('dd/MM/yyyy').format(order.orderDate)}'),
                        trailing: order.status == PurchaseOrderStatus.Ordered
                            ? ElevatedButton(
                                onPressed: () => _receiveOrder(doc),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
