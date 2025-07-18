import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:salespro/admin/models/sales_route.dart';
import 'package:salespro/admin/widgets/route_form.dart';

class RouteListScreen extends StatefulWidget {
  const RouteListScreen({super.key});

  @override
  _RouteListScreenState createState() => _RouteListScreenState();
}

class _RouteListScreenState extends State<RouteListScreen> {
  void _showRouteForm({DocumentSnapshot? doc}) {
    SalesRoute? route;
    if (doc != null) {
      final data = doc.data() as Map<String, dynamic>;
      route = SalesRoute.fromMap(data..['id'] = doc.id);
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RouteForm(
          route: route,
          onSave: (savedRoute) async {
            if (doc == null) {
              await FirebaseFirestore.instance
                  .collection('routes')
                  .add(savedRoute.toMap());
            } else {
              await FirebaseFirestore.instance
                  .collection('routes')
                  .doc(doc.id)
                  .update(savedRoute.toMap());
            }
            setState(() {});
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Routes',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              _showRouteForm();
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Route'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('routes').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final route = SalesRoute.fromMap(data..['id'] = doc.id);
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.route,
                            color: Colors.blue, size: 40),
                        title: Text(route.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Salesperson: ${route.salesperson.name}'),
                            Text('Customers: ${route.customers.length} stores'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.grey),
                          onPressed: () {
                            _showRouteForm(doc: doc);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
