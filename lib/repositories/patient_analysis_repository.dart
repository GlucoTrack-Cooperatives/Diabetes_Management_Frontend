import 'package:diabetes_management_system/models/dashboard_models.dart';
import 'package:diabetes_management_system/models/patient_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../models/log_entry_dto.dart';

final patientAnalysisRepositoryProvider = Provider<PatientAnalysisRepository>((ref) {
  return PatientAnalysisRepository(ref.watch(apiClientProvider));
});

class PatientAnalysisRepository {
  final ApiClient _apiClient;

  PatientAnalysisRepository(this._apiClient);

  Future<List<LogEntryDTO>> getPatientRecentLogs(String patientId) async {
    final response = await _apiClient.get('/patients/$patientId/logs/recent');
    if (response == null) return [];
    final List<dynamic> body = response;
    return body.map((json) => LogEntryDTO.fromJson(json)).toList();
  }

  Future<List<GlucoseReading>> getGlucoseHistory(int hours, String patientId) async {
    final response = await _apiClient.get('/patients/$patientId/dashboard/glucose/history?hours=$hours');
    if (response == null) return [];
    return (response as List).map((e) => GlucoseReading.fromJson(e)).toList();
  }

  Future<Patient?> getPatientProfile(String patientId) async {
    final response = await _apiClient.get('/patients/$patientId');
    if (response == null) return null;
    return Patient.fromJson(response);
  }
}
