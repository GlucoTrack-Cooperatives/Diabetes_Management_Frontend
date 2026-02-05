import 'package:diabetes_management_system/models/patient_profile.dart';
import 'package:diabetes_management_system/models/patient_profile_update_request.dart';
import 'package:diabetes_management_system/models/update_alert_settings_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/theme/app_text_styles.dart';
import 'package:diabetes_management_system/widgets/custom_elevated_button.dart';
import 'package:diabetes_management_system/widgets/custom_text_form_field.dart';
import 'package:diabetes_management_system/patient/dashboard/patient_dashboard_controller.dart';
import 'package:diabetes_management_system/patient/settings/patient_settings_controller.dart';
import '../../models/glucose_alert_settings.dart';
import 'alert_settings_controller.dart';

class PatientSettingsScreen extends ConsumerStatefulWidget {
  const PatientSettingsScreen({super.key});

  @override
  ConsumerState<PatientSettingsScreen> createState() => _PatientSettingsScreenState();
}

class _PatientSettingsScreenState extends ConsumerState<PatientSettingsScreen> {
  final _personalInfoFormKey = GlobalKey<FormState>();
  final _alertsFormKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _surNameController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  late TextEditingController _diagnosisDateController;
  late TextEditingController _emergencyContactPhoneController;

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

