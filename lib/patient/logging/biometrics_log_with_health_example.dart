import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'health_data_controller.dart';

/// Example integration of Health API into a biometrics logging screen
/// This shows how to add an "Import from Health" button
class BiometricsLogWithHealthImport extends ConsumerStatefulWidget {
  const BiometricsLogWithHealthImport({super.key});

  @override
  ConsumerState<BiometricsLogWithHealthImport> createState() =>
      _BiometricsLogWithHealthImportState();
}

class _BiometricsLogWithHealthImportState
    extends ConsumerState<BiometricsLogWithHealthImport> {
  final _glucoseController = TextEditingController();
  final _weightController = TextEditingController();
  bool _isImporting = false;

  @override
  void dispose() {
    _glucoseController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _importFromHealth() async {
    setState(() {
      _isImporting = true;
    });

    try {
      final controller = ref.read(healthDataControllerProvider);

      // Check if we have permissions
      final hasPermissions = await controller.checkPermissions();

      if (!hasPermissions) {
        // Request permissions
        final granted = await controller.requestPermissions();

        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Health permissions are required to import data'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }

      // Fetch recent blood glucose
      final glucoseData = await controller.fetchRecentBloodGlucose();

      if (glucoseData.isNotEmpty) {
        // Get the most recent reading
        final latest = glucoseData.last;
        setState(() {
          _glucoseController.text = latest.value.toStringAsFixed(0);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Imported glucose: ${latest.value.toStringAsFixed(0)} ${latest.unit}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No recent blood glucose data found in Health app'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing from Health: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  Future<void> _syncToHealth(double glucoseValue) async {
    try {
      final controller = ref.read(healthDataControllerProvider);

      final success = await controller.saveBloodGlucose(
        glucoseValue,
        DateTime.now(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Saved to Health app'
                  : 'Failed to save to Health app',
            ),
            backgroundColor: success ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error syncing to Health: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biometrics Log'),
        actions: [
          // Import from Health button
          IconButton(
            icon: _isImporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.health_and_safety),
            onPressed: _isImporting ? null : _importFromHealth,
            tooltip: 'Import from Health',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Glucose input field
            TextField(
              controller: _glucoseController,
              decoration: InputDecoration(
                labelText: 'Blood Glucose (mg/dL)',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: _importFromHealth,
                  tooltip: 'Import from Health',
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Weight input field
            TextField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: () async {
                // Validate and save
                final glucoseText = _glucoseController.text.trim();
                if (glucoseText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter blood glucose value'),
                    ),
                  );
                  return;
                }

                final glucoseValue = double.tryParse(glucoseText);
                if (glucoseValue == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid glucose value'),
                    ),
                  );
                  return;
                }

                // Here you would save to your backend
                // await logRepository.createBiometricsLog(...)

                // Also save to Health app
                await _syncToHealth(glucoseValue);

                // Show success and clear
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Biometrics logged successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  _glucoseController.clear();
                  _weightController.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Save Log'),
            ),
            const SizedBox(height: 16),

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
                        'Tap the Health icon to import your latest readings from Apple Health or Google Health Connect',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
