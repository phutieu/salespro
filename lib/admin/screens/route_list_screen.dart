import 'package:flutter/material.dart';
import 'package:salespro/admin/mock_data.dart';
import 'package:salespro/admin/models/sales_route.dart';
import 'package:salespro/admin/widgets/route_form.dart';

class RouteListScreen extends StatefulWidget {
  const RouteListScreen({super.key});

  @override
  _RouteListScreenState createState() => _RouteListScreenState();
}

class _RouteListScreenState extends State<RouteListScreen> {
  late List<SalesRoute> _routes;

  @override
  void initState() {
    super.initState();
    _routes = List.from(mockRoutes);
  }

  void _showRouteForm({SalesRoute? route}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RouteForm(
          route: route,
          onSave: (savedRoute) {
            setState(() {
              if (route == null) {
                _routes.add(savedRoute);
              } else {
                final index = _routes.indexWhere((r) => r.id == savedRoute.id);
                if (index != -1) {
                  _routes[index] = savedRoute;
                }
              }
            });
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
            'Sales Routes',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              _showRouteForm();
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Route'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _routes.length,
              itemBuilder: (context, index) {
                final route = _routes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading:
                        const Icon(Icons.route, color: Colors.blue, size: 40),
                    title: Text(route.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
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
                        _showRouteForm(route: route);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
