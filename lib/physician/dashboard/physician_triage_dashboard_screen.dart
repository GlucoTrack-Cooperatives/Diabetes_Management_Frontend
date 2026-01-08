import 'package:diabetes_management_system/physician/patient_analysis/patient_analysis_screen.dart';
import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/theme/app_text_styles.dart';
import 'package:diabetes_management_system/utils/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'physician_dashboard_controller.dart'; // Import the new controller

// 1. Change to ConsumerWidget
class PhysicianTriageDashboardScreen extends ConsumerWidget {
  const PhysicianTriageDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // 2. Listen for success/error to show SnackBars
    ref.listen(physicianDashboardControllerProvider, (previous, next) {
      next.when(
        data: (_) {
          if (previous?.isLoading == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invitation sent to patient!'), backgroundColor: Colors.green),
            );
          }
        },
        error: (err, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${err.toString()}'), backgroundColor: Colors.red),
          );
        },
        loading: () {},
      );
    });

    return Scaffold(
      // Wrapped in Scaffold to support FloatingActionButton
      body: ResponsiveLayout(
        mobileBody: _PatientList(isDesktop: false),
        desktopBody: _PatientList(isDesktop: true),
      ),
      // 3. Add the Add Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPatientDialog(context, ref),
        label: const Text("Add Patient"),
        icon: const Icon(Icons.person_add),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  // 4. The Search Dialog
  void _showAddPatientDialog(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Assign New Patient"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Enter the email address the patient used to register.",
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: "Patient Email",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            Consumer( // Use Consumer to watch loading state specifically for the button
              builder: (context, ref, child) {
                final state = ref.watch(physicianDashboardControllerProvider);

                return ElevatedButton(
                  onPressed: state.isLoading
                      ? null
                      : () {
                    if (formKey.currentState!.validate()) {
                      // Call the controller
                      ref.read(physicianDashboardControllerProvider.notifier)
                          .invitePatientByEmail(emailController.text.trim());
                      Navigator.pop(context); // Close dialog immediately
                    }
                  },
                  child: state.isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("Send Request"),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _PatientList extends ConsumerWidget { // Change to ConsumerWidget
  final bool isDesktop;

  const _PatientList({required this.isDesktop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the data provider
    final patientsAsync = ref.watch(physicianPatientsListProvider);

    return Padding(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      child: patientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading patients: $err')),
        data: (patients) {
          if (patients.isEmpty) {
            return const Center(child: Text("No patients assigned yet. Click 'Add Patient' to start."));
          }

          return ListView.builder(
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final patient = patients[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: patient.isPhysicianConfirmed ? AppColors.primary : Colors.grey,
                    child: Text(
                        patient.fullName.isNotEmpty ? patient.fullName[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white)
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                          '${patient.fullName} (${patient.age}yo)',
                          style: AppTextStyles.headline2
                      ),
                      if (!patient.isPhysicianConfirmed) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: const Text(
                            "Pending",
                            style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Phone: ${patient.phoneNumber}', style: AppTextStyles.bodyText2),
                        if (patient.latestGlucoseValue != null)
                          Text(
                            'Latest Glucose: ${patient.latestGlucoseValue} mg/dL (${patient.latestGlucoseTrend})',
                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                          ),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () {
                    // Only allow navigation if confirmed, or show warning
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PatientAnalysisScreen(
                            patientId: patient.id,
                            patientName: patient.fullName,
                          )),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}