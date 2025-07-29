import 'package:salespro/admin/models/customer.dart';
import 'package:salespro/admin/models/order_item.dart';
import 'package:salespro/admin/models/payment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] ?? '',
      customer: map['customer'] is Map<String, dynamic>
          ? Customer.fromMap({
              ...map['customer'],
              'id': map['customerId'] ?? map['customer']['id'] ?? '',
              'storeName': map['customer']['storeName'] ?? '',
              'address': map['customer']['address'] ?? '',
              'contactPerson': map['customer']['contactPerson'] ?? '',
              'phoneNumber': map['customer']['phoneNumber'] ?? '',
              'area': map['customer']['area'] ?? '',
            })
          : Customer.fromMap({
              'id': map['customerId'] ?? '',
              'storeName': '',
              'address': '',
              'contactPerson': '',
              'phoneNumber': '',
              'area': '',
            }),
      items: (map['items'] as List<dynamic>? ?? [])
          .map((item) => item is Map<String, dynamic>
              ? OrderItem.fromMap(item)
              : OrderItem.fromMap({}))
          .toList(),
      payments: (map['payments'] as List<dynamic>? ?? [])
          .map((p) => p is Map<String, dynamic>
              ? Payment.fromMap(p)
              : Payment.fromMap({}))
          .toList(),
      orderDate: map['orderDate'] != null
          ? (map['orderDate'] is Timestamp
              ? (map['orderDate'] as Timestamp).toDate()
              : DateTime.tryParse(map['orderDate'].toString()) ??
                  DateTime.now())
          : DateTime.now(),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == 'OrderStatus.' + (map['status'] ?? 'Pending'),
        orElse: () => OrderStatus.Pending,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customer.id,
      'customer': customer.toMap(),
      'items': items.map((item) => item.toMap()).toList(),
      'payments': payments.map((p) => p.toMap()).toList(),
      'orderDate': orderDate.toIso8601String(),
      'status': status.toString().split('.').last,
    };
  }
}
