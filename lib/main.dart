import 'package:diabetes_management_system/main_navigation.dart';
import 'package:diabetes_management_system/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(
    child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Diabetes Management',
      theme: AppTheme.lightTheme, // Use your custom theme
      home: MainNavigation(), // Set the home to your navigation wrapper
    );
  }
}
