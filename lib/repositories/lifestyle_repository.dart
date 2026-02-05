import 'package:diabetes_management_system/services/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/health_event_request.dart';

final lifestyleRepositoryProvider = Provider((ref) => LifestyleRepository(ref.watch(apiClientProvider)));

class LifestyleRepository {
  final ApiClient _apiClient;
  LifestyleRepository(this._apiClient);

  Future<void> logHealthEvent(String patientId, HealthEventRequest request) async {
    await _apiClient.post('/patients/$patientId/lifestyle/event', request.toJson());
  }

  Future<List<HealthEventDTO>> getHealthEvents(String patientId, DateTime start, DateTime end) async {
    final response = await _apiClient.get('/patients/$patientId/lifestyle/events',
      queryParameters: {
        // .toUtc() followed by .toIso8601String() is the standard way to send to an Instant field
        'startDate': start.toUtc().toIso8601String(),
        'endDate': end.toUtc().toIso8601String(),
      },
    );
    return (response as List).map((json) => HealthEventDTO.fromJson(json)).toList();
  }
}