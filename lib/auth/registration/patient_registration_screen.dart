import 'package:diabetes_management_system/patient/patient_main_screen.dart';
import 'package:flutter/material.dart';
import 'package:diabetes_management_system/theme/app_text_styles.dart';

class PatientRegistrationScreen extends StatelessWidget {
  const PatientRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Registration'),
      ),
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

class _PatientRegistrationForm extends StatefulWidget {
  @override
  __PatientRegistrationFormState createState() => __PatientRegistrationFormState();
}

class __PatientRegistrationFormState extends State<_PatientRegistrationForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Create Patient Account', style: AppTextStyles.headline1),
          SizedBox(height: 24),
          TextFormField(decoration: InputDecoration(labelText: 'First Name', border: OutlineInputBorder())),
          SizedBox(height: 16),
          TextFormField(decoration: InputDecoration(labelText: 'Last Name', border: OutlineInputBorder())),
          SizedBox(height: 16),
          TextFormField(decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
          SizedBox(height: 16),
          TextFormField(obscureText: true, decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
          SizedBox(height: 16),
          // Note: A date picker would be a better UX for date fields.
          TextFormField(decoration: InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)', border: OutlineInputBorder())),
          SizedBox(height: 16),
          TextFormField(decoration: InputDecoration(labelText: 'Diagnosis Date (YYYY-MM-DD)', border: OutlineInputBorder())),
          SizedBox(height: 16),
          TextFormField(decoration: InputDecoration(labelText: 'Emergency Contact Phone', border: OutlineInputBorder())),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Handle patient registration logic
              }
            },
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PatientMainScreen()),
                );
              },
              child: Text('Register'),
            ),
          ),
        ],
      ),
    );
  }
}
