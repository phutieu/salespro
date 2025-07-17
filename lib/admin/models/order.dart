import 'package:salespro/admin/models/customer.dart';
import 'package:salespro/admin/models/order_item.dart';
import 'package:salespro/admin/models/payment.dart';

enum OrderStatus { Pending, Confirmed, Delivered, Cancelled }

enum PaymentStatus { Unpaid, PartiallyPaid, Paid }

class Order {
  final String id;
  final Customer customer;
  final List<OrderItem> items;
  final List<Payment> payments;
  final DateTime orderDate;
  OrderStatus status;

  double get totalAmount {
    return items.fold(0, (sum, item) => sum + item.totalPrice);
  }

  double get amountPaid {
    return payments.fold(0, (sum, payment) => sum + payment.amount);
  }

  double get amountDue => totalAmount - amountPaid;

  PaymentStatus get paymentStatus {
    if (amountPaid <= 0) {
      return PaymentStatus.Unpaid;
    } else if (amountPaid < totalAmount) {
      return PaymentStatus.PartiallyPaid;
    } else {
      return PaymentStatus.Paid;
    }
  }

  Order({
    required this.id,
    required this.customer,
    required this.items,
    required this.orderDate,
    this.status = OrderStatus.Pending,
    this.payments = const [],
  });
}
