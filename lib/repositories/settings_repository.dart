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
}