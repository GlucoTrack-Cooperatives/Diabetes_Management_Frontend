import 'package:diabetes_management_system/auth/login/login_screen.dart';
import 'package:diabetes_management_system/physician/communication/physician_chat_list.dart';
import 'package:diabetes_management_system/physician/dashboard/physician_triage_dashboard_screen.dart';
import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/utils/responsive_layout.dart';
import 'package:diabetes_management_system/widgets/physician_bottom_nav.dart';
import 'package:diabetes_management_system/widgets/side_navigation_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diabetes_management_system/physician/dashboard/physician_dashboard_controller.dart';

import '../auth/login/login_controller.dart';

class PhysicianMainScreen extends ConsumerStatefulWidget {
  const PhysicianMainScreen({super.key});

  @override
  ConsumerState<PhysicianMainScreen> createState() => _PhysicianMainScreenState();
}

class _PhysicianMainScreenState extends ConsumerState<PhysicianMainScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  static final List<Widget> _widgetOptions = <Widget>[
    const PhysicianTriageDashboardScreen(),
    const PhysicianChatList(),
  ];

  static const List<String> _widgetTitles = <String>[
    'Patient List',
    'Patient Messages',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        ref.read(patientSearchQueryProvider.notifier).state = '';
      }
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: _isSearching
          ? IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _toggleSearch,
      )
          : null,
      title: _isSearching
          ? TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(color: Colors.black87, fontSize: 18),
        cursorColor: AppColors.primary,
        decoration: const InputDecoration(
          hintText: 'Search patient name...',
          hintStyle: TextStyle(color: Colors.black38),
          border: InputBorder.none,
        ),
        onChanged: (value) {
          ref.read(patientSearchQueryProvider.notifier).state = value;
        },
      )
          : Text(_widgetTitles.elementAt(_selectedIndex)),
      actions: [
        if (_selectedIndex == 0) ...[ // Only show search on Patient List tab
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _toggleSearch,
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _searchController.clear();
                ref.read(patientSearchQueryProvider.notifier).state = '';
              },
            ),
        ],
        // Hide logout while searching to avoid clutter, or keep it if preferred
        if (!_isSearching)
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: "Logout",
            onPressed: _handleLogout,
          ),
      ],
    );
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
      appBar: _buildAppBar(),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: PhysicianBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
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
              appBar: _buildAppBar(),
              body: _widgetOptions.elementAt(_selectedIndex),
            ),
          ),
        ],
      ),
    );
  }
}