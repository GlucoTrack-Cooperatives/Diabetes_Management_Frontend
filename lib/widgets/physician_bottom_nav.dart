import 'package:flutter/material.dart';

class PhysicianBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final Color? backgroundColor;

  const PhysicianBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      type: BottomNavigationBarType.fixed,
      backgroundColor: backgroundColor,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.people_alt_outlined),
          activeIcon: Icon(Icons.people_alt),
          label: 'Patients',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          activeIcon: Icon(Icons.chat_bubble),
          label: 'Messages',
        ),
      ],
    );
  }
}
