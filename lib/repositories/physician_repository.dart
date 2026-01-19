import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../models/physician_patient_summary.dart';
import 'package:dio/dio.dart';

// 1. Provider to access this repository globally
final physicianRepositoryProvider = Provider<PhysicianRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PhysicianRepository(apiClient);
});

class PhysicianRepository {
  final ApiClient _apiClient;

  PhysicianRepository(this._apiClient);

  Future<void> invitePatient(String email) async {
    await _apiClient.post('/physicians/invite-patient', {
      'patientEmail': email,
    });

  }

  Future<List<PhysicianPatientSummary>> getMyPatients() async {
    // Assuming Backend Endpoint: GET /api/physicians/patients
    // The backend uses the Token to know WHICH physician is asking.
    final response = await _apiClient.get('/physicians/patients');

    if (response == null) return [];

    return (response as List)
        .map((e) => PhysicianPatientSummary.fromJson(e))
        .toList();
  }
}
