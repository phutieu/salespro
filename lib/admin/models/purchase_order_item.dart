import 'package:salespro/admin/models/product.dart';

class PurchaseOrderItem {
  final Product product;
  final int quantity;
  final double purchasePrice; // Giá tại thời điểm nhập hàng

  PurchaseOrderItem({
    required this.product,
    required this.quantity,
    required this.purchasePrice,
  });
}
