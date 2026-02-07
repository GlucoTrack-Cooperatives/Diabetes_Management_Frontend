import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- YOUR IMPORTS ---
// Make sure these paths match your project structure
import 'package:diabetes_management_system/auth/login/login_controller.dart';
import 'package:diabetes_management_system/patient/patient_main_screen.dart';
import 'package:diabetes_management_system/models/patient_registration_request.dart';
import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/theme/app_text_styles.dart';
import 'package:diabetes_management_system/utils/responsive_layout.dart';
import 'package:diabetes_management_system/widgets/custom_elevated_button.dart';
import 'package:diabetes_management_system/widgets/custom_text_form_field.dart';
import 'registration_controller.dart';

class PatientRegistrationScreen extends StatelessWidget {
  const PatientRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient Registration"),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ResponsiveLayout(
        mobileBody: const _RegistrationMobileBody(),
        desktopBody: const _RegistrationDesktopBody(),
      ),
    );
  }
}

class _RegistrationMobileBody extends StatelessWidget {
  const _RegistrationMobileBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _PatientRegistrationForm(),
        ),
      ),
    );
  }
}

class _RegistrationDesktopBody extends StatelessWidget {
  const _RegistrationDesktopBody();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left Side: Branding (Same style as Login)
        Expanded(
          child: Container(
            color: AppColors.primary,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add_alt_1, size: 80, color: Colors.white),
                  const SizedBox(height: 20),
                  Text(
                    'Join Us Today',
                    style: AppTextStyles.headline1.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Create your patient account',
                    style: AppTextStyles.bodyText1.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Right Side: Form
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500), // Slightly wider for registration form
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40.0),
                child: _PatientRegistrationForm(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PatientRegistrationForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PatientRegistrationForm> createState() => _PatientRegistrationFormState();
}

class _PatientRegistrationFormState extends ConsumerState<_PatientRegistrationForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _firstNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _diagnosisDateController = TextEditingController();
  final _emergencyController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _diagnosisDateController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      final request = PatientRegistrationRequest(
        firstName: _firstNameController.text.trim(),
        surname: _surnameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        dob: _dobController.text.trim(),
        diagnosisDate: _diagnosisDateController.text.trim(),
        emergencyContactPhone: _emergencyController.text.trim(),
      );

      ref.read(registrationControllerProvider.notifier).registerPatient(request);
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary, // Ensure calendar matches theme
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      // Format: YYYY-MM-DD
      controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Listen for Registration Success -> Trigger Auto-Login
    ref.listen<AsyncValue<void>>(registrationControllerProvider, (previous, next) {
      next.when(
        data: (_) {
          if (previous?.isLoading == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registration Successful! Logging in...'), backgroundColor: Colors.green),
            );
            // Auto-login logic
            ref.read(loginControllerProvider.notifier).login(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            );
          }
        },
        error: (error, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString()), backgroundColor: Colors.red),
          );
        },
        loading: () {},
      );
    });

    // 2. Listen for Login Success -> Navigate to Dashboard
    ref.listen<AsyncValue<void>>(loginControllerProvider, (previous, next) {
      next.when(
        data: (_) {
          if (previous?.isLoading == true) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const PatientMainScreen()),
                  (route) => false,
            );
          }
        },
        error: (error, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Registration successful, but login failed: ${error.toString()}"),
              backgroundColor: Colors.orange,
            ),
          );
          // If auto-login fails, go back to login screen
          Navigator.of(context).pop();
        },
        loading: () {},
      );
    });

    final regState = ref.watch(registrationControllerProvider);
    final loginState = ref.watch(loginControllerProvider);
    final bool isLoading = regState.isLoading || loginState.isLoading;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Create Account', style: AppTextStyles.headline1),
          const SizedBox(height: 8),
          Text('Please fill in your details below', style: AppTextStyles.bodyText2),
          const SizedBox(height: 32),

          // Name Row (Side by side)
          Row(
            children: [
              Expanded(
                child: CustomTextFormField(
                  controller: _firstNameController,
                  labelText: 'First Name',
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextFormField(
                  controller: _surnameController,
                  labelText: 'Surname',
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          CustomTextFormField(
            controller: _emailController,
            labelText: 'Email',
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v?.isEmpty == true || !v!.contains('@')) ? 'Valid email required' : null,
          ),
          const SizedBox(height: 16),

          CustomTextFormField(
            controller: _passwordController,
            labelText: 'Password',
            obscureText: true,
            validator: (v) => (v != null && v.length < 6) ? 'Min 6 chars required' : null,
          ),
          const SizedBox(height: 16),

          CustomTextFormField(
            controller: _phoneController,
            labelText: 'Phone Number',
            keyboardType: TextInputType.phone,
            validator: (v) => v?.isEmpty == true ? 'Required' : null,
          ),
          const SizedBox(height: 16),

          // Date Row (Side by side)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(context, _dobController),
                  child: AbsorbPointer(
                    child: CustomTextFormField(
                      controller: _dobController,
                      labelText: 'Date of Birth',
                      suffixIcon: const Icon(Icons.calendar_today, size: 18),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(context, _diagnosisDateController),
                  child: AbsorbPointer(
                    child: CustomTextFormField(
                      controller: _diagnosisDateController,
                      labelText: 'Diagnosis Date',
                      suffixIcon: const Icon(Icons.history, size: 18),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          CustomTextFormField(
            controller: _emergencyController,
            labelText: 'Emergency Contact Phone',
            keyboardType: TextInputType.phone,
            validator: (v) => v?.isEmpty == true ? 'Required' : null,
          ),
          const SizedBox(height: 32),

          CustomElevatedButton(
            onPressed: isLoading ? null : _onSubmit,
            child: isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
                : const Text('Register'),
          ),

          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Already have an account? Login'),
            ),
          ),
        ],
      ),
    );
  }
}