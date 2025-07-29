import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  const CheckoutScreen({super.key, required this.cartItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String? selectedCustomerId;
  Map<String, dynamic>? selectedCustomerData;

  @override
  Widget build(BuildContext context) {
    final total = widget.cartItems
        .fold<num>(0, (sum, item) => sum + (item['price'] * item['quantity']));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán đơn hàng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Chọn khách hàng
          Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<firestore.QuerySnapshot>(
              stream: firestore.FirebaseFirestore.instance
                  .collection('customers')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final docs = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  value: selectedCustomerId,
                  hint: const Text('Chọn cửa hàng/khách hàng'),
                  items: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(
                          '${data['storeName'] ?? ''} - ${data['code'] ?? ''}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCustomerId = value;
                      selectedCustomerData = docs
                          .firstWhere((d) => d.id == value)
                          .data() as Map<String, dynamic>;
                    });
                  },
                );
              },
            ),
          ),
          // Hiển thị thông tin khách hàng đã chọn
          if (selectedCustomerData != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tên: ${selectedCustomerData!['storeName'] ?? ''}'),
                  Text('Địa chỉ: ${selectedCustomerData!['address'] ?? ''}'),
                  Text('SĐT: ${selectedCustomerData!['phoneNumber'] ?? ''}'),
                ],
              ),
            ),
          // Danh sách sản phẩm
          Expanded(
            child: ListView.separated(
              itemCount: widget.cartItems.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = widget.cartItems[index];
                return ListTile(
                  title: Text('${item['name']}'),
                  subtitle: Text(
                      'Số lượng: ${item['quantity']} x ${NumberFormat('#,###').format(item['price'])}'),
                  trailing: Text(NumberFormat('#,###')
                      .format(item['price'] * item['quantity'])),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Tổng cộng:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Spacer(),
                Text(NumberFormat('#,###').format(total),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Đổi sang xanh lá cây
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: selectedCustomerId == null
                    ? null
                    : () async {
                        final user = FirebaseAuth.instance.currentUser;
                        // Chuyển cartItems thành danh sách OrderItem map đúng định dạng
                        final items = widget.cartItems
                            .map((item) => {
                                  'product': {
                                    'id': item['id'],
                                    'name': item['name'],
                                    'description': item['description'] ?? '',
                                    'unit': item['unit'],
                                    'salePrice': item['price'],
                                    'purchasePrice': item['price'],
                                    'stockQuantity': item['stockQuantity'] ?? 0,
                                    'category': item['category'] ?? '',
                                  },
                                  'quantity': item['quantity'],
                                  'unitPrice': item['price'],
                                })
                            .toList();
                        await firestore.FirebaseFirestore.instance
                            .collection('orders')
                            .add({
                          'customerId': selectedCustomerId,
                          'customer': {
                            'id': selectedCustomerId,
                            'storeName':
                                selectedCustomerData!['storeName'] ?? '',
                            'address': selectedCustomerData!['address'] ?? '',
                            'contactPerson':
                                selectedCustomerData!['contactPerson'] ?? '',
                            'phoneNumber':
                                selectedCustomerData!['phoneNumber'] ?? '',
                            'area': selectedCustomerData!['area'] ?? '',
                          },
                          'items': items,
                          'payments': [],
                          'orderDate': DateTime.now().toIso8601String(),
                          'status': 'Pending',
                          'userId': user?.uid,
                        });
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đặt hàng thành công!')),
                        );
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                        );
                      },
                child: const Text(
                  'Xác nhận đặt hàng',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black), // Chữ đen đậm
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
