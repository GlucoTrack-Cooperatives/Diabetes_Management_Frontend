import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/auth_repository.dart';
import '../../models/patient_registration_request.dart';
import '../../models/physician_registration_request.dart';

final registrationControllerProvider = StateNotifierProvider<RegistrationController, AsyncValue<void>>((ref) {
  return RegistrationController(ref.watch(authRepositoryProvider));
});

class RegistrationController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;

  RegistrationController(this._repository) : super(const AsyncValue.data(null));

  Future<void> registerPatient(PatientRegistrationRequest request) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.registerPatient(request);
    });
  }

  Future<void> registerPhysician(PhysicianRegistrationRequest request) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.registerPhysician(request);
    });
  }
}