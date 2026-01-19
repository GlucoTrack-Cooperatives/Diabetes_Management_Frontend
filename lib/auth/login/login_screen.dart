import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Imports for your specific project structure
import 'package:diabetes_management_system/auth/registration/patient_registration_screen.dart';
import 'package:diabetes_management_system/auth/registration/physician_registration_screen.dart';
import 'package:diabetes_management_system/patient/patient_main_screen.dart';
import 'package:diabetes_management_system/utils/responsive_layout.dart';
import 'package:diabetes_management_system/widgets/custom_elevated_button.dart';
import 'package:diabetes_management_system/widgets/custom_text_form_field.dart';
import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/theme/app_text_styles.dart';
import '../../physician/physician_main_screen.dart';
import '../../services/secure_storage_service.dart';
import 'login_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        mobileBody: _LoginMobileBody(),
        desktopBody: _LoginDesktopBody(),
      ),
    );
  }
}

class _LoginMobileBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _LoginForm(),
        ),
      ),
    );
  }
}

class _LoginDesktopBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            color: AppColors.primary,
            child: Center(
              child: Text(
                'Diabetes Management System',
                style: AppTextStyles.headline1.copyWith(color: Colors.black),
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _LoginForm(),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (_formKey.currentState!.validate()) {
      // Call the new controller
      ref.read(loginControllerProvider.notifier).login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Watch the state to update UI (Loading spinners, etc)
    final state = ref.watch(loginControllerProvider);
    final isLoading = state.isLoading;

    ref.listen<AsyncValue<void>>(loginControllerProvider, (previous, next) async {
      next.when(
        data: (_) async {
          if (previous?.isLoading == true) {
            // Login Successful. Now check the role to decide where to go.
            final role = await ref.read(storageServiceProvider).getRole();

            if (!context.mounted) return;

            Widget targetScreen;
            if (role == 'PATIENT') {
              targetScreen = const PatientMainScreen();
            } else if (role == 'PHYSICIAN') {
              targetScreen = const PhysicianMainScreen();
            } else {
              // Fallback or Admin
              targetScreen = const PatientMainScreen();
            }

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => targetScreen),
            );
          }
        },
        error: (error, stack) {
          // ... error handling ...
        },
        loading: () {},
      );
    });

    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Login', style: AppTextStyles.headline1),
          const SizedBox(height: 24),
          CustomTextFormField(
            controller: _emailController,
            labelText: 'Email',
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter your email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextFormField(
            controller: _passwordController,
            labelText: 'Password',
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter your password';
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Updated Button Logic
          CustomElevatedButton(
            onPressed: isLoading ? null : _onLoginPressed,
            child: isLoading
                ? const SizedBox(
              height: 30,
              width: 24,
              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.0),
            )
                : const Text('Login'),
          ),

          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PatientRegistrationScreen()),
              );
            },
            child: const Text('Register as a new patient'),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PhysicianRegistrationScreen()),
              );
            },
            child: const Text('Register as a new physician'),
          ),
        ],
      ),
    );
  }
}