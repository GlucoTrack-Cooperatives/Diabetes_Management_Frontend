import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/patient_profile.dart';
import '../services/api_client.dart';
import '../services/secure_storage_service.dart';
import '../models/dashboard_models.dart';
import '../models/log_entry_dto.dart';

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
  Future<GlucoseReading?> getLatestGlucose() async {
    try {
      final patientId = await _getPatientId();
      final response = await _client.get('/patients/$patientId/dashboard/glucose/latest');

      // Check for null response
      if (response == null) {
        return null;
      }

      return GlucoseReading.fromJson(response);
    } catch (e) {
      print("Error fetching latest glucose: $e");
      return null;
    }
  }

  // --- 2. GLUCOSE HISTORY ---
  Future<List<GlucoseReading>> getGlucoseHistory(int hours) async {
    try {
      final patientId = await _getPatientId();
      final response = await _client.get('/patients/$patientId/dashboard/glucose/history');

      // FIX: Check for null response
      if (response == null) return [];

      return (response as List).map((e) => GlucoseReading.fromJson(e)).toList();
    } catch (e) {
      print("Error fetching glucose history: $e");
      return [];
    }
  }

  // --- 3. DASHBOARD STATS ---
  Future<DashboardStats?> getStats() async {
    try {
      final patientId = await _getPatientId();
      final response = await _client.get('/patients/$patientId/dashboard/stats');

      // FIX: Check for null response
      if (response == null) {
        return null;
      }

      return DashboardStats.fromJson(response);
    } catch (e) {
      print("Error fetching dashboard stats: $e");
      return null;
    }
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

  Future<Map<String, dynamic>> getPatientThresholds() async {
    try {
      final response = await _client.get('/patients/settings');

      if (response is Map<String, dynamic>) {
        return response;
      }
      print("response for thresholds: $response");
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print("Error fetching profile: $e");
      return Map<String, dynamic>();
    }
  }

  Future<List<LogEntryDTO>> getRecentInsulinLogs() async {
    try {
      final patientId = await _getPatientId();
      final response = await _client.get('/patients/$patientId/logs/recent');
      if (response == null) return [];
      
      final List<dynamic> body = response;
      return body
          .map((json) => LogEntryDTO.fromJson(json))
          .where((log) => log.type.toLowerCase() == 'insulin')
          .toList();
    } catch (e) {
      print("Error fetching insulin logs: $e");
      return [];
    }
  }

}