import 'package:diabetes_management_system/auth/login/auth_provider.dart';
import 'package:diabetes_management_system/auth/registration/patient_registration_screen.dart';
import 'package:diabetes_management_system/auth/registration/physician_registration_screen.dart';
import 'package:diabetes_management_system/utils/responsive_layout.dart';
import 'package:diabetes_management_system/widgets/custom_elevated_button.dart';
import 'package:diabetes_management_system/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/theme/app_text_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class LoginScreen extends StatelessWidget {
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
                style: AppTextStyles.headline1.copyWith(color: Colors.white),
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: _LoginForm(),
            ),
          ),
        ),
      ],
    );
  }
}


class _LoginForm extends ConsumerWidget {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) { // Add WidgetRef
    // Watch the state of the authProvider
    final authState = ref.watch(authProvider);
    // Listen for changes to show alerts or navigate
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.success) {
        // TODO: Navigate to the main dashboard
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Login Successful!')));
      } else if (next.status == AuthStatus.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Login Failed: ${next.errorMessage}')));
      }
    });

    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Login', style: AppTextStyles.headline1),
          SizedBox(height: 24),
          CustomTextFormField(
            controller: _emailController,
            labelText: 'Email',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          CustomTextFormField(
            controller: _passwordController,
            labelText: 'Password',
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
          SizedBox(height: 24),
          CustomElevatedButton(
            onPressed: authState.status == AuthStatus.loading
                ? null // Disable button while loading
                : () {
              if (_formKey.currentState!.validate()) {
                // Call the login method
                // from the provider
                ref.read(authProvider.notifier).login(

                  _emailController.text,
                  _passwordController.text,
                );
              }
            },
            // Show a loading indicator or text
            child: authState.status == AuthStatus.loading
                ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0),
            )
                : Text('Login'),
          ),
          SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PatientRegistrationScreen()),
              );
            },
            child: Text('Register as a new patient'),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PhysicianRegistrationScreen()),
              );
            },
            child: Text('Register as a new physician'),
          ),
        ],
      ),
    );
  }
}
