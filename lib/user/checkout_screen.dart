import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';

class CheckoutScreen extends StatelessWidget {
  final List<Map<String, dynamic>> cartItems;
  const CheckoutScreen({super.key, required this.cartItems});

  @override
  Widget build(BuildContext context) {
    final total = cartItems.fold<num>(
        0, (sum, item) => sum + (item['price'] * item['quantity']));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán đơn hàng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: cartItems.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = cartItems[index];
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
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  await FirebaseFirestore.instance.collection('orders').add({
                    'userId': user?.uid,
                    'items': cartItems,
                    'total': total,
                    'createdAt': DateTime.now().toIso8601String(),
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đặt hàng thành công!')),
                  );
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Xác nhận đặt hàng',
                    style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
