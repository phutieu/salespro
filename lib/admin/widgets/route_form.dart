import 'package:flutter/material.dart';
import 'package:salespro/admin/models/customer.dart';
import 'package:salespro/admin/models/sales_route.dart';
import 'package:salespro/admin/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RouteForm extends StatefulWidget {
  final SalesRoute? route;
  final Function(SalesRoute) onSave;

  const RouteForm({super.key, this.route, required this.onSave});

  @override
  _RouteFormState createState() => _RouteFormState();
}

class _RouteFormState extends State<RouteForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late List<Customer> _selectedCustomers;
  User? _selectedSalesperson;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.route?.name ?? '');
    _selectedCustomers = widget.route?.customers ?? [];
    _selectedSalesperson = widget.route?.salesperson;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.route == null ? 'Add Route' : 'Edit Route'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Route Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter route name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Dropdown chọn nhân viên bán hàng (User role Sales)
              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'Sales')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const CircularProgressIndicator();
                  final docs = snapshot.data!.docs;
                  final availableSalespeople = docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return User.fromMap(data..['id'] = doc.id);
                  }).toList();
                  return DropdownButtonFormField<User>(
                    value: _selectedSalesperson,
                    decoration: const InputDecoration(labelText: 'Salesperson'),
                    items: availableSalespeople.map((user) {
                      return DropdownMenuItem<User>(
                        value: user,
                        child: Text(user.name),
                      );
                    }).toList(),
                    onChanged: (User? newValue) {
                      setState(() {
                        _selectedSalesperson = newValue;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Please select a salesperson' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              // Lấy danh sách khách hàng từ Firestore
              StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('customers')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const CircularProgressIndicator();
                  final docs = snapshot.data!.docs;
                  final availableCustomers = docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Customer.fromMap(data..['id'] = doc.id);
                  }).toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select Customers'),
                      Wrap(
                        children: availableCustomers.map((customer) {
                          final isSelected = _selectedCustomers
                              .any((c) => c.id == customer.id);
                          return FilterChip(
                            label: Text(customer.storeName),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedCustomers.add(customer);
                                } else {
                                  _selectedCustomers
                                      .removeWhere((c) => c.id == customer.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: const Text('Save'),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newRoute = SalesRoute(
                id: widget.route?.id ?? '',
                name: _nameController.text,
                salesperson: _selectedSalesperson!,
                customers: _selectedCustomers,
              );
              widget.onSave(newRoute);
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}