  void _initializeAlertControllers(Map<String, dynamic> settings) {
    if (_isAlertsInitialized) return;
    _lowCtrl.text = (settings['lowThreshold'] ?? '3.9').toString();
    _highCtrl.text = (settings['highThreshold'] ?? '10.0').toString();
    _critLowCtrl.text = (settings['criticalLowThreshold'] ?? '3.0').toString();
    _critHighCtrl.text = (settings['criticalHighThreshold'] ?? '13.9').toString();
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
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
      ),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (data) {
          if (data.patient == null) return const Center(child: Text("No patient found."));
          _initializePersonalControllers(data.patient!);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPhysicianSection(data.patient!),
                const SizedBox(height: 24),
                _buildSectionHeader("Glucose Alerts"),
                const SizedBox(height: 12),
                clinicalSettingsAsync.when(
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (e, stack) {
                    _initializeAlertControllers({});
                    return _buildAlertsCard(settingsState.isLoading);
                  }, 
                  data: (settingsMap) {
                    _initializeAlertControllers(settingsMap);
                    return _buildAlertsCard(settingsState.isLoading);
                  },
                ),
                const SizedBox(height: 32),
                _buildSectionHeader("Personal Information"),
                const SizedBox(height: 16),
                _buildPersonalInfoForm(data.patient!.id, settingsState.isLoading),
                const SizedBox(height: 32),
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
    return _CozyCard(
      child: Form(
        key: _alertsFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("DISPLAY UNIT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
                SegmentedButton<GlucoseUnit>(
                  segments: const [
                    ButtonSegment(value: GlucoseUnit.mgdL, label: Text('mg/dL')),
                    ButtonSegment(value: GlucoseUnit.mmolL, label: Text('mmol/L')),
                  ],
                  selected: {ref.watch(alertSettingsProvider).displayUnit},
                  onSelectionChanged: (Set<GlucoseUnit> newSelection) {
                    ref.read(alertSettingsControllerProvider).updateDisplayUnit(newSelection.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.border, thickness: 1),
            const SizedBox(height: 16),
            
            const Text("THRESHOLDS (mg/dL)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildSmallCozyInput(_critLowCtrl, "Crit Low")),
                const SizedBox(width: 8),
                Expanded(child: _buildSmallCozyInput(_lowCtrl, "Low")),
                const SizedBox(width: 8),
                Expanded(child: _buildSmallCozyInput(_highCtrl, "High")),
                const SizedBox(width: 8),
                Expanded(child: _buildSmallCozyInput(_critHighCtrl, "Crit High")),
              ],
            ),
            const Divider(height: 32, color: AppColors.border, thickness: 1),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Push Notifications", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              value: _notificationEnabled,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _notificationEnabled = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Sound Alerts", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              value: _soundEnabled,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _soundEnabled = v),
            ),
            const SizedBox(height: 24),
            CustomElevatedButton(
              onPressed: isLoading ? null : _updateAlertSettings,
              text: "Save Alert Settings",
              color: AppColors.primary,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    final Color inputFillColor = const Color(0xFFF2F4F7);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0, bottom: 8.0),
          child: Text(
            label,
            style: AppTextStyles.bodyText1.copyWith(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: inputFillColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            readOnly: true,
            style: AppTextStyles.bodyText1,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: const Icon(Icons.calendar_today, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              filled: true,
              fillColor: inputFillColor,
            ),
            onTap: () async {
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: controller.text.isNotEmpty 
                    ? DateTime.tryParse(controller.text) ?? DateTime.now()
                    : DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );

              if (pickedDate != null) {
                final formattedDate = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                controller.text = formattedDate;
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSmallCozyInput(TextEditingController ctrl, String label) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoForm(String patientId, bool isLoading) {
    return Form(
      key: _personalInfoFormKey,
      child: Column(
        children: [
          CustomTextFormField(controller: _firstNameController, labelText: "First Name"),
          const SizedBox(height: 16),
          CustomTextFormField(controller: _surNameController, labelText: "Surname"),
          const SizedBox(height: 16),
          CustomTextFormField(controller: _phoneController, labelText: "Phone Number", keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          _buildDateField("Date of Birth", _dobController),
          const SizedBox(height: 16),
          _buildDateField("Diagnosis Date", _diagnosisDateController),
          const SizedBox(height: 16),
          CustomTextFormField(controller: _emergencyContactPhoneController, labelText: "Emergency Contact"),
          const SizedBox(height: 24),
          CustomElevatedButton(
            text: "Update Profile",
            onPressed: isLoading ? null : () => _handleUpdatePersonalInfo(patientId),
          ),
        ],
      ),
    );
  }

  Widget _buildDexcomCard() {
    return _CozyCard(
      color: AppColors.skyBlue,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.import_export, color: AppColors.primary, size: 32),
        title: const Text("Dexcom G6/G7", style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text("Sync your data.", style: TextStyle(fontSize: 12)),
        trailing: CustomElevatedButton(
          width: 120,
          height: 60,
          onPressed: _showDexcomDialog,
          text: "Connect",
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: AppTextStyles.headline2.copyWith(fontSize: 18));
  }

  Widget _buildPhysicianSection(Patient patient) {
    if (patient.physicianName == null) return const SizedBox.shrink();
    final isConfirmed = patient.isPhysicianConfirmed == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Medical Team"),
        const SizedBox(height: 12),
        _CozyCard(
          color: isConfirmed ? AppColors.mint : AppColors.peach,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.medical_services, color: AppColors.primary),
            title: Text("Dr. ${patient.physicianName}", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(isConfirmed ? "Confirmed" : "Pending...", style: const TextStyle(fontSize: 12)),
            trailing: isConfirmed ? const Icon(Icons.check_circle, color: AppColors.primary) : CustomElevatedButton(
              width: 100, height: 50, text: "Accept", onPressed: () => ref.read(patientSettingsControllerProvider.notifier).acceptPhysicianRequest(patient.id),
            ),
          ),
        ),
      ],
    );
  }

  void _showDexcomDialog() {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Connect Dexcom"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextFormField(controller: emailCtrl, labelText: "Email"),
            const SizedBox(height: 16),
            CustomTextFormField(controller: passCtrl, labelText: "Password", obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(patientSettingsControllerProvider.notifier).connectDexcom(emailCtrl.text.trim(), passCtrl.text.trim());
            },
            child: const Text("Connect"),
          ),
        ],
      ),
    );
  }

}

class _CozyCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  const _CozyCard({required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
