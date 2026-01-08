import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'alert_settings_controller.dart';

/// Screen for configuring glucose alert settings
class AlertSettingsScreen extends ConsumerStatefulWidget {
  const AlertSettingsScreen({super.key});

  @override
  ConsumerState<AlertSettingsScreen> createState() => _AlertSettingsScreenState();
}

class _AlertSettingsScreenState extends ConsumerState<AlertSettingsScreen> {
  late TextEditingController _lowController;
  late TextEditingController _highController;
  late TextEditingController _criticalLowController;
  late TextEditingController _criticalHighController;

  @override
  void initState() {
    super.initState();
    _lowController = TextEditingController();
    _highController = TextEditingController();
    _criticalLowController = TextEditingController();
    _criticalHighController = TextEditingController();

    // Load settings on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(alertSettingsControllerProvider).loadSettings().then((_) {
        _updateControllers();
      });
    });
  }

  void _updateControllers() {
    final settings = ref.read(alertSettingsProvider);
    _lowController.text = settings.lowThreshold.toStringAsFixed(0);
    _highController.text = settings.highThreshold.toStringAsFixed(0);
    _criticalLowController.text = settings.criticalLowThreshold.toStringAsFixed(0);
    _criticalHighController.text = settings.criticalHighThreshold.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _lowController.dispose();
    _highController.dispose();
    _criticalLowController.dispose();
    _criticalHighController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final low = double.tryParse(_lowController.text);
    final high = double.tryParse(_highController.text);
    final criticalLow = double.tryParse(_criticalLowController.text);
    final criticalHigh = double.tryParse(_criticalHighController.text);

    if (low == null || high == null || criticalLow == null || criticalHigh == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid numbers for all thresholds'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate thresholds
    if (criticalLow >= low) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Critical low must be less than low threshold'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (high >= criticalHigh) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('High threshold must be less than critical high'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await ref.read(alertSettingsControllerProvider).updateThresholds(
            lowThreshold: low,
            highThreshold: high,
            criticalLowThreshold: criticalLow,
            criticalHighThreshold: criticalHigh,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alert settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(alertSettingsProvider);
    final controller = ref.read(alertSettingsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Glucose Alert Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Configure your glucose alert thresholds. You\'ll receive notifications when readings are outside these ranges.',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Threshold settings
            Text(
              'Alert Thresholds (mg/dL)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Critical Low
            _buildThresholdField(
              controller: _criticalLowController,
              label: 'Critical Low',
              hint: 'e.g., 54',
              color: Colors.red.shade900,
              icon: Icons.warning_amber,
            ),
            const SizedBox(height: 12),

            // Low
            _buildThresholdField(
              controller: _lowController,
              label: 'Low',
              hint: 'e.g., 70',
              color: Colors.orange,
              icon: Icons.trending_down,
            ),
            const SizedBox(height: 12),

            // High
            _buildThresholdField(
              controller: _highController,
              label: 'High',
              hint: 'e.g., 180',
              color: Colors.orange,
              icon: Icons.trending_up,
            ),
            const SizedBox(height: 12),

            // Critical High
            _buildThresholdField(
              controller: _criticalHighController,
              label: 'Critical High',
              hint: 'e.g., 250',
              color: Colors.red.shade900,
              icon: Icons.warning_amber,
            ),
            const SizedBox(height: 24),

            const Divider(),
            const SizedBox(height: 16),

            // Notification settings
            Text(
              'Notification Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Enable notifications
            SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle: const Text('Receive alerts when glucose is out of range'),
              value: settings.notificationsEnabled,
              onChanged: (value) {
                controller.toggleNotifications(value);
              },
            ),

            // Enable sound
            SwitchListTile(
              title: const Text('Alert Sound'),
              subtitle: const Text('Play sound with notifications'),
              value: settings.soundEnabled,
              onChanged: (value) {
                controller.toggleSound(value);
              },
            ),

            // High alert mandatory info
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.amber.shade900),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'High glucose alerts are always enabled for your safety',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Preview section
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Alert Preview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            _buildAlertPreview('Critical Low', settings.criticalLowThreshold, Colors.red.shade900),
            const SizedBox(height: 8),
            _buildAlertPreview('Low', settings.lowThreshold, Colors.orange),
            const SizedBox(height: 8),
            _buildAlertPreview('Normal', (settings.lowThreshold + settings.highThreshold) / 2, Colors.green),
            const SizedBox(height: 8),
            _buildAlertPreview('High', settings.highThreshold, Colors.orange),
            const SizedBox(height: 8),
            _buildAlertPreview('Critical High', settings.criticalHighThreshold, Colors.red.shade900),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Color color,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon, color: color),
        suffixText: 'mg/dL',
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildAlertPreview(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          Text(
            '${value.toStringAsFixed(0)} mg/dL',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
