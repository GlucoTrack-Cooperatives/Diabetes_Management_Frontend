import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/health_api_service.dart';
import '../../models/health_data_point.dart';

/// Provider for the health data list
final healthDataListProvider = StateProvider<List<HealthDataPoint>>((ref) => []);

/// Provider for health data loading state
final healthDataLoadingProvider = StateProvider<bool>((ref) => false);

/// Controller for managing health data integration
class HealthDataController {
  final HealthApiService _healthService;
  final Ref _ref;

  HealthDataController(this._healthService, this._ref);

  /// Request permissions to access health data
  Future<bool> requestPermissions() async {
    try {
      return await _healthService.requestPermissions();
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  /// Check if we have the necessary permissions
  Future<bool> checkPermissions() async {
    try {
      return await _healthService.hasPermissions();
    } catch (e) {
      print('Error checking permissions: $e');
      return false;
    }
  }

  /// Fetch all health data for today
  Future<void> fetchTodayHealthData() async {
    _ref.read(healthDataLoadingProvider.notifier).state = true;

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final data = await _healthService.getAllHealthData(startOfDay, now);
      _ref.read(healthDataListProvider.notifier).state = data;
    } catch (e) {
      print('Error fetching today health data: $e');
      rethrow;
    } finally {
      _ref.read(healthDataLoadingProvider.notifier).state = false;
    }
  }

  /// Fetch health data for a specific date range
  Future<void> fetchHealthData(DateTime start, DateTime end) async {
    _ref.read(healthDataLoadingProvider.notifier).state = true;

    try {
      final data = await _healthService.getAllHealthData(start, end);
      _ref.read(healthDataListProvider.notifier).state = data;
    } catch (e) {
      print('Error fetching health data: $e');
      rethrow;
    } finally {
      _ref.read(healthDataLoadingProvider.notifier).state = false;
    }
  }

  /// Fetch blood glucose data for the last 7 days
  Future<List<HealthDataPoint>> fetchRecentBloodGlucose() async {
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      return await _healthService.getBloodGlucoseData(sevenDaysAgo, now);
    } catch (e) {
      print('Error fetching blood glucose: $e');
      return [];
    }
  }

  /// Fetch step count for today
  Future<int?> fetchTodaySteps() async {
    try {
      final now = DateTime.now();
      return await _healthService.getTotalStepsForDay(now);
    } catch (e) {
      print('Error fetching steps: $e');
      return null;
    }
  }

  /// Save blood glucose reading to health store
  Future<bool> saveBloodGlucose(double value, DateTime timestamp) async {
    try {
      return await _healthService.writeBloodGlucose(value, timestamp);
    } catch (e) {
      print('Error saving blood glucose: $e');
      return false;
    }
  }

  /// Save weight to health store
  Future<bool> saveWeight(double weightKg, DateTime timestamp) async {
    try {
      return await _healthService.writeWeight(weightKg, timestamp);
    } catch (e) {
      print('Error saving weight: $e');
      return false;
    }
  }

  /// Save steps to health store
  Future<bool> saveSteps(int steps, DateTime startTime, DateTime endTime) async {
    try {
      return await _healthService.writeSteps(steps, startTime, endTime);
    } catch (e) {
      print('Error saving steps: $e');
      return false;
    }
  }
}

/// Provider for the health data controller
final healthDataControllerProvider = Provider<HealthDataController>((ref) {
  return HealthDataController(
    ref.watch(healthApiServiceProvider),
    ref,
  );
});
