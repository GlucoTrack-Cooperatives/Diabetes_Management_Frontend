import 'package:diabetes_management_system/patient/communication/patient_chat_screen.dart';
import 'package:diabetes_management_system/patient/dashboard/patient_dashboard_screen.dart';
import 'package:diabetes_management_system/patient/lifestyle/lifestyle_tracker_screen.dart';
import 'package:diabetes_management_system/patient/logging/food_insulin_log_screen.dart';
import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/utils/responsive_layout.dart';
import 'package:diabetes_management_system/widgets/patient_bottom_nav.dart';
import 'package:flutter/material.dart';

class PatientMainScreen extends StatefulWidget {
  @override
  _PatientMainScreenState createState() => _PatientMainScreenState();
}

class _PatientMainScreenState extends State<PatientMainScreen> {
  int _selectedIndex = 0;

  // The list of screens to navigate between
  static final List<Widget> _widgetOptions = <Widget>[
    PatientDashboardScreen(),
    PatientChatScreen(),
    FoodInsulinLogScreen(),
    LifestyleTrackerScreen(),
  ];

  // The titles for the AppBar corresponding to each screen
  static const List<String> _widgetTitles = <String>[
    'Dashboard',
    'Chat',
    'Food & Insulin Log',
    'Lifestyle',
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

  // The mobile layout with a Scaffold and the custom BottomNavigationBar
  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_widgetTitles.elementAt(_selectedIndex)),
        // You can add specific actions for each screen here if needed
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: PatientBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        backgroundColor: AppColors.accent, // Set the accent color here
      ),
    );
  }

  // The desktop layout with a permanent NavigationDrawer
  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          NavigationDrawer(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            indicatorColor: Colors.white, // Use accent color for the selection indicator
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
                child: Text(
                  'Patient Menu',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const NavigationDrawerDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              const NavigationDrawerDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: Text('Chat'),
              ),
              const NavigationDrawerDestination(
                icon: Icon(Icons.fastfood_outlined),
                selectedIcon: Icon(Icons.fastfood),
                label: Text('Log'),
              ),
              const NavigationDrawerDestination(
                icon: Icon(Icons.monitor_heart_outlined),
                selectedIcon: Icon(Icons.monitor_heart),
                label: Text('Lifestyle'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Text(_widgetTitles.elementAt(_selectedIndex)),
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
