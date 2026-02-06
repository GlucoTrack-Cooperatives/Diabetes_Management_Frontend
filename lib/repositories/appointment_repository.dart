import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/patient_appointment.dart';
import '../services/api_client.dart';

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AppointmentRepository(apiClient);
});

class AppointmentRepository {
  final ApiClient _apiClient;

  AppointmentRepository(this._apiClient);

  Future<List<PatientAppointment>> getPatientAppointments(String patientId) async {
    final response = await _apiClient.get('/physicians/patients/$patientId/appointments');
    if (response == null) return [];
    return (response as List).map((e) => PatientAppointment.fromJson(e)).toList();
  }

  Future<PatientAppointment> createAppointment(String patientId, CreateAppointmentRequest request) async {
    final response = await _apiClient.post('/physicians/patients/$patientId/appointments', request.toJson());
    return PatientAppointment.fromJson(response);
  }
}
