import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_log_request.dart';
import '../models/insulin_log_request.dart';
import '../models/log_entry_dto.dart';
import '../services/api_client.dart';

// 1. Provider to access this repository globally
final logRepositoryProvider = Provider<LogRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LogRepository(apiClient);
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
}
