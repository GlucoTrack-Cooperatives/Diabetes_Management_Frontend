import 'package:flutter/material.dart';

class SideNavigationDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final String title;
  final Color? indicatorColor;
  final List<NavigationDrawerDestination> destinations;

  const SideNavigationDrawer({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.title,
    required this.destinations,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      indicatorColor: indicatorColor,
      backgroundColor: Colors.white, // Explicitly set background color
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        ...destinations,
      ],
    );
  }
}
