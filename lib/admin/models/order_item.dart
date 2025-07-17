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
}
