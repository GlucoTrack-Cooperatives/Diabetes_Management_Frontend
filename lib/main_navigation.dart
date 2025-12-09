import 'package:diabetes_management_system/auth/login/login_screen.dart';
import 'package:diabetes_management_system/patient/patient_main_screen.dart';
import 'package:flutter/material.dart';

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // In a real app, this would be driven by an auth service.
  // For now, we'll set it to true to see the patient view directly.
  bool _isLoggedIn = true; 

  @override
  Widget build(BuildContext context) {
    // If logged in, show the main patient screen, otherwise show the login screen.
    return _isLoggedIn
        ? PatientMainScreen() 
        : LoginScreen();
  }
}
