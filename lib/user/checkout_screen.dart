import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  const CheckoutScreen({super.key, required this.cartItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPaymentMethod = 'Cash';
  String? _orderId;

  // Đảm bảo các biến này đã được khai báo trong State ở đầu class _CheckoutScreenState:
  int todayOrderCount = 0;
  int todayPaymentTotal = 0;
  int todayCheckins = 0;

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
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  // Lưu đơn hàng
                  final orderRef = await FirebaseFirestore.instance
                      .collection('orders')
                      .add({
                    'userId': user?.uid,
                    'items': widget.cartItems,
                    'total': total,
                    'createdAt': DateTime.now().toIso8601String(),
                  });
                  // Lưu thanh toán vào collection 'payment' với tổng tiền, ngày, id thanh toán
                  final paymentRef = await FirebaseFirestore.instance
                      .collection('payment')
                      .add({
                    'amount': total,
                    'orderId': orderRef.id,
                    'userId': user?.uid,
                    'paymentDate': Timestamp.now(),
                  });
                  // Có thể lấy id thanh toán qua paymentRef.id nếu cần
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Đặt hàng & thanh toán thành công!')),
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

  Future<void> _handlePayment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Tạo dữ liệu thanh toán
    final paymentData = {
      'amount': _calculateTotalAmount(), // Tính tổng tiền
      'method': _selectedPaymentMethod, // Ví dụ: 'Cash', 'Other'
      'orderId': _orderId, // Nếu có mã đơn hàng
      'userId': user.uid,
      'paymentDate': Timestamp.now(),
      // Thêm các trường khác nếu cần
    };

    await FirebaseFirestore.instance.collection('payment').add(paymentData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thanh toán thành công!')),
    );
    Navigator.of(context).pop(); // hoặc chuyển về màn hình chính
  }

  num _calculateTotalAmount() {
    return widget.cartItems
        .fold<num>(0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  // Gợi ý sửa hàm _fetchDailySummary để truy vấn đúng kiểu dữ liệu Timestamp cho paymentDate và orderDate.
  // Giả sử bạn lưu orderDate, paymentDate là Timestamp trong Firestore.

  Future<void> _fetchDailySummary() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Đơn hàng
    final orderSnap = await FirebaseFirestore.instance
        .collection('orders')
        .where('orderDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('orderDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    int orderCount = orderSnap.docs.length;
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
