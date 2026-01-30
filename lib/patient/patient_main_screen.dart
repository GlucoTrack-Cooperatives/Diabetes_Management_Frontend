import 'package:diabetes_management_system/auth/login/login_screen.dart';
import 'package:diabetes_management_system/controllers/chat_controller.dart';
import 'package:diabetes_management_system/patient/communication/patient_chat_screen.dart';
import 'package:diabetes_management_system/patient/dashboard/patient_dashboard_screen.dart';
import 'package:diabetes_management_system/patient/lifestyle/lifestyle_controller.dart';
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

class PatientMainScreen extends ConsumerStatefulWidget {
  const PatientMainScreen({super.key});

  @override
  ConsumerState<PatientMainScreen> createState() => _PatientMainScreenState();
}

class _PatientMainScreenState extends ConsumerState<PatientMainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const PatientDashboardScreen(),
    const PatientChatScreen(),
    FoodInsulinLogScreen(),
    const LifestyleTrackerScreen(),
  ];

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

  Future<void> _handleLogout() async {
    await ref.read(loginControllerProvider.notifier).logout();
    if (mounted) {
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
      if (_selectedIndex == 3)
        IconButton(
          icon: const Icon(Icons.sync),
          tooltip: 'Sync Health Data',
          onPressed: () {
            ref.read(lifestyleControllerProvider.notifier).syncHealthData();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Syncing health data...'),
                  duration: Duration(seconds: 1)
              ),
            );
          },
        ),
      IconButton(
        icon: const Icon(Icons.settings, color: Colors.grey),
        tooltip: "Settings",
        onPressed: _navigateToSettings,
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
    final chatThreads = ref.watch(chatThreadsProvider);
    String appBarTitle = _widgetTitles[_selectedIndex];

    if (_selectedIndex == 1) {
      chatThreads.whenData((threads) {
        if (threads.isNotEmpty) {
          appBarTitle = "Dr. ${threads.first.physicianName}";
        }
      });
    }

    return ResponsiveLayout(
      mobileBody: _buildMobileLayout(appBarTitle),
      desktopBody: _buildDesktopLayout(appBarTitle),
    );
  }

  Widget _buildMobileLayout(String title) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: _buildAppBarActions(),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: PatientBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildDesktopLayout(String title) {
    return Scaffold(
      body: Row(
        children: [
          SideNavigationDrawer(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            title: 'Patient Menu',
            indicatorColor: AppColors.peach,
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
                  title: Text(title),
                  actions: [
                    ..._buildAppBarActions(),
                    const SizedBox(width: 16),
                  ],
                ),
                body: _widgetOptions.elementAt(_selectedIndex),
              ),
            ),
        ],
      ),
    );
  }
}
