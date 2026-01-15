import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../models/patient_profile.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(apiClientProvider));
});

class SettingsRepository {
  final ApiClient _client;

  SettingsRepository(this._client);

  // Update Patient Profile (Name, Phone, etc.)
  Future<void> updatePatientProfile(String patientId, Map<String, dynamic> data) async {
    await _client.put('/patients/$patientId/profile', data);
  }

  // Connect to Dexcom
  Future<void> connectDexcom(String dexcomEmail, String dexcomPassword) async {
    // Matches the DexcomAuthController endpoint: @PostMapping("/api/dexcom/auth")
    await _client.post('/dexcom/auth', {
      'dexcom_email': dexcomEmail,
      'dexcom_password': dexcomPassword,
    });
  }

  Future<void> confirmPhysician(String patientId) async {
    // Matches Backend: PUT /api/patients/{patientId}/confirm-physician
    await _client.put('/patients/$patientId/confirm-physician', {});
  }

  Future<Map<String, dynamic>> getPatientSettings() async {
    final response = await _client.get('/patients/settings');
    if (response is Map<String, dynamic>) {
      return response;
    }

    // If response is a Response object from Dio:
    return response.data as Map<String, dynamic>;
  }

  // UPDATE the clinical settings
  Future<void> updatePatientSettings(Map<String, dynamic> data) async {
    // Matches Backend: @PutMapping @RequestMapping("/api/patients/settings")
    final response = await _client.put('/patients/settings', data);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to update patient settings');
    }
  }

}