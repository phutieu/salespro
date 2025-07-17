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
}
