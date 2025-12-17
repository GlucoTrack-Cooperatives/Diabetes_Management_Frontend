import 'package:diabetes_management_system/physician/communication/physician_chat_screen.dart';
import 'package:diabetes_management_system/physician/dashboard/physician_triage_dashboard_screen.dart';
import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/utils/responsive_layout.dart';
import 'package:diabetes_management_system/widgets/physician_bottom_nav.dart';
import 'package:diabetes_management_system/widgets/side_navigation_drawer.dart';
import 'package:flutter/material.dart';

class PhysicianMainScreen extends StatefulWidget {
  @override
  _PhysicianMainScreenState createState() => _PhysicianMainScreenState();
}

class _PhysicianMainScreenState extends State<PhysicianMainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    PhysicianTriageDashboardScreen(),
    PhysicianChatScreen(),
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
        actions: _selectedIndex == 0
            ? [
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.filter_list),
                  onPressed: () {},
                ),
              ]
            : null,
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
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
                actions: _selectedIndex == 0
                    ? [
                        IconButton(
                          icon: Icon(Icons.search),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: Icon(Icons.filter_list),
                          onPressed: () {},
                        ),
                      ]
                    : null,
              ),
              body: Center(
                child: _widgetOptions.elementAt(_selectedIndex),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
