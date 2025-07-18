import 'package:salespro/admin/models/product.dart';

class OrderItem {
  final Product product;
  int quantity;
  double unitPrice; // Giá bán tại thời điểm đặt hàng

  OrderItem({
    required this.product,
    required this.quantity,
    required this.unitPrice,
  });

  double get totalPrice => quantity * unitPrice;

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      product: map['product'] is Map<String, dynamic>
          ? Product.fromMap(map['product'])
          : Product.fromMap({}),
      quantity: map['quantity'] ?? 0,
      unitPrice: (map['unitPrice'] is int)
          ? (map['unitPrice'] as int).toDouble()
          : (map['unitPrice'] ?? 0.0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product': product.toMap(),
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }
}
