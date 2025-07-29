import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salespro/admin/models/purchase_order.dart';
import 'package:salespro/admin/models/product.dart';
import 'package:salespro/admin/models/purchase_order_item.dart';

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
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Tạo đơn nhập mới'),
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) => const _PurchaseOrderFormDialog(),
                );
                setState(() {});
              },
            ),
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
                if (docs.isEmpty) {
                  return const Center(
                      child: Text('Chưa có phiếu nhập kho nào'));
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Mã đơn')),
                      DataColumn(label: Text('Nhà cung cấp')),
                      DataColumn(label: Text('Ngày tạo')),
                      DataColumn(label: Text('Trạng thái')),
                      DataColumn(label: Text('Tổng tiền')),
                      DataColumn(label: Text('Hành động')),
                    ],
                    rows: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final order =
                          PurchaseOrder.fromMap(data..['id'] = doc.id);
                      final total = order.items.fold<num>(
                          0,
                          (sum, item) =>
                              sum + (item.quantity * item.purchasePrice));
                      return DataRow(cells: [
                        DataCell(Text(order.id)),
                        DataCell(Text(order.supplier)),
                        DataCell(Text(
                            DateFormat('dd/MM/yyyy').format(order.orderDate))),
                        DataCell(Row(
                          children: [
                            Icon(
                              order.status == PurchaseOrderStatus.Received
                                  ? Icons.check_circle
                                  : Icons.pending,
                              color:
                                  order.status == PurchaseOrderStatus.Received
                                      ? Colors.green
                                      : Colors.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            DropdownButton<PurchaseOrderStatus>(
                              value: order.status,
                              underline: const SizedBox(),
                              items: [
                                DropdownMenuItem(
                                  value: PurchaseOrderStatus.Ordered,
                                  child: const Text('Ordered'),
                                ),
                                DropdownMenuItem(
                                  value: PurchaseOrderStatus.Received,
                                  child: const Text('Received'),
                                ),
                              ],
                              onChanged: (newStatus) async {
                                if (newStatus != null &&
                                    newStatus != order.status) {
                                  await FirebaseFirestore.instance
                                      .collection('purchase_orders')
                                      .doc(order.id)
                                      .update({
                                    'status':
                                        newStatus.toString().split('.').last
                                  });
                                  // Nếu chuyển từ Ordered sang Received thì cập nhật tồn kho
                                  if (order.status ==
                                          PurchaseOrderStatus.Ordered &&
                                      newStatus ==
                                          PurchaseOrderStatus.Received) {
                                    for (final item in order.items) {
                                      final productId = item.product.id;
                                      final qtyToAdd = item.quantity;
                                      final productRef = FirebaseFirestore
                                          .instance
                                          .collection('products')
                                          .doc(productId);
                                      await FirebaseFirestore.instance
                                          .runTransaction((transaction) async {
                                        final snapshot =
                                            await transaction.get(productRef);
                                        final currentStock = (snapshot
                                                .data()?['stockQuantity'] ??
                                            0) as int;
                                        transaction.update(productRef, {
                                          'stockQuantity':
                                              currentStock + qtyToAdd
                                        });
                                      });
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        )),
                        DataCell(Text(
                            NumberFormat.decimalPattern('vi_VN').format(total) +
                                'đ')),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_red_eye),
                              tooltip: 'Xem chi tiết',
                              onPressed: () => _showOrderDetail(context, order),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Sửa',
                              onPressed: () =>
                                  _showEditOrderForm(context, doc, order),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: 'Xóa',
                              onPressed: () =>
                                  _confirmDeleteOrder(context, doc.id),
                            ),
                          ],
                        )),
                      ]);
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

  void _showOrderDetail(BuildContext context, PurchaseOrder order) {
    final total = order.items.fold<num>(
        0, (sum, item) => sum + (item.quantity * item.purchasePrice));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết đơn nhập: ${order.id}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nhà cung cấp: ${order.supplier}'),
              Text(
                  'Ngày tạo: ${DateFormat('dd/MM/yyyy').format(order.orderDate)}'),
              Text(
                  'Trạng thái: ${order.status == PurchaseOrderStatus.Received ? 'Received' : 'Ordered'}'),
              const SizedBox(height: 8),
              const Text('Danh sách sản phẩm:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...order.items.map((item) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(item.product.name)),
                      Text(
                          '${item.quantity} x ${NumberFormat.decimalPattern('vi_VN').format(item.purchasePrice)}đ'),
                      Text(
                          '= ${NumberFormat.decimalPattern('vi_VN').format(item.quantity * item.purchasePrice)}đ'),
                    ],
                  )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('Tổng tiền: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${NumberFormat.decimalPattern('vi_VN').format(total)}đ',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
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

  void _showEditOrderForm(
      BuildContext context, DocumentSnapshot doc, PurchaseOrder order) async {
    await showDialog(
      context: context,
      builder: (context) => _PurchaseOrderFormDialog(
        initialOrder: order,
        docId: doc.id,
      ),
    );
    setState(() {});
  }

  void _confirmDeleteOrder(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa đơn nhập này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('purchase_orders')
                  .doc(docId)
                  .delete();
              if (mounted) Navigator.of(context).pop();
              setState(() {});
            },
            child: const Text('Xóa'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
}

class _PurchaseOrderFormDialog extends StatefulWidget {
  final PurchaseOrder? initialOrder;
  final String? docId;

  const _PurchaseOrderFormDialog({Key? key, this.initialOrder, this.docId})
      : super(key: key);

  @override
  State<_PurchaseOrderFormDialog> createState() =>
      _PurchaseOrderFormDialogState();
}

class _PurchaseOrderFormDialogState extends State<_PurchaseOrderFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _supplierController = TextEditingController();
  final List<_OrderItemInput> _items = [];
  bool _isSaving = false;

  double get _totalAmount =>
      _items.fold(0, (sum, item) => sum + (item.quantity * item.purchasePrice));

  void _addItem() {
    setState(() {
      _items.add(_OrderItemInput());
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate() || _items.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final orderData = {
        'supplier': _supplierController.text.trim(),
        'orderDate': DateTime.now().toIso8601String(),
        'items': _items.map((item) => item.toMap()).toList(),
        'status': 'Ordered',
      };
      if (widget.docId == null) {
        // Tạo mới
        final docRef = await FirebaseFirestore.instance
            .collection('purchase_orders')
            .add(orderData);
        await docRef.update({'id': docRef.id});
      } else {
        // Sửa
        await FirebaseFirestore.instance
            .collection('purchase_orders')
            .doc(widget.docId)
            .update({
          ...orderData,
          'id': widget.docId,
        });
      }
      if (mounted) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Lưu đơn nhập thành công!'),
          backgroundColor: Colors.green));
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Lỗi lưu đơn nhập: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialOrder != null) {
      _supplierController.text = widget.initialOrder!.supplier;
      _items.addAll(widget.initialOrder!.items
          .map((item) => _OrderItemInput.fromPurchaseOrderItem(item)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: widget.initialOrder == null
          ? const Text('Tạo đơn nhập mới')
          : const Text('Sửa đơn nhập'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _supplierController,
                decoration: const InputDecoration(labelText: 'Nhà cung cấp'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Nhập tên nhà cung cấp'
                    : null,
              ),
              const SizedBox(height: 12),
              ..._items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        _ProductAutocompleteField(
                          controller: item.productController,
                          onProductSelected: (product) =>
                              item.selectedProduct = product,
                          initialProduct: item.selectedProduct,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: item.quantityController,
                                decoration: const InputDecoration(
                                    labelText: 'Số lượng'),
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    (int.tryParse(v ?? '') ?? 0) > 0
                                        ? null
                                        : 'Nhập số lượng',
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: item.priceController,
                                decoration: const InputDecoration(
                                    labelText: 'Giá nhập'),
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    (double.tryParse(v ?? '') ?? 0) > 0
                                        ? null
                                        : 'Nhập giá',
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeItem(idx),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Thêm sản phẩm'),
                onPressed: _addItem,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('Tổng tiền: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${_totalAmount.toStringAsFixed(0)} ₫',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveOrder,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Lưu'),
        ),
      ],
    );
  }
}

class _OrderItemInput {
  Product? selectedProduct;
  final TextEditingController productController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  _OrderItemInput();

  int get quantity => int.tryParse(quantityController.text) ?? 0;
  double get purchasePrice => double.tryParse(priceController.text) ?? 0;

  Map<String, dynamic> toMap() {
    return {
      'product': selectedProduct?.toMap() ?? {},
      'quantity': quantity,
      'purchasePrice': purchasePrice,
    };
  }

  factory _OrderItemInput.fromPurchaseOrderItem(PurchaseOrderItem item) {
    final input = _OrderItemInput();
    input.selectedProduct = item.product;
    input.productController.text =
        item.product.name; // Đảm bảo luôn set tên sản phẩm
    input.quantityController.text = item.quantity.toString();
    input.priceController.text = item.purchasePrice.toString();
    return input;
  }
}

class _ProductAutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<Product> onProductSelected;
  final Product? initialProduct;
  const _ProductAutocompleteField(
      {required this.controller,
      required this.onProductSelected,
      this.initialProduct,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final products = snapshot.data!.docs
            .map((doc) => Product.fromMap(
                doc.data() as Map<String, dynamic>..['id'] = doc.id))
            .toList();
        // Nếu có initialProduct và controller chưa có text, set text luôn
        if (initialProduct != null &&
            (controller.text.isEmpty ||
                controller.text != initialProduct!.name)) {
          controller.text = initialProduct!.name;
        }
        return Autocomplete<Product>(
          displayStringForOption: (p) => p.name,
          initialValue: TextEditingValue(text: controller.text),
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty)
              return const Iterable<Product>.empty();
            return products.where((p) => p.name
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase()));
          },
          onSelected: (product) {
            controller.text = product.name;
            onProductSelected(product);
          },
          fieldViewBuilder:
              (context, textController, focusNode, onFieldSubmitted) {
            textController.text = controller.text;
            return TextFormField(
              controller: textController,
              focusNode: focusNode,
              decoration: const InputDecoration(labelText: 'Sản phẩm'),
              validator: (v) => v == null || v.isEmpty ? 'Chọn sản phẩm' : null,
            );
          },
        );
      },
    );
  }
}
