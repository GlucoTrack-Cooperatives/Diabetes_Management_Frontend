import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/patient_appointment.dart';
import '../../repositories/appointment_repository.dart';
import '../../repositories/chat_repository.dart';

final patientAppointmentsProvider = FutureProvider.autoDispose.family<List<PatientAppointment>, String>((ref, patientId) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.getPatientAppointments(patientId);
});

final patientAppointmentsControllerProvider = StateNotifierProvider.family<PatientAppointmentsController, AsyncValue<void>, String>((ref, patientId) {
  return PatientAppointmentsController(
    ref.watch(appointmentRepositoryProvider),
    ref.watch(chatRepositoryProvider),
    ref,
    patientId,
  );
});

class PatientAppointmentsController extends StateNotifier<AsyncValue<void>> {
  final AppointmentRepository _repository;
  final ChatRepository _chatRepository;
  final Ref _ref;
  final String _patientId;

  PatientAppointmentsController(this._repository, this._chatRepository, this._ref, this._patientId) : super(const AsyncValue.data(null));

  Future<void> recordAppointment({
    required AppointmentType type,
    required DateTime date,
    String? notes,
    bool notifyPatient = true,
  }) async {
    state = const AsyncValue.loading();
    try {
      final request = CreateAppointmentRequest(
        type: type.label,
        appointmentDate: date,
        notes: notes,
      );
      
      await _repository.createAppointment(_patientId, request);
      
      if (notifyPatient) {
        try {
          final threads = await _chatRepository.getChatThreads();
          if (threads.isNotEmpty) {
            // Find the chat thread for this patient
            final thread = threads.firstWhere(
              (t) => t.patientId == _patientId,
            );
            
            final nextDate = date.add(type.frequency);
            final dateStr = "${date.day}/${date.month}/${date.year}";
            final nextDateStr = "${nextDate.day}/${nextDate.month}/${nextDate.year}";
            
            final message = "Automated Message: Your ${type.label} was recorded on $dateStr. Your next one is due around $nextDateStr.";
            await _chatRepository.sendMessage(thread.id, message);
          }
        } catch (chatError) {
          // Silently fail chat notification if thread isn't found
          print("Could not send automated message: $chatError");
        }
      }

      _ref.invalidate(patientAppointmentsProvider(_patientId));
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
