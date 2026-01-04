import 'package:diabetes_management_system/models/patient_profile.dart';
import 'package:diabetes_management_system/models/patient_profile_update_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_text_form_field.dart';
import '../dashboard/patient_dashboard_controller.dart';
import 'patient_settings_controller.dart';

class PatientSettingsScreen extends ConsumerStatefulWidget {
  const PatientSettingsScreen({super.key});

  @override
  ConsumerState<PatientSettingsScreen> createState() => _PatientSettingsScreenState();
}

class _PatientSettingsScreenState extends ConsumerState<PatientSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for editable fields
  late TextEditingController _firstNameController;
  late TextEditingController _surNameController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  late TextEditingController _diagnosisDateController;
  late TextEditingController _emergencyContactPhoneController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _surNameController = TextEditingController();
    _phoneController = TextEditingController();
    _dobController = TextEditingController();
    _diagnosisDateController = TextEditingController();
    _emergencyContactPhoneController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _surNameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _diagnosisDateController.dispose();
    _emergencyContactPhoneController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    // Pre-fill data from the Dashboard State
    final dashboardState = ref.read(dashboardControllerProvider).value;
    if (dashboardState != null && dashboardState.patient != null) {
      final p = dashboardState.patient!;
      if (_firstNameController.text.isEmpty) _firstNameController.text = p.firstName;
      if (_surNameController.text.isEmpty) _surNameController.text = p.surName;
      if (_phoneController.text.isEmpty) _phoneController.text = p.phoneNumbers;
      if (_dobController.text.isEmpty) _dobController.text = p.dob;
      if (_diagnosisDateController.text.isEmpty) _diagnosisDateController.text = p.diagnosisDate;
      if (_emergencyContactPhoneController.text.isEmpty) _emergencyContactPhoneController.text = p.emergencyContactPhone;
    }
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    final dashboardState = ref.read(dashboardControllerProvider).value;
    if (dashboardState == null || dashboardState.patient == null) return;

    final request = PatientProfileUpdateRequest(
      firstName: _firstNameController.text.trim(),
      surName: _surNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      dob: _dobController.text.trim(),
      diagnosisDate: _diagnosisDateController.text.trim(),
      emergencyContactPhone: _emergencyContactPhoneController.text.trim(),
    );

    await ref.read(patientSettingsControllerProvider.notifier).updateProfile(
          dashboardState.patient!.id,
          request,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  void _showDexcomDialog() {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Connect Dexcom"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter your real Dexcom credentials to sync data.", style: TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: "Dexcom Email", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog first
              await ref.read(patientSettingsControllerProvider.notifier)
                  .connectDexcom(emailCtrl.text.trim(), passCtrl.text.trim());

              // Check for errors via state listening or assumption
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dexcom connection request sent')),
                );
              }
            },
            child: const Text("Connect"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch dashboard state to ensure we have patient data
    final dashboardAsync = ref.watch(dashboardControllerProvider);
    final settingsAsync = ref.watch(patientSettingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Patient Settings')),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading profile: $err')),
        data: (data) {
          if (data.patient == null) return const Center(child: Text("No patient profile found."));

          // Ensure controllers are populated once
          _initializeControllers();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPhysicianSection(data.patient!),
                  _buildSectionHeader("Personal Information"),
                  const SizedBox(height: 10),
                  CustomTextFormField(
                    controller: _firstNameController,
                    labelText: "First Name",
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextFormField(
                    controller: _surNameController,
                    labelText: "Surname",
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextFormField(
                    controller: _phoneController,
                    labelText: "Phone Number",
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextFormField(
                    controller: _dobController,
                    labelText: "Date of Birth (YYYY-MM-DD)",
                    keyboardType: TextInputType.datetime,
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextFormField(
                    controller: _diagnosisDateController,
                    labelText: "Diagnosis Date (YYYY-MM-DD)",
                    keyboardType: TextInputType.datetime,
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextFormField(
                    controller: _emergencyContactPhoneController,
                    labelText: "Emergency Contact Phone",
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  // const SizedBox(height: 16),
                  // TextFormField(
                  //   initialValue: data.patient!.email,
                  //   readOnly: true,
                  //   decoration: const InputDecoration(
                  //     labelText: "Email (Cannot be changed)",
                  //     border: OutlineInputBorder(),
                  //     filled: true,
                  //     fillColor: Colors.black12,
                  //   ),
                  // ),
                  const SizedBox(height: 24),
                  settingsAsync.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : CustomElevatedButton(
                    text: "Save Changes",
                    onPressed: _handleUpdate,
                  ),

                  const Divider(height: 40, thickness: 2),

                  _buildSectionHeader("Integrations"),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.import_export, color: AppColors.accent, size: 32),
                      title: const Text("Dexcom G6/G7"),
                      subtitle: const Text("Connect your account to sync glucose data."),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        onPressed: _showDexcomDialog,
                        child: const Text("Connect", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
    );
  }

  Widget _buildPhysicianSection(Patient patient) {
    // Case 1: No doctor assigned at all
    if (patient.physicianName == null) {
      return const SizedBox.shrink();
    }

    final isConfirmed = patient.isPhysicianConfirmed == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Medical Team"),
        const SizedBox(height: 10),
        Card(
          elevation: 2,
          color: isConfirmed ? Colors.white : Colors.orange.shade50, // Highlight if pending
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.medical_services, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Dr. ${patient.physicianName}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            isConfirmed ? "Primary Physician" : "Requesting to connect...",
                            style: TextStyle(
                              color: isConfirmed ? Colors.grey : Colors.orange.shade800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Show "Accept" button only if NOT confirmed
                    if (!isConfirmed)
                      ElevatedButton(
                        onPressed: () {
                          ref.read(patientSettingsControllerProvider.notifier)
                              .acceptPhysicianRequest(patient.id);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text("Accept"),
                      )
                    else
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 40, thickness: 2),
      ],
    );
  }
}
