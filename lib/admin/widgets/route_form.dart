import 'package:flutter/material.dart';
import 'package:salespro/admin/models/customer.dart';
import 'package:salespro/admin/models/sales_route.dart';
import 'package:salespro/admin/models/user.dart';
import 'package:salespro/admin/mock_data.dart';
import 'dart:math';

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
  late User _selectedSalesperson;
  late List<Customer> _selectedCustomers;

  final List<User> _availableSalespeople = mockUsers
      .where((user) => user.role == UserRole.Sales && user.isActive)
      .toList();
  final List<Customer> _availableCustomers = List.from(mockCustomers);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.route?.name ?? '');
    _selectedSalesperson =
        widget.route?.salesperson ?? _availableSalespeople.first;
    _selectedCustomers = widget.route?.customers ?? [];
  }

  void _showCustomerSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final tempSelectedCustomers = List<Customer>.from(_selectedCustomers);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Customers'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  itemCount: _availableCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = _availableCustomers[index];
                    final isSelected =
                        tempSelectedCustomers.any((c) => c.id == customer.id);
                    return CheckboxListTile(
                      title: Text(customer.storeName),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            tempSelectedCustomers.add(customer);
                          } else {
                            tempSelectedCustomers
                                .removeWhere((c) => c.id == customer.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedCustomers = tempSelectedCustomers;
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.route == null ? 'Create Route' : 'Edit Route'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Route Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
              ),
              DropdownButtonFormField<User>(
                value: _selectedSalesperson,
                decoration: const InputDecoration(labelText: 'Salesperson'),
                items: _availableSalespeople.map((User user) {
                  return DropdownMenuItem<User>(
                    value: user,
                    child: Text(user.name),
                  );
                }).toList(),
                onChanged: (User? newValue) {
                  setState(() {
                    _selectedSalesperson = newValue!;
                  });
                },
              ),
              const SizedBox(height: 20),
              ListTile(
                title: const Text('Customers'),
                subtitle: Text('${_selectedCustomers.length} selected'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _showCustomerSelectionDialog,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newRoute = SalesRoute(
                id: widget.route?.id ??
                    'T${Random().nextInt(100).toString().padLeft(2, '0')}',
                name: _nameController.text,
                salesperson: _selectedSalesperson,
                customers: _selectedCustomers,
              );
              widget.onSave(newRoute);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
