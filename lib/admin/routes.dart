import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:salespro/admin/screens/dashboard_screen.dart';
import 'package:salespro/admin/screens/product_list_screen.dart';
import 'package:salespro/admin/screens/purchase_order_list_screen.dart';
import 'package:salespro/admin/screens/customer_list_screen.dart';
import 'package:salespro/admin/screens/order_list_screen.dart';
import 'package:salespro/admin/screens/order_details_screen.dart';
import 'package:salespro/admin/screens/user_list_screen.dart';
import 'package:salespro/admin/screens/route_list_screen.dart';
import 'package:salespro/admin/screens/debt_list_screen.dart';
import 'package:salespro/admin/screens/customer_debt_details_screen.dart';
import 'package:salespro/admin/screens/employee_tracking_screen.dart';
import 'package:salespro/admin/admin_app.dart';

final GoRouter adminRouter = GoRouter(
  initialLocation: '/admin',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return AdminApp(child: child);
      },
      routes: [
        GoRoute(
          path: '/admin',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/admin/products',
          builder: (context, state) => const ProductListScreen(),
        ),
        GoRoute(
          path: '/admin/stock-in',
          builder: (context, state) => const PurchaseOrderListScreen(),
        ),
        GoRoute(
          path: '/admin/customers',
          builder: (context, state) => const CustomerListScreen(),
        ),
        GoRoute(
          path: '/admin/orders',
          builder: (context, state) => const OrderListScreen(),
        ),
        GoRoute(
          path: '/admin/orders/:orderId',
          builder: (context, state) {
            final orderId = state.pathParameters['orderId']!;
            return OrderDetailsScreen(orderId: orderId);
          },
        ),
        GoRoute(
          path: '/admin/users',
          builder: (context, state) => const UserListScreen(),
        ),
        GoRoute(
          path: '/admin/routes',
          builder: (context, state) => const RouteListScreen(),
        ),
        GoRoute(
          path: '/admin/debt',
          builder: (context, state) => const DebtListScreen(),
        ),
        GoRoute(
          path: '/admin/debt/:customerId',
          builder: (context, state) {
            final customerId = state.pathParameters['customerId']!;
            return CustomerDebtDetailsScreen(customerId: customerId);
          },
        ),
        GoRoute(
          path: '/admin/tracking',
          builder: (context, state) => const EmployeeTrackingScreen(),
        ),
        // Add other admin routes here
      ],
    ),
  ],
);
