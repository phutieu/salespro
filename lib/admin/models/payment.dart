import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentMethod { Cash, BankTransfer, Other }

class Payment {
  final String id;
  final String orderId; // To link payment to an order
  final double amount;
  final DateTime paymentDate;
  final PaymentMethod method;

  Payment({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.paymentDate,
    required this.method,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] ?? '',
      orderId: map['orderId'] ?? '',
      amount: (map['amount'] is int)
          ? (map['amount'] as int).toDouble()
          : (map['amount'] ?? 0.0),
      paymentDate: map['paymentDate'] != null
          ? (map['paymentDate'] is Timestamp
              ? (map['paymentDate'] as Timestamp).toDate()
              : DateTime.tryParse(map['paymentDate'].toString()) ??
                  DateTime.now())
          : DateTime.now(),
      method: PaymentMethod.values.firstWhere(
        (e) => e.toString() == 'PaymentMethod.' + (map['method'] ?? 'Cash'),
        orElse: () => PaymentMethod.Cash,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'method': method.toString().split('.').last,
    };
  }
}
