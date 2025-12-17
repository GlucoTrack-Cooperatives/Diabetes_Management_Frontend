import 'package:diabetes_management_system/physician/dashboard/physician_triage_dashboard_screen.dart';
import 'package:diabetes_management_system/physician/physician_main_screen.dart';
import 'package:flutter/material.dart';
import 'package:diabetes_management_system/theme/app_text_styles.dart';

class PhysicianRegistrationScreen extends StatelessWidget {
  const PhysicianRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Physician Registration'),
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

class _PhysicianRegistrationForm extends StatefulWidget {
  @override
  __PhysicianRegistrationFormState createState() => __PhysicianRegistrationFormState();
}

class __PhysicianRegistrationFormState extends State<_PhysicianRegistrationForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Create Physician Account', style: AppTextStyles.headline1),
          SizedBox(height: 24),
          TextFormField(decoration: InputDecoration(labelText: 'First Name', border: OutlineInputBorder())),
          SizedBox(height: 16),
          TextFormField(decoration: InputDecoration(labelText: 'Last Name', border: OutlineInputBorder())),
          SizedBox(height: 16),
          TextFormField(decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
          SizedBox(height: 16),
          TextFormField(obscureText: true, decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
          SizedBox(height: 16),
          TextFormField(decoration: InputDecoration(labelText: 'Specialty', border: OutlineInputBorder())),
          SizedBox(height: 16),
          TextFormField(decoration: InputDecoration(labelText: 'License Number', border: OutlineInputBorder())),
          SizedBox(height: 16),
          TextFormField(decoration: InputDecoration(labelText: 'Clinic Name', border: OutlineInputBorder())),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Handle physician registration logic
              }
            },
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PhysicianMainScreen()),
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
