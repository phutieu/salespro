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
}
