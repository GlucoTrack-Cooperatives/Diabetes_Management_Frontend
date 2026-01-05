import 'package:diabetes_management_system/services/secure_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_log_request.dart';
import '../models/insulin_log_request.dart';
import '../models/medications_request.dart';
import '../models/log_entry_dto.dart';
import '../services/api_client.dart';

// 1. Provider to access this repository globally
final logRepositoryProvider = Provider<LogRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LogRepository(apiClient);
});

final medicationsProvider = FutureProvider.autoDispose<List<Medication>>((ref) async {
  final repository = ref.watch(logRepositoryProvider);
  final storage = ref.watch(storageServiceProvider);

  // We need the patientId because the endpoint depends on it
  final userId = await storage.getUserId();
  if (userId == null) throw Exception("User not logged in");

  return repository.getMedications(userId);
});

class LogRepository {
  final ApiClient _apiClient;

  LogRepository(this._apiClient);

  Future<void> createFoodLog(String patientId, FoodLogRequest request) async {
    await _apiClient.post('/patients/$patientId/logs/food', request.toJson());
  }

  Future<List<LogEntryDTO>> getRecentLogs(String patientId) async {
    final responseData = await _apiClient.get('/patients/$patientId/logs/recent');
    final List<dynamic> body = responseData;
    return body.map((json) => LogEntryDTO.fromJson(json)).toList();
  }

  Future<void> createInsulinLog(String patientId, InsulinLogRequest request) async {
    await _apiClient.post('/patients/$patientId/logs/insulin', request.toJson());
  }

  Future<List<Medication>> getMedications(String patientId) async {
    final responseData = await _apiClient.get('/patients/$patientId/logs/medications');

    // Convert the raw JSON list into a List of Medication objects
    final List<dynamic> body = responseData;
    return body.map((json) => Medication.fromJson(json)).toList();
  }
}
