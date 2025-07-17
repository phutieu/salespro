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
}
