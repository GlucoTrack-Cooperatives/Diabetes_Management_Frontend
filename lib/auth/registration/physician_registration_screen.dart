import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- YOUR IMPORTS ---
import 'package:diabetes_management_system/auth/login/login_controller.dart';
import 'package:diabetes_management_system/models/physician_registration_request.dart';
import 'package:diabetes_management_system/physician/physician_main_screen.dart';
import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/theme/app_text_styles.dart';
import 'package:diabetes_management_system/utils/responsive_layout.dart';
import 'package:diabetes_management_system/widgets/custom_elevated_button.dart';
import 'package:diabetes_management_system/widgets/custom_text_form_field.dart';
import 'registration_controller.dart';

class PhysicianRegistrationScreen extends StatelessWidget {
  const PhysicianRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Physician Registration"),
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
          child: _PhysicianRegistrationForm(),
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
        // Left Side: Branding
        Expanded(
          child: Container(
            color: AppColors.primary,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.medical_services_outlined, size: 80, color: Colors.white),
                  const SizedBox(height: 20),
                  Text(
                    'Partner With Us',
                    style: AppTextStyles.headline1.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Create your physician account',
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
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40.0),
                child: _PhysicianRegistrationForm(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PhysicianRegistrationForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PhysicianRegistrationForm> createState() => _PhysicianRegistrationFormState();
}

class _PhysicianRegistrationFormState extends ConsumerState<_PhysicianRegistrationForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _firstNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // We don't need a controller for the dropdown text, just a variable to store the value
  final _licenseNumberController = TextEditingController();
  final _clinicNameController = TextEditingController();

  // Dropdown State
  String? _selectedSpecialty;
  final List<String> _specialties = [
    'Endocrinology',
    'Internal Medicine',
    'General Practice / Family Medicine',
    'Diabetology',
    'Cardiology',
    'Nephrology',
    'Pediatrics',
    'Other',
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _licenseNumberController.dispose();
    _clinicNameController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      final request = PhysicianRegistrationRequest(
        firstName: _firstNameController.text.trim(),
        surname: _surnameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        specialty: _selectedSpecialty!, // Use the selected variable
        licenseNumber: _licenseNumberController.text.trim(),
        clinicName: _clinicNameController.text.trim(),
      );

      ref.read(registrationControllerProvider.notifier).registerPhysician(request);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(registrationControllerProvider, (previous, next) {
      next.when(
        data: (_) {
          if (previous?.isLoading == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registration Successful! Logging in...'), backgroundColor: Colors.green),
            );
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

    ref.listen<AsyncValue<void>>(loginControllerProvider, (previous, next) {
      next.when(
        data: (_) {
          if (previous?.isLoading == true) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const PhysicianMainScreen()),
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
          Text('Enter your professional details', style: AppTextStyles.bodyText2),
          const SizedBox(height: 32),

          // Name Row
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

          // --- REPLACED TEXT FIELD WITH DROPDOWN ---
          CustomDropdownFormField(
            labelText: 'Specialty',
            value: _selectedSpecialty,
            items: _specialties,
            onChanged: (value) {
              setState(() {
                _selectedSpecialty = value;
              });
            },
            validator: (v) => v == null ? 'Please select a specialty' : null,
          ),
          // -----------------------------------------

          const SizedBox(height: 16),

          CustomTextFormField(
            controller: _licenseNumberController,
            labelText: 'Medical License Number',
            validator: (v) => v?.isEmpty == true ? 'Required' : null,
          ),
          const SizedBox(height: 16),

          CustomTextFormField(
            controller: _clinicNameController,
            labelText: 'Clinic / Hospital Name',
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

// --- HELPER WIDGET FOR CONSISTENT DROPDOWN STYLING ---
class CustomDropdownFormField extends StatelessWidget {
  final String labelText;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  const CustomDropdownFormField({
    super.key,
    required this.labelText,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    // Matches CustomTextFormField color
    final Color inputFillColor = const Color(0xFFEFF1F3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0, bottom: 8.0),
          child: Text(
            labelText,
            style: AppTextStyles.bodyText1.copyWith(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: inputFillColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: AppTextStyles.bodyText1),
              );
            }).toList(),
            onChanged: onChanged,
            validator: validator,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              filled: true,
              fillColor: inputFillColor,
            ),
            dropdownColor: Colors.white,
            icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}