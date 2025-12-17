import 'package:flutter/material.dart';

class PatientSettingsScreen extends StatelessWidget {
  const PatientSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Settings'),
      ),
      body: Center(
        child: Text('Patient Settings Content Goes Here'),
      ),
    );
  }
}
