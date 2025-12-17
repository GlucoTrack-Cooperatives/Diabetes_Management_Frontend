import 'package:diabetes_management_system/auth/login/login_screen.dart'; // Make sure this import points to your file
import 'package:flutter/material.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {

  @override
  Widget build(BuildContext context) {
    // We removed the Scaffold and FloatingActionButton here because
    // LoginScreen() already has its own Scaffold and ResponsiveLayout.
    return LoginScreen();
  }
}