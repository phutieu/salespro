import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:salespro/admin/mock_data.dart';
import 'package:salespro/admin/models/customer.dart';
import 'package:salespro/admin/models/order.dart';
import 'package:intl/intl.dart';

class DebtListScreen extends StatelessWidget {
  const DebtListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Calculate debt for each customer
    final Map<Customer, double> customerDebts = {};
    for (var order in mockOrders) {
      if (order.status != OrderStatus.Cancelled) {
        customerDebts.update(
          order.customer,
          (value) => value + order.amountDue,
          ifAbsent: () => order.amountDue,
        );
      }
    }

    final debts = customerDebts.entries.toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Debt & Payment Management',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Customer')),
                  DataColumn(label: Text('Phone Number')),
                  DataColumn(label: Text('Total Debt')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: debts.map((entry) {
                  final customer = entry.key;
                  final totalDebt = entry.value;
                  return DataRow(cells: [
                    DataCell(Text(customer.storeName)),
                    DataCell(Text(customer.phoneNumber)),
                    DataCell(
                      Text(
                        '${NumberFormat.decimalPattern('vi_VN').format(totalDebt)} ₫',
                        style: TextStyle(
                          color: totalDebt > 0 ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataCell(IconButton(
                      icon: const Icon(Icons.receipt_long, color: Colors.blue),
                      onPressed: () {
                        context.go('/admin/debt/${customer.id}');
                      },
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
