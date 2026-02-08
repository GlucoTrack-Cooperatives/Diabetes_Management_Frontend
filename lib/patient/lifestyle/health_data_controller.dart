// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../services/health_api_service.dart';
// import '../../models/health_data_point.dart';
//
// /// Provider for the health data list
// final healthDataListProvider = StateProvider<List<HealthDataPoint>>((ref) => []);
//
// /// Provider for health data loading state
// final healthDataLoadingProvider = StateProvider<bool>((ref) => false);
//
// /// Controller for managing health data integration
// class HealthDataController {
//   final HealthApiService _healthService;
//   final Ref _ref;
//
//   HealthDataController(this._healthService, this._ref);
//
//   /// Request permissions to access health data
//   Future<bool> requestPermissions() async {
//     try {
//       return await _healthService.requestPermissions();
//     } catch (e) {
//       print('Error requesting permissions: $e');
//       return false;
//     }
//   }
//
//   /// Check if we have the necessary permissions
//   Future<bool> checkPermissions() async {
//     try {
//       return await _healthService.hasPermissions();
//     } catch (e) {
//       print('Error checking permissions: $e');
//       return false;
//     }
//   }
//
//   /// Fetch all health data for today
//   Future<void> fetchTodayHealthData() async {
//     _ref.read(healthDataLoadingProvider.notifier).state = true;
//
//     try {
//       final now = DateTime.now();
//       final startOfDay = DateTime(now.year, now.month, now.day);
//
//       // final data = await _healthService.getAllHealthData(startOfDay, now);
//       final data = <HealthDataPoint>[]; // Return empty list to prevent errors
//       _ref.read(healthDataListProvider.notifier).state = data;
//     } catch (e) {
//       print('Error fetching today health data: $e');
//       rethrow;
//     } finally {
//       _ref.read(healthDataLoadingProvider.notifier).state = false;
//     }
//   }
//
//   /// Fetch health data for a specific date range
//   Future<void> fetchHealthData(DateTime start, DateTime end) async {
//     _ref.read(healthDataLoadingProvider.notifier).state = true;
//
//     try {
//       final data = await _healthService.getAllHealthData(start, end);
//       _ref.read(healthDataListProvider.notifier).state = data;
//     } catch (e) {
//       print('Error fetching health data: $e');
//       rethrow;
//     } finally {
//       _ref.read(healthDataLoadingProvider.notifier).state = false;
//     }
//   }
//
//   /// Fetch blood glucose data for the last 7 days
//   Future<List<HealthDataPoint>> fetchRecentBloodGlucose() async {
//     try {
//       final now = DateTime.now();
//       final sevenDaysAgo = now.subtract(const Duration(days: 7));
//
//       return await _healthService.getBloodGlucoseData(sevenDaysAgo, now);
//     } catch (e) {
//       print('Error fetching blood glucose: $e');
//       return [];
//     }
//   }
//
//   /// Fetch step count for the last 24 hours
//   Future<int?> fetchLast24hSteps() async {
//     try {
//       final now = DateTime.now();
//       final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));
//       return await _healthService.getTotalStepsInRange(twentyFourHoursAgo, now);
//     } catch (e) {
//       print('Error fetching steps: $e');
//       return null;
//     }
//   }
//
//   /// Fetch calorie data for the last 24 hours
//   Future<List<HealthDataPoint>> fetchLast24hCalories() async {
//     try {
//       final now = DateTime.now();
//       final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));
//       return await _healthService.getTotalEnergyData(twentyFourHoursAgo, now);
//     } catch (e) {
//       print('Error fetching calories: $e');
//       return [];
//     }
//   }
//
//   /// Save blood glucose reading to health store
//   Future<bool> saveBloodGlucose(double value, DateTime timestamp) async {
//     try {
//       return await _healthService.writeBloodGlucose(value, timestamp);
//     } catch (e) {
//       print('Error saving blood glucose: $e');
//       return false;
//     }
//   }
// }
//
// /// Provider for the health data controller
// final healthDataControllerProvider = Provider<HealthDataController>((ref) {
//   return HealthDataController(
//     ref.watch(healthApiServiceProvider),
//     ref,
//   );
// });
