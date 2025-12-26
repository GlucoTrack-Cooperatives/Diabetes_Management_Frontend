import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/auth_repository.dart';
import '../../models/patient_registration_request.dart';

// 1. The State: What can happen? (Initial, Loading, Success, Error)
// We use AsyncValue which is built-in to Riverpod to handle these states easily.
final registrationControllerProvider = StateNotifierProvider<RegistrationController, AsyncValue<void>>((ref) {
  return RegistrationController(ref.watch(authRepositoryProvider));
});

class RegistrationController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;

  RegistrationController(this._repository) : super(const AsyncValue.data(null));

  Future<void> register(PatientRegistrationRequest request) async {
    // 1. Set state to loading
    state = const AsyncValue.loading();

    // 2. Call repository
    state = await AsyncValue.guard(() async {
      await _repository.registerPatient(request);
    });
  }
}