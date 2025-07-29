import 'package:cloud_firestore/cloud_firestore.dart';

class ReturnItem {
  final String productId;
  final String productName;
  final int quantity;
  final String reason;

  ReturnItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.reason,
  });

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'reason': reason,
      };

  factory ReturnItem.fromMap(Map<String, dynamic> map) => ReturnItem(
        productId: map['productId'] ?? '',
        productName: map['productName'] ?? '',
        quantity: map['quantity'] ?? 0,
        reason: map['reason'] ?? '',
      );
}

class ReturnRecord {
  final String id;
  final String orderId;
  final String userId;
  final String customerId;
  final List<ReturnItem> items;
  final DateTime createdAt;

  ReturnRecord({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.customerId,
    required this.items,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'orderId': orderId,
        'userId': userId,
        'customerId': customerId,
        'items': items.map((e) => e.toMap()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory ReturnRecord.fromMap(Map<String, dynamic> map) => ReturnRecord(
        id: map['id'] ?? '',
        orderId: map['orderId'] ?? '',
        userId: map['userId'] ?? '',
        customerId: map['customerId'] ?? '',
        items: (map['items'] as List<dynamic>? ?? [])
            .map((e) => ReturnItem.fromMap(e as Map<String, dynamic>))
            .toList(),
        createdAt: map['createdAt'] is Timestamp
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
}
