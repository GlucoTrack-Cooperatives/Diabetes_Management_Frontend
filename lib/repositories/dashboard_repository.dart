import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/patient_profile.dart';
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

  // --- 1. LATEST GLUCOSE ---
  Future<GlucoseReading> getLatestGlucose() async {
    final patientId = await _getPatientId();
    final response = await _client.get('/patients/$patientId/dashboard/glucose/latest');

    // Check for null response
    if (response == null) {
      return GlucoseReading(
          value: 0,
          timestamp: DateTime.now(),
          trend: 'NULL'
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
          timeInRange: -99,
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

  Future<Patient?> getPatientProfile() async {
    try {
      final patientId = await _getPatientId();
      final response = await _client.get('/patients/$patientId');

      if (response == null) return null;

      return Patient.fromJson(response);
    } catch (e) {
      print("Error fetching profile: $e");
      return null;
    }
  }

}