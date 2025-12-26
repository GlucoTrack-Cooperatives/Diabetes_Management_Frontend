// import 'package:diabetes_management_system/patient/patient_main_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:diabetes_management_system/theme/app_text_styles.dart';
//
// class PatientRegistrationScreen extends StatelessWidget {
//   const PatientRegistrationScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Patient Registration'),
//       ),
//       body: Center(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: _PatientRegistrationForm(),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _PatientRegistrationForm extends StatefulWidget {
//   @override
//   __PatientRegistrationFormState createState() => __PatientRegistrationFormState();
// }
//
// class __PatientRegistrationFormState extends State<_PatientRegistrationForm> {
//   final _formKey = GlobalKey<FormState>();
//
//   @override
//   Widget build(BuildContext context) {
//     return Form(
//       key: _formKey,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Text('Create Patient Account', style: AppTextStyles.headline1),
//           SizedBox(height: 24),
//           TextFormField(decoration: InputDecoration(labelText: 'First Name', border: OutlineInputBorder())),
//           SizedBox(height: 16),
//           TextFormField(decoration: InputDecoration(labelText: 'Last Name', border: OutlineInputBorder())),
//           SizedBox(height: 16),
//           TextFormField(decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
//           SizedBox(height: 16),
//           TextFormField(obscureText: true, decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
//           SizedBox(height: 16),
//           // Note: A date picker would be a better UX for date fields.
//           TextFormField(decoration: InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)', border: OutlineInputBorder())),
//           SizedBox(height: 16),
//           TextFormField(decoration: InputDecoration(labelText: 'Diagnosis Date (YYYY-MM-DD)', border: OutlineInputBorder())),
//           SizedBox(height: 16),
//           TextFormField(decoration: InputDecoration(labelText: 'Emergency Contact Phone', border: OutlineInputBorder())),
//           SizedBox(height: 24),
//           ElevatedButton(
//             onPressed: () {
//               if (_formKey.currentState!.validate()) {
//                 // Handle patient registration logic
//               }
//             },
//             child: TextButton(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => PatientMainScreen()),
//                 );
//               },
//               child: Text('Register'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


// ## Refactor the UI (view) with riverpod


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/patient_registration_request.dart';
import 'registration_controller.dart';
import '../../../theme/app_text_styles.dart';

// Convert to ConsumerWidget to access Riverpod providers
class PatientRegistrationScreen extends ConsumerWidget {
  const PatientRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to the controller state for global feedback (Success/Error)
    ref.listen<AsyncValue<void>>(registrationControllerProvider, (previous, next) {
      next.when(
        data: (_) {
          if (previous?.isLoading == true) { // Only show success if we just finished loading
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registration Successful! Please Login.')),
            );
            Navigator.pop(context); // Go back to login screen
          }
        },
        error: (error, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString()), backgroundColor: Colors.red),
          );
        },
        loading: () {}, // Do nothing, the UI handles the spinner locally
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Patient Registration')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _PatientRegistrationForm(),
          ),
        ),
      ),
    );
  }
}

class _PatientRegistrationForm extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PatientRegistrationForm> createState() => _PatientRegistrationFormState();
}

class _PatientRegistrationFormState extends ConsumerState<_PatientRegistrationForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers to capture text input
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dobController = TextEditingController();
  final _diagnosisDateController = TextEditingController();
  final _emergencyController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    _diagnosisDateController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      // Create the DTO
      final request = PatientRegistrationRequest(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        dob: _dobController.text.trim(),
        diagnosisDate: _diagnosisDateController.text.trim(),
        emergencyContact: _emergencyController.text.trim(),
      );

      // Call the controller
      ref.read(registrationControllerProvider.notifier).register(request);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the state to disable button while loading
    final state = ref.watch(registrationControllerProvider);
    final isLoading = state.isLoading;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Create Patient Account', style: AppTextStyles.headline1),
          const SizedBox(height: 24),

          _buildTextField('First Name', _firstNameController),
          const SizedBox(height: 16),

          _buildTextField('Last Name', _lastNameController),
          const SizedBox(height: 16),

          _buildTextField('Email', _emailController, type: TextInputType.emailAddress),
          const SizedBox(height: 16),

          _buildTextField('Password', _passwordController, type: TextInputType.text, isObscure: true),
          const SizedBox(height: 16),

          _buildTextField('Date of Birth (YYYY-MM-DD)', _dobController, type: TextInputType.datetime),
          const SizedBox(height: 16),

          _buildTextField('Diagnosis Date (YYYY-MM-DD)', _diagnosisDateController, type: TextInputType.datetime),
          const SizedBox(height: 16),

          _buildTextField('Emergency Contact Phone', _emergencyController, type: TextInputType.phone),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: isLoading ? null : _onSubmit, // Disable if loading
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: isLoading
                ? const SizedBox(
                height: 20, width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
            )
                : const Text('Register'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller,
      {TextInputType? type, bool isObscure = false}
      ) {
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
