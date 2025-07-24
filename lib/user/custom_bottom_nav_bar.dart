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
            icon: Icon(Icons.card_giftcard), label: 'Đơn hàng'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'KPI'),
        BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Thêm'),
      ],
      type: BottomNavigationBarType.fixed,
    );
  }
}
