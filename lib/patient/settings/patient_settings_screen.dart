import 'package:diabetes_management_system/models/patient_profile.dart';
import 'package:diabetes_management_system/models/patient_profile_update_request.dart';
import 'package:diabetes_management_system/models/update_alert_settings_request.dart';
import 'package:diabetes_management_system/models/patient_alert_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/widgets/custom_elevated_button.dart';
import 'package:diabetes_management_system/widgets/custom_text_form_field.dart';
import 'package:diabetes_management_system/patient/dashboard/patient_dashboard_controller.dart';
import 'package:diabetes_management_system/patient/settings/patient_settings_controller.dart';

class PatientSettingsScreen extends ConsumerStatefulWidget {
  const PatientSettingsScreen({super.key});

  @override
  ConsumerState<PatientSettingsScreen> createState() => _PatientSettingsScreenState();
}

class _PatientSettingsScreenState extends ConsumerState<PatientSettingsScreen> {
  final _personalInfoFormKey = GlobalKey<FormState>();
  final _alertsFormKey = GlobalKey<FormState>();

  // --- Personal Info Controllers ---
  late TextEditingController _firstNameController;
  late TextEditingController _surNameController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  late TextEditingController _diagnosisDateController;
  late TextEditingController _emergencyContactPhoneController;

  // --- Alert Settings Controllers ---
  late TextEditingController _lowCtrl;
  late TextEditingController _highCtrl;
  late TextEditingController _critLowCtrl;
  late TextEditingController _critHighCtrl;
  bool _soundEnabled = true;
  bool _notificationEnabled = true;

  bool _isPersonalInitialized = false;
  bool _isAlertsInitialized = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _surNameController = TextEditingController();
    _phoneController = TextEditingController();
    _dobController = TextEditingController();
    _diagnosisDateController = TextEditingController();
    _emergencyContactPhoneController = TextEditingController();

