import 'package:diabetes_management_system/auth/registration/patient_registration_screen.dart';
import 'package:diabetes_management_system/auth/registration/physician_registration_screen.dart';
import 'package:diabetes_management_system/utils/responsive_layout.dart';
import 'package:diabetes_management_system/widgets/custom_elevated_button.dart';
import 'package:diabetes_management_system/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/theme/app_text_styles.dart';

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

class _LoginForm extends StatefulWidget {
  @override
  __LoginFormState createState() => __LoginFormState();
}

class __LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Handle login logic
              }
            },
            text: 'Login',
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
