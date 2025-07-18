import 'package:salespro/admin/models/customer.dart';
import 'package:salespro/admin/models/user.dart';

class SalesRoute {
  final String id;
  String name;
  User salesperson;
  List<Customer> customers;

  SalesRoute({
    required this.id,
    required this.name,
    required this.salesperson,
    required this.customers,
  });

  factory SalesRoute.fromMap(Map<String, dynamic> map) {
    return SalesRoute(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      salesperson: map['salesperson'] is Map<String, dynamic>
          ? User.fromMap(map['salesperson'])
          : User.fromMap({}),
      customers: (map['customers'] as List<dynamic>? ?? [])
          .map((c) => c is Map<String, dynamic>
              ? Customer.fromMap(c)
              : Customer.fromMap({}))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'salesperson': salesperson.toMap(),
      'customers': customers.map((c) => c.toMap()).toList(),
    };
  }
}
