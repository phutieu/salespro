import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:intl/intl.dart';
import '../../admin/models/order.dart' as modelOrder;
import 'checkout_screen.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(customerData['storeName'] ?? 'Chi tiết khách hàng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Thông tin khách hàng
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildInfoCard(
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
          ),
          // Tiêu đề lịch sử đơn hàng
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.history, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Lịch sử đơn hàng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          // Danh sách đơn hàng
          Expanded(
            child: StreamBuilder<firestore.QuerySnapshot>(
              stream: firestore.FirebaseFirestore.instance
                  .collection('orders')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Debug: in ra số lượng documents
                print(
                    'Found ${snapshot.data!.docs.length} orders for customer $customerId');

                // Debug: in ra tất cả documents để kiểm tra
                for (final doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  print('Document ID: ${doc.id}');
                  print('Document data: $data');
                  print('Customer ID in document: ${data['customerId']}');
                  print('Current customer ID: $customerId');
                  print('---');
                }

                final orders = snapshot.data!.docs
                    .map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      print('Processing order: $data');
                      // Đảm bảo có id trong data
                      data['id'] = doc.id;
                      try {
                        return modelOrder.Order.fromMap(data);
                      } catch (e) {
                        print('Error parsing order: $e');
                        print('Order data: $data');
                        return null;
                      }
                    })
                    .where((order) => order != null)
                    .cast<modelOrder.Order>()
                    .toList();

                // Lọc theo customer ID
                final customerOrders = orders.where((order) {
                  // Kiểm tra nếu có customerId trong data gốc
                  final doc =
                      snapshot.data!.docs.firstWhere((d) => d.id == order.id);
                  final originalData = doc.data() as Map<String, dynamic>;
                  final matches = originalData['customerId'] == customerId;
                  print(
                      'Order ${order.id}: customerId=${originalData['customerId']}, currentCustomerId=$customerId, matches=$matches');
                  return matches;
                }).toList();

                print('Total orders: ${orders.length}');
                print('Customer orders: ${customerOrders.length}');
                if (customerOrders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('Chưa có đơn hàng nào',
                            style: TextStyle(fontSize: 18, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text('Customer ID: $customerId',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                // Sắp xếp theo ngày đặt hàng (mới nhất trước)
                customerOrders
                    .sort((a, b) => b.orderDate.compareTo(a.orderDate));

                return ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: customerOrders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final order = customerOrders[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => _showOrderDetail(context, order),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Dòng đầu: Ngày đặt hàng và trạng thái
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ngày đặt: ${DateFormat('dd/MM/yyyy').format(order.orderDate)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        'Giờ đặt: ${DateFormat('HH:mm').format(order.orderDate)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(order.status),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      _getStatusText(order.status),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Dòng thứ hai: Thông tin giao hàng và tổng tiền
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ngày giao: ${_getDeliveryDate(order)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '${order.items.length} sản phẩm',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Tổng tiền:',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        '${NumberFormat('#,###').format(order.totalAmount)}đ',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Tạo đơn hàng mới'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _ProductSelectScreen(
                        customerId: customerId,
                        customerData: customerData,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
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

  Color _getStatusColor(modelOrder.OrderStatus status) {
    switch (status) {
      case modelOrder.OrderStatus.Pending:
        return Colors.orange;
      case modelOrder.OrderStatus.Confirmed:
        return Colors.blue;
      case modelOrder.OrderStatus.Delivered:
        return Colors.green;
      case modelOrder.OrderStatus.Cancelled:
        return Colors.red;
      case modelOrder.OrderStatus.Return:
        return Colors.purple;
    }
  }

  String _getStatusText(modelOrder.OrderStatus status) {
    switch (status) {
      case modelOrder.OrderStatus.Pending:
        return 'Chờ xác nhận';
      case modelOrder.OrderStatus.Confirmed:
        return 'Đã xác nhận';
      case modelOrder.OrderStatus.Delivered:
        return 'Đã giao';
      case modelOrder.OrderStatus.Cancelled:
        return 'Đã hủy';
      case modelOrder.OrderStatus.Return:
        return 'Đã trả';
    }
  }

  String _getDeliveryDate(modelOrder.Order order) {
    switch (order.status) {
      case modelOrder.OrderStatus.Delivered:
        // Nếu đã giao, hiển thị ngày giao (giả sử là ngày đặt + 1-3 ngày)
        final deliveryDate = order.orderDate.add(const Duration(days: 2));
        return DateFormat('dd/MM/yyyy').format(deliveryDate);
      case modelOrder.OrderStatus.Cancelled:
        return 'Đã hủy';
      case modelOrder.OrderStatus.Confirmed:
        return 'Đang xử lý';
      case modelOrder.OrderStatus.Pending:
        return 'Chưa xác nhận';
      case modelOrder.OrderStatus.Return:
        return 'Đã trả';
    }
  }

  void _showOrderDetail(BuildContext context, modelOrder.Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chi tiết đơn hàng'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thông tin khách hàng
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customer.storeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Địa chỉ: ${order.customer.address}'),
                    Text('SĐT: ${order.customer.phoneNumber}'),
                    Text(
                        'Ngày đặt: ${DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate)}'),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(order.status),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Danh sách sản phẩm
              const Text(
                'Danh sách sản phẩm:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ...order.items.map((item) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                'Số lượng: ${item.quantity} ${item.product.unit}'),
                            Text(
                                'Giá: ${NumberFormat('#,###').format(item.unitPrice)}đ'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Thành tiền:'),
                            Text(
                              '${NumberFormat('#,###').format(item.quantity * item.unitPrice)}đ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
              const Divider(),
              // Tổng tiền
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng tiền:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '${NumberFormat('#,###').format(order.totalAmount)}đ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

// Tạo màn hình chọn sản phẩm cho khách hàng
class _ProductSelectScreen extends StatefulWidget {
  final String customerId;
  final Map<String, dynamic> customerData;
  const _ProductSelectScreen(
      {required this.customerId, required this.customerData});
  @override
  State<_ProductSelectScreen> createState() => _ProductSelectScreenState();
}

class _ProductSelectScreenState extends State<_ProductSelectScreen> {
  final Map<String, int> _quantities = {};
  final Map<String, String> _units = {};
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chọn sản phẩm')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm ...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _search = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<firestore.QuerySnapshot>(
              stream: firestore.FirebaseFirestore.instance
                  .collection('products')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final code = (data['id'] ?? '').toString().toLowerCase();
                  return _search.isEmpty ||
                      name.contains(_search) ||
                      code.contains(_search);
                }).toList();
                if (docs.isEmpty) {
                  return const Center(child: Text('Không có sản phẩm nào'));
                }
                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final id = docs[index].id;
                    final price = (data['salePrice'] ?? 0) as num;
                    final quantity = _quantities[id] ?? 0;
                    final unit = _units[id] ?? (data['unit'] ?? 'HỘP');
                    final total = price * quantity;
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${data['name'] ?? ''} - ${data['id'] ?? ''}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                DropdownButton<String>(
                                  value: unit,
                                  items: [(data['unit'] ?? 'HỘP') as String]
                                      .map((u) => DropdownMenuItem<String>(
                                          value: u, child: Text(u)))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _units[id] = value!;
                                    });
                                  },
                                ),
                                const SizedBox(width: 12),
                                const Text('Số lượng:'),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: quantity > 0
                                      ? () => setState(
                                          () => _quantities[id] = quantity - 1)
                                      : null,
                                ),
                                Container(
                                  width: 32,
                                  alignment: Alignment.center,
                                  child: Text('$quantity',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => setState(
                                      () => _quantities[id] = quantity + 1),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Text('Tồn kho NPP:'),
                                const SizedBox(width: 4),
                                Text('${data['stockQuantity'] ?? 0}'),
                                const Spacer(),
                                const Text('Đơn giá:'),
                                const SizedBox(width: 4),
                                Container(
                                  width: 100,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey[400]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                      NumberFormat('#,###').format(price),
                                      textAlign: TextAlign.right),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              children: [
                                const Text('Tổng tiền:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Text(NumberFormat('#,###').format(total)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                    onPressed: () {
                      // Lấy lại snapshot sản phẩm để lấy docs
                      final stream = firestore.FirebaseFirestore.instance
                          .collection('products')
                          .snapshots();
                      stream.first.then((snapshot) {
                        final docs = snapshot.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name =
                              (data['name'] ?? '').toString().toLowerCase();
                          final code =
                              (data['id'] ?? '').toString().toLowerCase();
                          return _search.isEmpty ||
                              name.contains(_search) ||
                              code.contains(_search);
                        }).toList();
                        final cartItems = <Map<String, dynamic>>[];
                        for (final entry in _quantities.entries) {
                          if (entry.value > 0) {
                            final doc =
                                docs.firstWhere((d) => d.id == entry.key);
                            final data = doc.data() as Map<String, dynamic>;
                            cartItems.add({
                              'id': doc.id,
                              'name': data['name'],
                              'price': data['salePrice'],
                              'quantity': entry.value,
                              'unit': _units[doc.id] ?? data['unit'] ?? 'HỘP',
                            });
                          }
                        }
                        if (cartItems.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Vui lòng chọn ít nhất 1 sản phẩm!')),
                          );
                          return;
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CheckoutScreen(
                              cartItems: cartItems,
                              customerId: widget.customerId,
                              customerData: widget.customerData,
                            ),
                          ),
                        );
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                            '${_quantities.values.fold<int>(0, (sum, q) => sum + (q > 0 ? 1 : 0))} Sản phẩm'),
                        const SizedBox(width: 8),
                        const Icon(Icons.shopping_cart_outlined),
                        const SizedBox(width: 8),
                        Text(
                            '${_quantities.values.fold<int>(0, (sum, q) => sum + q)}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
