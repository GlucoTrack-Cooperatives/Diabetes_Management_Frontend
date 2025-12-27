import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../services/secure_storage_service.dart';
import '../models/dashboard_models.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(
    ref.watch(apiClientProvider),
    ref.watch(storageServiceProvider),
  );
});

class DashboardRepository {
  final ApiClient _client;
  final SecureStorageService _storage;

  DashboardRepository(this._client, this._storage);

  Future<String> _getPatientId() async {
    final id = await _storage.getUserId();
    if (id == null) throw Exception("User ID not found. Please login again.");
    return id;
  }

  // Future<GlucoseReading> getLatestGlucose() async {
  //   final patientId = await _getPatientId();
  //   final response = await _client.get('/patients/$patientId/dashboard/glucose/latest');
  //   return GlucoseReading.fromJson(response);
  // }
  //
  // Future<List<GlucoseReading>> getGlucoseHistory(int hours) async {
  //   final patientId = await _getPatientId();
  //   final response = await _client.get('/patients/$patientId/dashboard/glucose/history?hours=$hours');
  //   return (response as List).map((e) => GlucoseReading.fromJson(e)).toList();
  // }
  //
  // Future<DashboardStats> getStats() async {
  //   final patientId = await _getPatientId();
  //   final response = await _client.get('/patients/$patientId/dashboard/stats');
  //   return DashboardStats.fromJson(response);
  // }

  // --- 1. LATEST GLUCOSE ---
  Future<GlucoseReading> getLatestGlucose() async {
    final patientId = await _getPatientId();
    final response = await _client.get('/patients/$patientId/dashboard/glucose/latest');

    // FIX: Check for null response
    if (response == null) {
      return GlucoseReading(
          value: 0,
          timestamp: DateTime.now(),
          trend: 'STABLE'
      );
    }

    return GlucoseReading.fromJson(response);
  }

  // --- 2. GLUCOSE HISTORY ---
  Future<List<GlucoseReading>> getGlucoseHistory(int hours) async {
    final patientId = await _getPatientId();
    final response = await _client.get('/patients/$patientId/dashboard/glucose/history?hours=$hours');

    // FIX: Check for null response
    if (response == null) return [];

    return (response as List).map((e) => GlucoseReading.fromJson(e)).toList();
  }

  // --- 3. DASHBOARD STATS ---
  Future<DashboardStats> getStats() async {
    final patientId = await _getPatientId();
    final response = await _client.get('/patients/$patientId/dashboard/stats');

    // FIX: Check for null response
    if (response == null) {
      return DashboardStats(
          timeInRange: 0,
          timeBelowRange: 0,
          averageGlucose: 0
      );
    }

    return DashboardStats.fromJson(response);
  }

  Future<List<RecentMeal>> getRecentMeals() async {
    try {
      final patientId = await _getPatientId();
      final response = await _client.get('/patients/$patientId/dashboard/recent-meals');

      // Backend returns List<LogEntryDTO>
      return (response as List).map((e) => RecentMeal.fromJson(e)).toList();
    } catch (e) {
      print("Error fetching meals: $e");
      return []; // Return empty list on error to avoid crashing UI
    }
  }

}