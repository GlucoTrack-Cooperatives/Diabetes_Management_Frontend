import 'package:diabetes_management_system/auth/login/login_controller.dart';
import 'package:diabetes_management_system/models/physician_registration_request.dart';
import 'package:diabetes_management_system/physician/physician_main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diabetes_management_system/theme/app_text_styles.dart';
import 'registration_controller.dart';

class PhysicianRegistrationScreen extends ConsumerWidget {
  const PhysicianRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Physician Registration'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _PhysicianRegistrationForm(),
          ),
        ),
      ),
    );
  }
}

class _PhysicianRegistrationForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PhysicianRegistrationForm> createState() => _PhysicianRegistrationFormState();
}

class _PhysicianRegistrationFormState extends ConsumerState<_PhysicianRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _clinicNameController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _specialtyController.dispose();
    _licenseNumberController.dispose();_clinicNameController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      final request = PhysicianRegistrationRequest(
        firstName: _firstNameController.text.trim(),
        surname: _surnameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        specialty: _specialtyController.text.trim(),
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
              const SnackBar(content: Text('Registration Successful! Logging in...')),
            );
            ref.read(loginControllerProvider.notifier).login(
                _emailController.text.trim(), _passwordController.text.trim());
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
                (Route<dynamic> route) => false);
          }
        },
        error: (error, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "Registration successful, but login failed: ${error.toString()}"),
                backgroundColor: Colors.orange),
          );
          Navigator.of(context).pop();
        },
        loading: () {},
      );
    });

    final state = ref.watch(registrationControllerProvider);
    final isLoading = state.isLoading;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Create Physician Account', style: AppTextStyles.headline1),
          const SizedBox(height: 24),
          _buildTextField('First Name', _firstNameController),
          const SizedBox(height: 16),
          _buildTextField('Surname', _surnameController),
          const SizedBox(height: 16),
          _buildTextField('Email', _emailController, type: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _buildTextField('Password', _passwordController, isObscure: true),
          const SizedBox(height: 16),
          _buildTextField('Specialty', _specialtyController),
          const SizedBox(height: 16),
          _buildTextField('License Number', _licenseNumberController),
          const SizedBox(height: 16),
          _buildTextField('Clinic Name', _clinicNameController),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : _onSubmit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Register'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType? type, bool isObscure = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      obscureText: isObscure,
      keyboardType: type,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }
  
}
