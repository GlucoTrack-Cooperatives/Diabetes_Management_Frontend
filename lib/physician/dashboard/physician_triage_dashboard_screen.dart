import 'package:diabetes_management_system/physician/patient_analysis/patient_analysis_screen.dart';
import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/theme/app_text_styles.dart';
import 'package:diabetes_management_system/utils/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'physician_dashboard_controller.dart';

class PhysicianTriageDashboardScreen extends ConsumerWidget {
  const PhysicianTriageDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for success/error to show SnackBars
    ref.listen(physicianDashboardControllerProvider, (previous, next) {
      next.when(
        data: (_) {
          if (previous?.isLoading == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invitation sent to patient!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        error: (err, stack) {
          final errorMessage = err.toString().replaceFirst('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        },
        loading: () {},
      );
    });

    return Scaffold(
      body: ResponsiveLayout(
        mobileBody: const _PatientList(isDesktop: false),
        desktopBody: const _PatientList(isDesktop: true),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPatientDialog(context, ref),
        label: const Text("Add Patient"),
        icon: const Icon(Icons.person_add),
        backgroundColor: AppColors.primary,
      ),
    );
  }

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
            Consumer(
              builder: (context, ref, child) {
                final state = ref.watch(physicianDashboardControllerProvider);

                return ElevatedButton(
                  onPressed: state.isLoading
                      ? null
                      : () async {
                    if (formKey.currentState!.validate()) {
                      await ref
                          .read(physicianDashboardControllerProvider.notifier)
                          .invitePatientByEmail(emailController.text.trim());
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: state.isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
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

class _PatientList extends ConsumerWidget {
  final bool isDesktop;

  const _PatientList({required this.isDesktop});

  bool _isHighRisk(num? glucose) {
    if (glucose == null) return false;
    return glucose < 70 || glucose > 250;
  }

  // Helper function to get the trend description from its number
  String _getGlucoseTrendLabel(dynamic trendValue) {
    // Handle if the value from the backend is a String
    final int value = trendValue is String ? int.tryParse(trendValue) ?? 8 : (trendValue as int? ?? 8);

    const trendMap = {
      0: 'None',
      1: 'Rising Rapidly', // Changed for clarity
      2: 'Rising',
      3: 'Rising Slowly', // Changed for clarity
      4: 'Stable',
      5: 'Falling Slowly', // Changed for clarity
      6: 'Falling',
      7: 'Falling Rapidly', // Changed for clarity
      8: 'Not Computable',
      9: 'Rate Out of Range',
    };

    return trendMap[value] ?? 'N/A';
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(physicianPatientsListProvider);
    final searchQuery = ref.watch(patientSearchQueryProvider);

    return Padding(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      child: patientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading patients: $err')),
        data: (patients) {
          final filteredPatients = patients.where((patient) {
            final nameMatch = patient.fullName.toLowerCase().contains(searchQuery.toLowerCase());
            // You can add email matching here if your model has it
            return nameMatch;
          }).toList();

          if (filteredPatients.isEmpty) {
            if (searchQuery.isNotEmpty) {
              return const Center(child: Text("No patients found matching your search."));
            }
            return const Center(
              child: Text("No patients assigned yet. Click 'Add Patient' to start."),
            );
          }

          final sortedPatients = List.from(filteredPatients);
          sortedPatients.sort((a, b) {
            final aRisk = _isHighRisk(a.latestGlucoseValue);
            final bRisk = _isHighRisk(b.latestGlucoseValue);

            if (aRisk && !bRisk) return -1;
            if (!aRisk && bRisk) return 1;

            if (!a.isPhysicianConfirmed && b.isPhysicianConfirmed) return -1;
            if (a.isPhysicianConfirmed && !b.isPhysicianConfirmed) return 1;

            return 0;
          });

          return ListView.builder(
            itemCount: sortedPatients.length,
            itemBuilder: (context, index) {
              final patient = sortedPatients[index];
              final isHighRisk = _isHighRisk(patient.latestGlucoseValue);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: isHighRisk
                    ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.red, width: 2),
                )
                    : null,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: isHighRisk
                        ? Colors.red
                        : (patient.isPhysicianConfirmed
                        ? AppColors.primary
                        : Colors.grey),
                    child: Icon(
                      isHighRisk ? Icons.warning_amber_rounded : Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  title: Row(
                    children: [
                      // 1. NAME: Wrapped in Flexible so it shrinks if needed
                      Flexible(
                        child: Text(
                          patient.fullName,
                          style: AppTextStyles.headline2,
                          overflow: TextOverflow.ellipsis, // Adds "..." if name is too long
                          maxLines: 1,
                        ),
                      ),

                      // 2. AGE: Not wrapped, so it will ALWAYS be visible
                      // We add a small space before it so it doesn't touch the name
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Text(
                          '(${patient.age}yo)',
                          // Optional: Make age slightly lighter or smaller to distinguish from name
                          style: AppTextStyles.headline2.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.normal
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // 3. BADGE: Always visible
                      if (isHighRisk)
                        _buildBadge("CRITICAL", Colors.red)
                      else if (!patient.isPhysicianConfirmed)
                        _buildBadge("PENDING", Colors.orange),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phone: ${patient.phoneNumber}',
                          style: AppTextStyles.bodyText2,
                        ),
                        if (patient.latestGlucoseValue != null)
                          Text(
                            'Latest Glucose: ${patient.latestGlucoseValue} mg/dL (${_getGlucoseTrendLabel(patient.latestGlucoseTrend)})',
                            style: TextStyle(
                              color: isHighRisk ? Colors.red : Colors.black87,
                              fontWeight:
                              isHighRisk ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientAnalysisScreen(
                          patientId: patient.id,
                          patientName: patient.fullName,
                        ),
                      ),
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

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
