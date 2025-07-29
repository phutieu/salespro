import 'package:flutter/material.dart';
import 'package:salespro/admin/models/customer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class CustomerForm extends StatefulWidget {
  final Customer? customer;
  final Function(Customer) onSave;

  const CustomerForm({super.key, this.customer, required this.onSave});

  @override
  _CustomerFormState createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _storeNameController;
  late TextEditingController _addressController;
  late TextEditingController _contactPersonController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _areaController;

  @override
  void initState() {
    super.initState();
    _storeNameController =
        TextEditingController(text: widget.customer?.storeName ?? '');
    _addressController =
        TextEditingController(text: widget.customer?.address ?? '');
    _contactPersonController =
        TextEditingController(text: widget.customer?.contactPerson ?? '');
    _phoneNumberController =
        TextEditingController(text: widget.customer?.phoneNumber ?? '');
    _areaController = TextEditingController(text: widget.customer?.area ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.customer == null ? 'Add Customer' : 'Edit Customer'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _storeNameController,
                decoration: const InputDecoration(labelText: 'Store Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter store name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextFormField(
                controller: _contactPersonController,
                decoration: const InputDecoration(labelText: 'Contact Person'),
              ),
              TextFormField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: _areaController,
                decoration: const InputDecoration(labelText: 'Area / Route'),
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
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              if (widget.customer == null) {
                // Tạo khách hàng mới
                final doc = await FirebaseFirestore.instance
                    .collection('customers')
                    .add({
                  'storeName': _storeNameController.text,
                  'address': _addressController.text,
                  'contactPerson': _contactPersonController.text,
                  'phoneNumber': _phoneNumberController.text,
                  'area': _areaController.text,
                  'visited': false,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                // Cập nhật id
                await doc.update({'id': doc.id});

                final newCustomer = Customer(
                  id: doc.id,
                  storeName: _storeNameController.text,
                  address: _addressController.text,
                  contactPerson: _contactPersonController.text,
                  phoneNumber: _phoneNumberController.text,
                  area: _areaController.text,
                  visited: false,
                );
                widget.onSave(newCustomer);
              } else {
                // Cập nhật khách hàng hiện có
                final updatedCustomer = Customer(
                  id: widget.customer!.id,
                  storeName: _storeNameController.text,
                  address: _addressController.text,
                  contactPerson: _contactPersonController.text,
                  phoneNumber: _phoneNumberController.text,
                  area: _areaController.text,
                  visited: widget.customer!.visited,
                );
                widget.onSave(updatedCustomer);
              }
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}
