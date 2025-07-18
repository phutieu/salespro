import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salespro/admin/models/customer.dart';
import 'package:salespro/admin/widgets/customer_form.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  void _showCustomerForm(BuildContext context, {DocumentSnapshot? doc}) {
    Customer? customer;
    if (doc != null) {
      final data = doc.data() as Map<String, dynamic>;
      customer = Customer.fromMap(data..['id'] = doc.id);
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomerForm(
          customer: customer,
          onSave: (savedCustomer) async {
            if (doc == null) {
              await FirebaseFirestore.instance
                  .collection('customers')
                  .add(savedCustomer.toMap());
            } else {
              await FirebaseFirestore.instance
                  .collection('customers')
                  .doc(doc.id)
                  .update(savedCustomer.toMap());
            }
            setState(() {});
          },
        );
      },
    );
  }

  void _deleteCustomer(String docId) async {
    await FirebaseFirestore.instance
        .collection('customers')
        .doc(docId)
        .delete();
    setState(() {});
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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('customers')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return DataTable(
                  columns: const [
                    DataColumn(label: Text('Customer ID')),
                    DataColumn(label: Text('Store Name')),
                    DataColumn(label: Text('Phone Number')),
                    DataColumn(label: Text('Area')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final customer = Customer.fromMap(data..['id'] = doc.id);
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
                              _showCustomerForm(context, doc: doc);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _deleteCustomer(doc.id);
                            },
                          ),
                        ],
                      )),
                    ]);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
