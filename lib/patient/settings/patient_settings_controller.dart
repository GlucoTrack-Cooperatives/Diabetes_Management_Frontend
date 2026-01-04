import 'package:diabetes_management_system/models/patient_profile_update_request.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/settings_repository.dart';
import '../dashboard/patient_dashboard_controller.dart';

final patientSettingsControllerProvider = StateNotifierProvider<PatientSettingsController, AsyncValue<void>>((ref) {
  return PatientSettingsController(
    ref.watch(settingsRepositoryProvider),
    ref,
  );
});

class PatientSettingsController extends StateNotifier<AsyncValue<void>> {
  final SettingsRepository _repository;
  final Ref _ref;

  PatientSettingsController(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> updateProfile(String patientId, PatientProfileUpdateRequest request) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updatePatientProfile(patientId, request.toJson());

      // Refresh the dashboard data so the new name shows up immediately
      _ref.read(dashboardControllerProvider.notifier).refreshData();

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> connectDexcom(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _repository.connectDexcom(email, password);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> acceptPhysicianRequest(String patientId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.confirmPhysician(patientId);

      // Important: Refresh the dashboard so the profile re-loads with isPhysicianConfirmed = true
      await _ref.read(dashboardControllerProvider.notifier).refreshData();

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}