import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/physician_repository.dart';

final physicianDashboardControllerProvider = StateNotifierProvider<PhysicianDashboardController, AsyncValue<void>>((ref) {
  return PhysicianDashboardController(ref.watch(physicianRepositoryProvider));
});

class PhysicianDashboardController extends StateNotifier<AsyncValue<void>> {
  final PhysicianRepository _repository;

  PhysicianDashboardController(this._repository) : super(const AsyncValue.data(null));

  Future<void> invitePatientByEmail(String email) async {
    state = const AsyncValue.loading();
    try {
      await _repository.invitePatient(email);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}