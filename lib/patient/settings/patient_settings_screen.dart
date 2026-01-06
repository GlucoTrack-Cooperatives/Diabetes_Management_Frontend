import 'package:diabetes_management_system/models/patient_profile.dart';
import 'package:diabetes_management_system/models/patient_profile_update_request.dart';
import 'package:diabetes_management_system/models/update_alert_settings_request.dart';
import 'package:diabetes_management_system/models/patient_alert_settings.dart';
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
  final _personalInfoFormKey = GlobalKey<FormState>();
  final _alertsFormKey = GlobalKey<FormState>(); // DEFINED HERE

  // --- Personal Info Controllers ---
  late TextEditingController _firstNameController;
  late TextEditingController _surNameController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  late TextEditingController _diagnosisDateController;
  late TextEditingController _emergencyContactPhoneController;

  // --- Alert Settings Controllers (ADDED THESE) ---
  late TextEditingController _lowCtrl;
  late TextEditingController _highCtrl;
  late TextEditingController _critLowCtrl;
  late TextEditingController _critHighCtrl;
  bool _soundEnabled = true;
  bool _notificationEnabled = true;

  @override
  void initState() {
    super.initState();
    // Personal Info Init
    _firstNameController = TextEditingController();
    _surNameController = TextEditingController();
    _phoneController = TextEditingController();
    _dobController = TextEditingController();
    _diagnosisDateController = TextEditingController();
    _emergencyContactPhoneController = TextEditingController();

    // Alert Init (Defaults)
    _lowCtrl = TextEditingController(text: "3.9");
    _highCtrl = TextEditingController(text: "10.0");
    _critLowCtrl = TextEditingController(text: "3.0");
    _critHighCtrl = TextEditingController(text: "13.9");
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _surNameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _diagnosisDateController.dispose();
    _emergencyContactPhoneController.dispose();

    // Dispose Alert Controllers
    _lowCtrl.dispose();
    _highCtrl.dispose();
    _critLowCtrl.dispose();
    _critHighCtrl.dispose();
    super.dispose();
  }

  // Flag to prevent overwriting user edits while typing if stream updates
  bool _isControllersInitialized = false;

  void _initializeControllers() {
    if (_isControllersInitialized) return;

    final dashboardState = ref.read(dashboardControllerProvider).value;
    if (dashboardState != null && dashboardState.patient != null) {
      final p = dashboardState.patient!;

      // 1. Personal Info
      _firstNameController.text = p.firstName;
      _surNameController.text = p.surName;
      _phoneController.text = p.phoneNumbers;
      _dobController.text = p.dob;
      _diagnosisDateController.text = p.diagnosisDate;
      _emergencyContactPhoneController.text = p.emergencyContactPhone;

      // 2. Alert Settings (Use defaults if null)
      final alerts = p.alertSettings ?? PatientAlertSettings.defaults();

      _lowCtrl.text = alerts.lowThreshold.toString();
      _highCtrl.text = alerts.highThreshold.toString();
      _critLowCtrl.text = alerts.criticalLowThreshold.toString();
      _critHighCtrl.text = alerts.criticalHighThreshold.toString();

      // Don't use setState in build, just assign
      _soundEnabled = alerts.isSoundEnabled;
      _notificationEnabled = alerts.isNotificationEnabled;

      _isControllersInitialized = true;
    }
  }

  // --- LOGIC: Update Alerts ---
  Future<void> _updateAlertSettings() async {
    if (!_alertsFormKey.currentState!.validate()) return;

    // 1. Parse the values (THIS WAS MISSING IN YOUR CODE)
    final double? critLow = double.tryParse(_critLowCtrl.text);
    final double? low = double.tryParse(_lowCtrl.text);
    final double? high = double.tryParse(_highCtrl.text);
    final double? critHigh = double.tryParse(_critHighCtrl.text);

    // 2. Validate Numbers
    if (critLow == null || low == null || high == null || critHigh == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid number format")));
      return;
    }

    // 3. Logic Validation
    if (critLow >= low) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Critical Low must be less than Low")));
      return;
    }
    if (low >= high) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Low must be less than High")));
      return;
    }
    if (high >= critHigh) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("High must be less than Critical High")));
      return;
    }

    final dashboardState = ref.read(dashboardControllerProvider).value;
    if (dashboardState?.patient == null) return;

    // 4. Create Request
    final request = UpdateAlertSettingsRequest(
      lowThreshold: low,
      highThreshold: high,
      criticalLowThreshold: critLow,
      criticalHighThreshold: critHigh,
      isSoundEnabled: _soundEnabled,
      isNotificationEnabled: _notificationEnabled,
    );

    // 5. Call Controller
    await ref.read(patientSettingsControllerProvider.notifier).updateAlerts(
      dashboardState!.patient!.id,
      request,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Alert configuration saved")),
      );
    }
  }

  // --- LOGIC: Update Personal Info ---
  Future<void> _handleUpdatePersonalInfo() async {
    if (!_personalInfoFormKey.currentState!.validate()) return;

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
            const Text("Enter your real Dexcom credentials.", style: TextStyle(fontSize: 12)),
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
              Navigator.pop(ctx);
              await ref.read(patientSettingsControllerProvider.notifier)
                  .connectDexcom(emailCtrl.text.trim(), passCtrl.text.trim());
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Connection request sent')),
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
    final dashboardAsync = ref.watch(dashboardControllerProvider);
    final settingsAsync = ref.watch(patientSettingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Patient Settings')),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (data) {
          if (data.patient == null) return const Center(child: Text("No patient profile found."));

          _initializeControllers();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPhysicianSection(data.patient!),

                // --- NEW SECTION: Alert Configuration ---
                _buildSectionHeader("Alert Configuration"),
                const SizedBox(height: 10),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _alertsFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Thresholds (mmol/L)", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: _buildSmallInput(_critLowCtrl, "Crit Low", Colors.red)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildSmallInput(_lowCtrl, "Low", Colors.orange)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildSmallInput(_highCtrl, "High", Colors.orange)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildSmallInput(_critHighCtrl, "Crit High", Colors.red)),
                            ],
                          ),
                          const Divider(height: 24),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text("Push Notifications"),
                            value: _notificationEnabled,
                            activeColor: AppColors.primary,
                            onChanged: (v) => setState(() => _notificationEnabled = v),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text("Sound Alerts"),
                            subtitle: const Text("Override mute for critical"),
                            value: _soundEnabled,
                            activeColor: AppColors.primary,
                            onChanged: (v) => setState(() => _soundEnabled = v),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: settingsAsync.isLoading ? null : _updateAlertSettings,
                              child: settingsAsync.isLoading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                                  : const Text("Update Alerts"),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),

                const Divider(height: 40, thickness: 2),

                // --- EXISTING SECTION: Personal Info ---
                _buildSectionHeader("Personal Information"),
                const SizedBox(height: 10),
                Form(
                  key: _personalInfoFormKey,
                  child: Column(
                    children: [
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
                        labelText: "Diagnosis Date",
                        keyboardType: TextInputType.datetime,
                        validator: (v) => v!.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextFormField(
                        controller: _emergencyContactPhoneController,
                        labelText: "Emergency Contact",
                        keyboardType: TextInputType.phone,
                        validator: (v) => v!.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 24),
                      CustomElevatedButton(
                        text: "Save Personal Info",
                        onPressed: settingsAsync.isLoading ? null : _handleUpdatePersonalInfo,
                      ),
                    ],
                  ),
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
                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSmallInput(TextEditingController ctrl, String label, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        SizedBox(
          height: 45,
          child: TextFormField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
    );
  }

  Widget _buildPhysicianSection(Patient patient) {
    if (patient.physicianName == null) return const SizedBox.shrink();
    final isConfirmed = patient.isPhysicianConfirmed == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Medical Team"),
        const SizedBox(height: 10),
        Card(
          elevation: 2,
          color: isConfirmed ? Colors.white : Colors.orange.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
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
                      Text("Dr. ${patient.physicianName}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(isConfirmed ? "Primary Physician" : "Requesting to connect...", style: TextStyle(color: isConfirmed ? Colors.grey : Colors.orange.shade800, fontSize: 12)),
                    ],
                  ),
                ),
                if (!isConfirmed)
                  ElevatedButton(
                    onPressed: () { ref.read(patientSettingsControllerProvider.notifier).acceptPhysicianRequest(patient.id); },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text("Accept"),
                  )
                else
                  const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
          ),
        ),
        const Divider(height: 40, thickness: 2),
      ],
    );
  }
}
