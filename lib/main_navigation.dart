import 'package:diabetes_management_system/auth/login/login_screen.dart'; // Make sure this import points to your file
import 'package:diabetes_management_system/patient/patient_main_screen.dart';
import 'package:diabetes_management_system/physician/physician_main_screen.dart';
import 'package:diabetes_management_system/services/secure_storage_service.dart';
import 'package:diabetes_management_system/services/fcm_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  @override
  void initState() {
    super.initState();

    _initializeFcm();
  }

  Future<void> _initializeFcm() async {
    final fcmService = ref.read(fcmServiceProvider);
    await fcmService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authCheckProvider);

    return authState.when(
      data: (role) {
        if (role == 'PATIENT') {
          return const PatientMainScreen();
        } else if (role == 'PHYSICIAN') {
          return const PhysicianMainScreen();
        } else {
          return const LoginScreen();
        }
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const LoginScreen(),
    );
  }
}

final authCheckProvider = FutureProvider<String?>((ref) async {
  final storage = ref.read(storageServiceProvider);
  final token = await storage.getToken();
  final role = await storage.getRole();

  if (token != null && role != null) {
    return role;
  }
  return null;
});