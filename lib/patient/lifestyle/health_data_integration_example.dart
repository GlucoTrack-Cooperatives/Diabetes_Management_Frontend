import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'health_data_controller.dart';

/// Example widget showing how to integrate Health API
/// This can be integrated into your logging screens
class HealthDataIntegrationExample extends ConsumerStatefulWidget {
  const HealthDataIntegrationExample({super.key});

  @override
  ConsumerState<HealthDataIntegrationExample> createState() =>
      _HealthDataIntegrationExampleState();
}

class _HealthDataIntegrationExampleState
    extends ConsumerState<HealthDataIntegrationExample> {
  bool _hasPermissions = false;
  int? _todaySteps;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final controller = ref.read(healthDataControllerProvider);
    final hasPermissions = await controller.checkPermissions();
    setState(() {
      _hasPermissions = hasPermissions;
    });
  }

  Future<void> _requestPermissions() async {
    final controller = ref.read(healthDataControllerProvider);
    final granted = await controller.requestPermissions();

    if (granted) {
      setState(() {
        _hasPermissions = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Health permissions granted!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Health permissions denied'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchTodaySteps() async {
    final controller = ref.read(healthDataControllerProvider);
    final steps = await controller.fetchTodaySteps();
    setState(() {
      _todaySteps = steps;
    });
  }

  Future<void> _fetchTodayData() async {
    final controller = ref.read(healthDataControllerProvider);
    await controller.fetchTodayHealthData();
  }

  Future<void> _saveBloodGlucose() async {
    // Example: Save a blood glucose reading of 120 mg/dL
    final controller = ref.read(healthDataControllerProvider);
    final success = await controller.saveBloodGlucose(120.0, DateTime.now());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Blood glucose saved to Health!'
                : 'Failed to save blood glucose',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final healthData = ref.watch(healthDataListProvider);
    final isLoading = ref.watch(healthDataLoadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health API Integration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Permissions status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      _hasPermissions
                          ? '✓ Health permissions granted'
                          : '✗ Health permissions not granted',
                      style: TextStyle(
                        fontSize: 16,
                        color: _hasPermissions ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!_hasPermissions)
                      ElevatedButton(
                        onPressed: _requestPermissions,
                        child: const Text('Request Health Permissions'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Steps display
            if (_hasPermissions) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Today\'s Steps',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _todaySteps?.toString() ?? 'Not loaded',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchTodaySteps,
                        child: const Text('Fetch Today\'s Steps'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Fetch all data button
              ElevatedButton(
                onPressed: _fetchTodayData,
                child: const Text('Fetch All Today\'s Health Data'),
              ),
              const SizedBox(height: 16),

              // Health data display
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Health Data',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : healthData.isEmpty
                                  ? const Center(
                                      child: Text('No health data available'),
                                    )
                                  : ListView.builder(
                                      itemCount: healthData.length,
                                      itemBuilder: (context, index) {
                                        final point = healthData[index];
                                        return ListTile(
                                          title: Text(point.type),
                                          subtitle: Text(
                                            '${point.value.toStringAsFixed(1)} ${point.unit}',
                                          ),
                                          trailing: Text(
                                            '${point.timestamp.hour}:${point.timestamp.minute.toString().padLeft(2, '0')}',
                                          ),
                                        );
                                      },
                                    ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Example: Save data to health
              ElevatedButton(
                onPressed: _saveBloodGlucose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Save Sample Blood Glucose to Health'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
