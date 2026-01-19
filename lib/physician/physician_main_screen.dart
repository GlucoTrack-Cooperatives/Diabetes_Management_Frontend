import 'package:diabetes_management_system/auth/login/login_screen.dart';
import 'package:diabetes_management_system/physician/communication/physician_chat_list.dart';
import 'package:diabetes_management_system/physician/dashboard/physician_triage_dashboard_screen.dart';
import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/utils/responsive_layout.dart';
import 'package:diabetes_management_system/widgets/physician_bottom_nav.dart';
import 'package:diabetes_management_system/widgets/side_navigation_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/login/login_controller.dart';

class PhysicianMainScreen extends ConsumerStatefulWidget {
  const PhysicianMainScreen({super.key});

  @override
  ConsumerState<PhysicianMainScreen> createState() => _PhysicianMainScreenState();
}

class _PhysicianMainScreenState extends ConsumerState<PhysicianMainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const PhysicianTriageDashboardScreen(),
    const PhysicianChatList(),
  ];

  static const List<String> _widgetTitles = <String>[
    'Patient List',
    'Patient Messages',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleLogout() async {
    await ref.read(loginControllerProvider.notifier).logout();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: _buildMobileLayout(),
      desktopBody: _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_widgetTitles.elementAt(_selectedIndex)),
        actions: [
          if (_selectedIndex == 0) ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {},
            ),
          ],
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: "Logout",
            onPressed: _handleLogout,
          ),
        ],
      ),
      // Removed Center() to allow the list/dashboard to use full width
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: PhysicianBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        backgroundColor: AppColors.accent,
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          SideNavigationDrawer(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            title: 'Physician Menu',
            indicatorColor: AppColors.accent,
            destinations: const [
              NavigationDrawerDestination(
                icon: Icon(Icons.people_alt_outlined),
                selectedIcon: Icon(Icons.people_alt),
                label: Text('Patients'),
              ),
              NavigationDrawerDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: Text('Messages'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Text(_widgetTitles.elementAt(_selectedIndex)),
                actions: [
                  if (_selectedIndex == 0) ...[
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: () {},
                    ),
                  ],
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    tooltip: "Logout",
                    onPressed: _handleLogout,
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              // Fixed the syntax error here: 'body' instead of 'child' outside the widget
              body: _widgetOptions.elementAt(_selectedIndex),
            ),
          ),
        ],
      ),
    );
  }
}