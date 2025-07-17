import 'package:flutter/material.dart';
import 'package:salespro/admin/mock_data.dart';
import 'package:salespro/admin/models/customer.dart';
import 'package:salespro/admin/widgets/customer_form.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  late List<Customer> _customers;

  @override
  void initState() {
    super.initState();
    _customers = List.from(mockCustomers);
  }

  void _showCustomerForm(BuildContext context, {Customer? customer}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomerForm(
          customer: customer,
          onSave: (savedCustomer) {
            setState(() {
              if (customer == null) {
                _customers.add(savedCustomer);
              } else {
                final index =
                    _customers.indexWhere((c) => c.id == savedCustomer.id);
                if (index != -1) {
                  _customers[index] = savedCustomer;
                }
              }
            });
          },
        );
      },
    );
  }

  void _deleteCustomer(String customerId) {
    setState(() {
      _customers.removeWhere((c) => c.id == customerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customers',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              _showCustomerForm(context);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Customer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Customer ID')),
                  DataColumn(label: Text('Store Name')),
                  DataColumn(label: Text('Phone Number')),
                  DataColumn(label: Text('Area')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _customers.map((customer) {
                  return DataRow(cells: [
                    DataCell(Text(customer.id)),
                    DataCell(Text(customer.storeName)),
                    DataCell(Text(customer.phoneNumber)),
                    DataCell(Text(customer.area)),
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            _showCustomerForm(context, customer: customer);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _deleteCustomer(customer.id);
                          },
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
