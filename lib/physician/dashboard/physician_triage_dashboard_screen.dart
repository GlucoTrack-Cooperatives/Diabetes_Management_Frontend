import 'package:diabetes_management_system/physician/patient_analysis/patient_analysis_screen.dart';
import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/theme/app_text_styles.dart';
import 'package:diabetes_management_system/utils/responsive_layout.dart';
import 'package:flutter/material.dart';

class PhysicianTriageDashboardScreen extends StatelessWidget {
  const PhysicianTriageDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The Scaffold is handled by PhysicianMainScreen
    return ResponsiveLayout(
      mobileBody: _PatientList(isDesktop: false),
      desktopBody: _PatientList(isDesktop: true),
    );
  }
}

class _PatientList extends StatelessWidget {
  final bool isDesktop;

  const _PatientList({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    // Mock Data
    final List<Map<String, dynamic>> patients = [
      {
        'initials': 'JD',
        'name': 'John Doe',
        'age': '45yo',
        'risk': 'HIGH RISK',
        'riskColor': AppColors.error,
        'stats': '7d Avg: 165 mg/dL | TIR: 65%'
      },
      {
        'initials': 'AS',
        'name': 'Alice Smith',
        'age': '32yo',
        'risk': 'Review Needed',
        'riskColor': Colors.orange,
        'stats': '7d Avg: 142 mg/dL | TIR: 78%'
      },
      {
        'initials': 'RJ',
        'name': 'Robert Johnson',
        'age': '58yo',
        'risk': 'Stable',
        'riskColor': Colors.green,
        'stats': '7d Avg: 120 mg/dL | TIR: 92%'
      },
    ];

    return Padding(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      child: ListView.builder(
        itemCount: patients.length,
        itemBuilder: (context, index) {
          final patient = patients[index];
          return Card(
            margin: EdgeInsets.only(bottom: 16),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(patient['initials'], style: TextStyle(color: Colors.white)),
              ),
              title: Row(
                children: [
                  Text('${patient['name']} (${patient['age']})', style: AppTextStyles.headline2),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(patient['stats'], style: AppTextStyles.bodyText2),
              ),
              trailing: Chip(
                label: Text(
                  patient['risk'],
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                backgroundColor: patient['riskColor'],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PatientAnalysisScreen()),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
