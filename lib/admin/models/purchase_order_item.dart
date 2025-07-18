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

  factory PurchaseOrderItem.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderItem(
      product: map['product'] is Map<String, dynamic>
          ? Product.fromMap(map['product'])
          : Product.fromMap({}),
      quantity: map['quantity'] ?? 0,
      purchasePrice: (map['purchasePrice'] is int)
          ? (map['purchasePrice'] as int).toDouble()
          : (map['purchasePrice'] ?? 0.0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product': product.toMap(),
      'quantity': quantity,
      'purchasePrice': purchasePrice,
    };
  }
}
