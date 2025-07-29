import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const CustomBottomNavBar(
      {super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: const Color(0xFF2563EB),
      unselectedItemColor: Colors.black,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.apps), label: 'Trang chủ'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Khách hàng'),
        BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long), label: 'Sản phẩm'),
        BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2), label: 'Đơn hàng'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'KPI'),
      ],
      type: BottomNavigationBarType.fixed,
    );
  }
}
