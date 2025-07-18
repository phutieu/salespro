import 'package:salespro/admin/models/purchase_order_item.dart';

enum PurchaseOrderStatus { Ordered, Received }

class PurchaseOrder {
  final String id;
  final String supplier; // Nhà cung cấp
  final DateTime orderDate;
  final List<PurchaseOrderItem> items;
  PurchaseOrderStatus status;

  PurchaseOrder({
    required this.id,
    required this.supplier,
    required this.orderDate,
    required this.items,
    this.status = PurchaseOrderStatus.Ordered,
  });

  factory PurchaseOrder.fromMap(Map<String, dynamic> map) {
    return PurchaseOrder(
      id: map['id'] ?? '',
      supplier: map['supplier'] ?? '',
      orderDate: map['orderDate'] != null
          ? DateTime.tryParse(map['orderDate']) ?? DateTime.now()
          : DateTime.now(),
      items: (map['items'] as List<dynamic>? ?? [])
          .map((item) => item is Map<String, dynamic>
              ? PurchaseOrderItem.fromMap(item)
              : PurchaseOrderItem.fromMap({}))
          .toList(),
      status: PurchaseOrderStatus.values.firstWhere(
        (e) =>
            e.toString() ==
            'PurchaseOrderStatus.' + (map['status'] ?? 'Ordered'),
        orElse: () => PurchaseOrderStatus.Ordered,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplier': supplier,
      'orderDate': orderDate.toIso8601String(),
      'items': items.map((item) => item.toMap()).toList(),
      'status': status.toString().split('.').last,
    };
  }
}
