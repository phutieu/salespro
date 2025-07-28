import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../admin/models/order.dart';

class CustomerDetailScreen extends StatelessWidget {
  final String customerId;
  final Map<String, dynamic> customerData;

  const CustomerDetailScreen({
    super.key,
    required this.customerId,
    required this.customerData,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(customerData['storeName'] ?? 'Chi tiết khách hàng'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Thông tin'),
              Tab(text: 'Lịch sử đơn hàng'),
            ],
            labelColor: Colors.black,
            indicatorColor: Colors.blue,
          ),
        ),
        body: TabBarView(
          children: [
            _buildInfoTab(),
            _buildOrderHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            'Thông tin cửa hàng',
            [
              _buildInfoRow('Tên cửa hàng:', customerData['storeName'] ?? ''),
              _buildInfoRow('Mã khách hàng:', customerData['code'] ?? ''),
              _buildInfoRow('Địa chỉ:', customerData['address'] ?? ''),
              _buildInfoRow(
                  'Số điện thoại:', customerData['phoneNumber'] ?? ''),
              _buildInfoRow('Khu vực:', customerData['area'] ?? ''),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('customerId', isEqualTo: customerId)
                .snapshots(),
            builder: (context, snapshot) {
              int totalOrders = 0;
              double totalRevenue = 0;
              double totalDebt = 0;

              if (snapshot.hasData) {
                final orders = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Order.fromMap(data..['id'] = doc.id);
                }).toList();

                totalOrders = orders.length;
                totalRevenue =
                    orders.fold(0, (sum, order) => sum + order.totalAmount);
                totalDebt =
                    orders.fold(0, (sum, order) => sum + order.amountDue);
              }

              return _buildInfoCard(
                'Thống kê',
                [
                  _buildInfoRow('Tổng đơn hàng:', '$totalOrders'),
                  _buildInfoRow('Doanh số:',
                      '${NumberFormat('#,###').format(totalRevenue)}₫'),
                  _buildInfoRow('Công nợ:',
                      '${NumberFormat('#,###').format(totalDebt)}₫'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('customerId', isEqualTo: customerId) // Query theo customerId
          .orderBy('orderDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          data['customerId'] = customerId; // Đảm bảo có customerId
          data['customer'] = customerData; // Sử dụng customerData từ props
          return Order.fromMap(data);
        }).toList();

        if (orders.isEmpty) {
          return const Center(child: Text('Chưa có đơn hàng nào'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Row(
                  children: [
                    Text('#${order.id.substring(0, 8)}'),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order.status.toString().split('.').last,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('dd/MM/yyyy').format(order.orderDate)),
                    Text(
                      '${order.items.length} sản phẩm - ${NumberFormat('#,###').format(order.totalAmount)}₫',
                    ),
                  ],
                ),
                trailing: Icon(
                  Icons.circle,
                  size: 12,
                  color: order.paymentStatus == PaymentStatus.Paid
                      ? Colors.green
                      : order.paymentStatus == PaymentStatus.PartiallyPaid
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.Pending:
        return Colors.orange;
      case OrderStatus.Confirmed:
        return Colors.blue;
      case OrderStatus.Delivered:
        return Colors.green;
      case OrderStatus.Cancelled:
        return Colors.red;
    }
  }
}
    }
  }
}
