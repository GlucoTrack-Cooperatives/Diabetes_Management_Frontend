import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diabetes_management_system/repositories/auth_repository.dart';
import 'package:diabetes_management_system/models/login_request.dart';
import 'package:diabetes_management_system/services/secure_storage_service.dart';
import 'package:diabetes_management_system/services/fcm_service.dart';
import 'package:diabetes_management_system/patient/dashboard/patient_dashboard_controller.dart';
import 'package:diabetes_management_system/physician/dashboard/physician_dashboard_controller.dart';


final loginControllerProvider = StateNotifierProvider<LoginController, AsyncValue<void>>((ref) {
  return LoginController(
    ref.watch(authRepositoryProvider),
    ref.watch(storageServiceProvider),
    ref.watch(fcmServiceProvider),
    ref,
  );
});

class LoginController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;
  final SecureStorageService _storageService;
  final FcmService _fcmService;
  final Ref _ref;

  LoginController(this._repository, this._storageService, this._fcmService, this._ref) : super(const AsyncValue.data(null));

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final request = LoginRequest(email: email, password: password);
      final result = await _repository.login(request);
      
      // 1. Save new credentials
      await _storageService.saveCredentials(result.token, result.role, result.userId);
      
      // 2. Register FCM
      await _fcmService.registerToken();

      // 3. IMPORTANT: Invalidate providers AFTER saving credentials 
      // to ensure they fetch data for the NEW user.
      _ref.invalidate(dashboardControllerProvider);
      _ref.invalidate(physicianPatientsListProvider);
    });
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();

    try {
      await _fcmService.unregisterToken();
      await _storageService.clearAll();

      // Clear memory state
      _ref.invalidate(dashboardControllerProvider);
      _ref.invalidate(physicianPatientsListProvider);
      
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      await _storageService.clearAll();
      state = AsyncValue.error(e, stack);
    }
  }
}
