import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:salespro/admin/models/order.dart';
import 'package:salespro/admin/models/order_item.dart';
import 'package:salespro/admin/models/customer.dart';

class CheckoutScreen extends StatefulWidget {
  final List<OrderItem> items;

  const CheckoutScreen({super.key, required this.items});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  Customer? selectedCustomer;

  Future<void> _createOrder() async {
    if (selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn khách hàng!')),
      );
      return;
    }

    try {
      final orderRef = FirebaseFirestore.instance.collection('orders').doc();
      final order = Order(
        id: orderRef.id,
        customer: selectedCustomer!,
        items: widget.items,
        orderDate: DateTime.now(),
      );

      await orderRef.set(order.toMap());
      Navigator.of(context).pop(true); // Trở về màn hình trước
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount =
        widget.items.fold<double>(0, (sum, item) => sum + item.totalPrice);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác nhận đơn hàng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Chọn khách hàng
          Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('customers').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final customers = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Customer.fromMap({...data, 'id': doc.id});
                }).toList();

                return DropdownButtonFormField<Customer>(
                  decoration: const InputDecoration(
                    labelText: 'Chọn khách hàng',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedCustomer,
                  items: customers.map((customer) {
                    return DropdownMenuItem(
                      value: customer,
                      child: Text(customer.storeName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedCustomer = value);
                  },
                );
              },
            ),
          ),
          // Danh sách sản phẩm
          Expanded(
            child: ListView.builder(
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text('${item.quantity} ${item.unit}'),
                  trailing: Text(
                    NumberFormat('#,###').format(item.totalPrice),
                  ),
                );
              },
            ),
          ),
          // Tổng tiền và nút xác nhận
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Tổng tiền'),
                      Text(
                        NumberFormat('#,###').format(totalAmount),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _createOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('Xác nhận đơn hàng'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
    int totalSales = orderSnap.docs.fold(
        0, (sum, doc) => sum + ((doc['totalAmount'] ?? 0) as num).toInt());

    // Thanh toán
    final paymentSnap = await FirebaseFirestore.instance
        .collection('payments')
        .where('paymentDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('paymentDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    int totalPayment = paymentSnap.docs
        .fold(0, (sum, doc) => sum + ((doc['amount'] ?? 0) as num).toInt());

    // Check-in
    final checkinSnap = await FirebaseFirestore.instance
        .collection('check-in')
        .where('checkinTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('checkinTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    int checkinCount = checkinSnap.docs.length;

    setState(() {
      todayOrderCount = orderCount;
      todayPaymentTotal = totalPayment;
      todayCheckins = checkinCount;
    });
  }
}
