import 'package:diabetes_management_system/auth/login/login_screen.dart';
import 'package:diabetes_management_system/patient/communication/patient_chat_screen.dart';
import 'package:diabetes_management_system/patient/dashboard/patient_dashboard_screen.dart';
import 'package:diabetes_management_system/patient/lifestyle/lifestyle_tracker_screen.dart';
import 'package:diabetes_management_system/patient/logging/food_insulin_log_screen.dart';
import 'package:diabetes_management_system/patient/settings/patient_settings_screen.dart';
import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/utils/responsive_layout.dart';
import 'package:diabetes_management_system/widgets/patient_bottom_nav.dart';
import 'package:diabetes_management_system/widgets/side_navigation_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/login/login_controller.dart';

// 1. Convert to ConsumerStatefulWidget to use Riverpod 'ref'
class PatientMainScreen extends ConsumerStatefulWidget {
  const PatientMainScreen({super.key});

  @override
  ConsumerState<PatientMainScreen> createState() => _PatientMainScreenState();
}

class _PatientMainScreenState extends ConsumerState<PatientMainScreen> {
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

  // LOGOUT FUNCTION
  Future<void> _handleLogout() async {
    // 1. Trigger the logout logic in the controller (clears token)
    await ref.read(loginControllerProvider.notifier).logout();

    // 2. Check if widget is still mounted before navigating
    if (mounted) {
      // 3. Navigate back to Login Screen and remove all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  void _navigateToSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PatientSettingsScreen()),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      IconButton(
        icon: const Icon(Icons.settings, color: Colors.grey),
        tooltip: "Settings",
        onPressed: _navigateToSettings, // Connects to the new screen
      ),
      IconButton(
        icon: const Icon(Icons.logout, color: Colors.redAccent),
        tooltip: "Logout",
        onPressed: _handleLogout,
      ),
      const SizedBox(width: 8),
    ];
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
        actions: _buildAppBarActions(),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: PatientBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        backgroundColor: AppColors.accent,
      ),
    );
  }

  // The desktop layout with a permanent NavigationDrawer
  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          SideNavigationDrawer(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            title: 'Patient Menu',
            indicatorColor: AppColors.accent,
            destinations: const [
              NavigationDrawerDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationDrawerDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble),
                label: Text('Chat'),
              ),
              NavigationDrawerDestination(
                icon: Icon(Icons.fastfood_outlined),
                selectedIcon: Icon(Icons.fastfood),
                label: Text('Log'),
              ),
              NavigationDrawerDestination(
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
                actions: [
                  ..._buildAppBarActions(), // Use updated actions
                  const SizedBox(width: 16),
                ],
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
