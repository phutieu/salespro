import 'package:flutter/material.dart';
import 'package:flutter_admin_scaffold/admin_scaffold.dart';
import 'package:go_router/go_router.dart';

class AdminApp extends StatelessWidget {
  final Widget child;

  const AdminApp({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Admin Console'),
      ),
      sideBar: SideBar(
        items: const [
          AdminMenuItem(
            title: 'Dashboard',
            route: '/admin',
            icon: Icons.dashboard,
          ),
          AdminMenuItem(
            title: 'Products',
            route: '/admin/products',
            icon: Icons.shopping_cart,
          ),
          AdminMenuItem(
            title: 'Stock In',
            route: '/admin/stock-in',
            icon: Icons.inventory_2,
          ),
          AdminMenuItem(
            title: 'Customers',
            route: '/admin/customers',
            icon: Icons.people,
          ),
          AdminMenuItem(
            title: 'Orders',
            route: '/admin/orders',
            icon: Icons.receipt,
          ),
          AdminMenuItem(
            title: 'Users',
            route: '/admin/users',
            icon: Icons.group,
          ),
          AdminMenuItem(
            title: 'Routes',
            route: '/admin/routes',
            icon: Icons.route,
          ),
          AdminMenuItem(
            title: 'Debt',
            route: '/admin/debt',
            icon: Icons.attach_money,
          ),
          AdminMenuItem(
            title: 'Tracking',
            route: '/admin/tracking',
            icon: Icons.pin_drop,
          ),
        ],
        selectedRoute: GoRouterState.of(context).uri.toString(),
        onSelected: (item) {
          if (item.route != null) {
            context.go(item.route!);
          }
        },
      ),
      body: child,
    );
  }
}
