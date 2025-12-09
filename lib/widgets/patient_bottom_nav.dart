import 'package:flutter/material.dart';

class PatientBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final Color? backgroundColor;

  const PatientBottomNav({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      selectedItemColor: Colors.white,
      type: BottomNavigationBarType.fixed, // Ensures all labels are visible
      backgroundColor: backgroundColor, // Use the new property here
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          activeIcon: Icon(Icons.chat_bubble),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.fastfood_outlined),
          activeIcon: Icon(Icons.fastfood),
          label: 'Log',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.monitor_heart_outlined),
          activeIcon: Icon(Icons.monitor_heart),
          label: 'Lifestyle',
        ),
      ],
    );
  }
}
