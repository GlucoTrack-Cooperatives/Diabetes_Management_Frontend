import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diabetes_management_system/repositories/auth_repository.dart';
import 'package:diabetes_management_system/models/login_request.dart';
import 'package:diabetes_management_system/services/secure_storage_service.dart';
import 'package:diabetes_management_system/services/fcm_service.dart';


// StateNotifierProvider exposing AsyncValue<void>
// AsyncValue handles: data (success), loading, and error automatically.
final loginControllerProvider = StateNotifierProvider<LoginController, AsyncValue<void>>((ref) {
  return LoginController(
    ref.watch(authRepositoryProvider),
    ref.watch(storageServiceProvider), // Inject Storage Service
    ref.watch(fcmServiceProvider),
  );
});

class LoginController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;
  final SecureStorageService _storageService;
  final FcmService _fcmService;

  LoginController(this._repository, this._storageService, this._fcmService) : super(const AsyncValue.data(null));

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();

    // AsyncValue.guard automatically catches errors and sets state to AsyncValue.error
    state = await AsyncValue.guard(() async {
      final request = LoginRequest(email: email, password: password);

      final result = await _repository.login(request);

      await _storageService.saveCredentials(result.token, result.role, result.userId);

      await _fcmService.registerToken();

    });
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();

    await _fcmService.unregisterToken();

    await _storageService.clearAll();
    state = const AsyncValue.data(null);
  }

}