import 'package:diabetes_management_system/auth/login/login_screen.dart';
import 'package:diabetes_management_system/patient/dashboard/patient_dashboard_screen.dart';
import 'package:diabetes_management_system/physician/dashboard/physician_triage_dashboard_screen.dart';
import 'package:flutter/material.dart';

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  bool _isLoggedIn = false;
  int _currentIndex = 0;

  final List<Widget> _views = [
    PatientDashboardScreen(),
    PhysicianTriageDashboardScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoggedIn
        ? Scaffold(
            body: _views[_currentIndex],
            bottomNavigationBar: BottomNavigationBar(
              onTap: _onTabTapped,
              currentIndex: _currentIndex,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Patient',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.medical_services),
                  label: 'Physician',
                ),
              ],
            ),
          )
        : LoginScreen();
  }
}
