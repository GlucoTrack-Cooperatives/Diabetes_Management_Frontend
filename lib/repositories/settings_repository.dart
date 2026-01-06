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

  // inside SettingsRepository class...

  Future<void> updateAlertSettings(String patientId, Map<String, dynamic> data) async {
    // Assuming you create a specific endpoint like: PUT /api/patients/{id}/alert-settings
    final response = await _client.put('/patients/$patientId/alert-settings', data);

    if (response.statusCode != 200) {
      throw Exception('Failed to update alert settings');
    }
  }

}