    _lowCtrl = TextEditingController();
    _highCtrl = TextEditingController();
    _critLowCtrl = TextEditingController();
    _critHighCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _surNameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _diagnosisDateController.dispose();
    _emergencyContactPhoneController.dispose();
    _lowCtrl.dispose();
    _highCtrl.dispose();
    _critLowCtrl.dispose();
    _critHighCtrl.dispose();
    super.dispose();
  }

  /// Initializes Personal Info from Dashboard data
  void _initializePersonalControllers(Patient p) {
    if (_isPersonalInitialized) return;
    _firstNameController.text = p.firstName;
    _surNameController.text = p.surName;
    _phoneController.text = p.phoneNumbers;
    _dobController.text = p.dob;
    _diagnosisDateController.text = p.diagnosisDate;
    _emergencyContactPhoneController.text = p.emergencyContactPhone;
    _isPersonalInitialized = true;
  }

  /// Initializes Alert Thresholds from Clinical Settings data (Backend DTO)
  void _initializeAlertControllers(Map<String, dynamic> settings) {
    if (_isAlertsInitialized) return;

    // Using backend keys from PatientSettingsDTO
    _lowCtrl.text = (settings['lowThreshold'] ?? '3.9').toString();
    _highCtrl.text = (settings['highThreshold'] ?? '10.0').toString();
    _critLowCtrl.text = (settings['criticalLowThreshold'] ?? '3.0').toString();
    _critHighCtrl.text = (settings['criticalHighThreshold'] ?? '13.9').toString();

    // Note: Local state for UI toggles (if not provided by this specific backend endpoint)
    _isAlertsInitialized = true;
  }

  Future<void> _updateAlertSettings() async {
    if (!_alertsFormKey.currentState!.validate()) return;

    final currentSettings = ref.read(clinicalSettingsProvider).valueOrNull ?? {};

    final request = UpdateAlertSettingsRequest(
      lowThreshold: double.parse(_lowCtrl.text),
      highThreshold: double.parse(_highCtrl.text),
      criticalLowThreshold: double.parse(_critLowCtrl.text),
      criticalHighThreshold: double.parse(_critHighCtrl.text),
      // Ensure these are NOT null to satisfy Backend constraints
      targetRangeLow: (currentSettings['targetRangeLow'] ?? 4.0).toDouble(),
      targetRangeHigh: (currentSettings['targetRangeHigh'] ?? 10.0).toDouble(),
      insulinCarbRatio: (currentSettings['insulinCarbRatio'] ?? 10.0).toDouble(),
      correctionFactor: (currentSettings['correctionFactor'] ?? 2.0).toDouble(),
    );

    await ref.read(patientSettingsControllerProvider.notifier).updateAlerts(request);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Alert thresholds updated successfully")),
      );
    }
  }

  Future<void> _handleUpdatePersonalInfo(String patientId) async {
    if (!_personalInfoFormKey.currentState!.validate()) return;

    final request = PatientProfileUpdateRequest(
      firstName: _firstNameController.text.trim(),
      surName: _surNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      dob: _dobController.text.trim(),
      diagnosisDate: _diagnosisDateController.text.trim(),
      emergencyContactPhone: _emergencyContactPhoneController.text.trim(),
    );

    await ref.read(patientSettingsControllerProvider.notifier).updateProfile(patientId, request);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardControllerProvider);
    final clinicalSettingsAsync = ref.watch(clinicalSettingsProvider);
    final settingsState = ref.watch(patientSettingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Alerts')),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (data) {
          if (data.patient == null) return const Center(child: Text("No patient found."));

          _initializePersonalControllers(data.patient!);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPhysicianSection(data.patient!),

                // --- 1. GLUCOSE ALERTS SECTION ---
                _buildSectionHeader("Glucose Alerts"),
                const SizedBox(height: 12),
                clinicalSettingsAsync.when(
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (e, stack) {
                    // 1. Log the EXACT error so you can see it in the terminal
                    debugPrint('!!! Clinical Settings Error: $e');
                    debugPrint('!!! StackTrace: $stack');

                    // 2. Instead of just showing "Failed to load", initialize with defaults
                    // so the user can still see the form and save new settings.
                    _initializeAlertControllers({});
                    return _buildAlertsCard(settingsState.isLoading);
                  }, data: (settingsMap) {
                  _initializeAlertControllers(settingsMap);
                  return _buildAlertsCard(settingsState.isLoading);
                },
                ),

                const SizedBox(height: 24),
                const Divider(thickness: 1),
                const SizedBox(height: 16),

                // --- 2. PERSONAL INFORMATION SECTION ---
                _buildSectionHeader("Personal Information"),
                const SizedBox(height: 16),
                _buildPersonalInfoForm(data.patient!.id, settingsState.isLoading),

                const SizedBox(height: 24),
                const Divider(thickness: 1),
                const SizedBox(height: 16),

                // --- 3. INTEGRATIONS SECTION ---
                _buildSectionHeader("Integrations"),
                const SizedBox(height: 12),
                _buildDexcomCard(),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAlertsCard(bool isLoading) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _alertsFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Thresholds (mmol/L)", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildSmallInput(_critLowCtrl, "Crit Low", Colors.red.shade900)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildSmallInput(_lowCtrl, "Low", Colors.orange)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildSmallInput(_highCtrl, "High", Colors.orange)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildSmallInput(_critHighCtrl, "Crit High", Colors.red.shade900)),
                ],
              ),
              const Divider(height: 32),
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
                value: _soundEnabled,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _soundEnabled = v),
              ),
              const SizedBox(height: 16),
              _buildAlertPreviewSection(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: isLoading ? null : _updateAlertSettings,
                  child: isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Save Alert Settings"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoForm(String patientId, bool isLoading) {
    return Form(
      key: _personalInfoFormKey,
      child: Column(
        children: [
          CustomTextFormField(controller: _firstNameController, labelText: "First Name"),
          const SizedBox(height: 12),
          CustomTextFormField(controller: _surNameController, labelText: "Surname"),
          const SizedBox(height: 12),
          CustomTextFormField(controller: _phoneController, labelText: "Phone Number", keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          CustomTextFormField(controller: _dobController, labelText: "Date of Birth (YYYY-MM-DD)"),
          const SizedBox(height: 20),
          CustomTextFormField(controller: _diagnosisDateController, labelText: "Diagnosis Date", keyboardType: TextInputType.datetime, validator: (v) => v!.isEmpty ? "Required" : null,),
          const SizedBox(height: 16),
          CustomTextFormField(controller: _emergencyContactPhoneController, labelText: "Emergency Contact", keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? "Required" : null,),
          const SizedBox(height: 20),
          CustomElevatedButton(
            text: "Update Profile",
            onPressed: isLoading ? null : () => _handleUpdatePersonalInfo(patientId),
          ),
        ],
      ),
    );
  }

  Widget _buildDexcomCard() {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.import_export, color: AppColors.accent, size: 32),
        title: const Text("Dexcom G6/G7"),
        subtitle: const Text("Sync your glucose data."),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _showDexcomDialog,
          child: const Text("Connect", style: TextStyle(color: Colors.white, fontSize: 11)),
        ),
      ),
    );
  }

  Widget _buildAlertPreviewSection() {
    final double? critLow = double.tryParse(_critLowCtrl.text);
    final double? low = double.tryParse(_lowCtrl.text);
    final double? high = double.tryParse(_highCtrl.text);
    final double? critHigh = double.tryParse(_critHighCtrl.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Preview", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
        _buildAlertRow('Crit Low', critLow, Colors.red.shade900),
        _buildAlertRow('Low', low, Colors.orange),
        _buildAlertRow('High', high, Colors.orange),
        _buildAlertRow('Crit High', critHigh, Colors.red.shade900),
      ],
    );
  }

  Widget _buildAlertRow(String label, double? value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
          const Spacer(),
          if (value != null) Text('${value.toStringAsFixed(1)} mmol/L', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSmallInput(TextEditingController ctrl, String label, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: TextFormField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (v) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary));
  }

  Widget _buildPhysicianSection(Patient patient) {
    debugPrint('Physician Name: ${patient.physicianName}, IsConfirmed: ${patient.isPhysicianConfirmed}');

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
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: AppColors.primary, child: Icon(Icons.medical_services, color: Colors.white)),
            title: Text("Dr. ${patient.physicianName}"),
            subtitle: Text(isConfirmed ? "Confirmed" : "Pending..."),
            trailing: isConfirmed
                ? const Icon(Icons.check_circle, color: Colors.green)
                : ElevatedButton(
              onPressed: () => ref.read(patientSettingsControllerProvider.notifier).acceptPhysicianRequest(patient.id),
              child: const Text("Accept"),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
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
}
