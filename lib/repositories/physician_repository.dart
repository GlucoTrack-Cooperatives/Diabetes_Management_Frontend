import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

// 1. Provider to access this repository globally
final physicianRepositoryProvider = Provider<PhysicianRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PhysicianRepository(apiClient);
});

class PhysicianRepository {
  final ApiClient _apiClient;

  PhysicianRepository(this._apiClient);

  Future<void> invitePatient(String email) async {
    // Matches the backend endpoint: POST /api/physicians/invite-patient
    await _apiClient.post('/physicians/invite-patient', {
      'patientEmail': email,
    });
  }
}
