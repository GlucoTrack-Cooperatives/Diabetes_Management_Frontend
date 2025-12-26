import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/auth_repository.dart';
import '../../models/login_request.dart';
import '../../services/secure_storage_service.dart';


// StateNotifierProvider exposing AsyncValue<void>
// AsyncValue handles: data (success), loading, and error automatically.
final loginControllerProvider = StateNotifierProvider<LoginController, AsyncValue<void>>((ref) {
  return LoginController(
    ref.watch(authRepositoryProvider),
    ref.watch(storageServiceProvider), // Inject Storage Service
  );
});

class LoginController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;
  final SecureStorageService _storageService;

  LoginController(this._repository, this._storageService) : super(const AsyncValue.data(null));

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();

    // AsyncValue.guard automatically catches errors and sets state to AsyncValue.error
    state = await AsyncValue.guard(() async {
      final request = LoginRequest(email: email, password: password);

      final result = await _repository.login(request);

      await _storageService.saveCredentials(result.token, result.role, result.userId);

    });
  }

  // LOGOUT logic
  Future<void> logout() async {
    state = const AsyncValue.loading();
    await _storageService.clearAll(); // Clears both token and role
    state = const AsyncValue.data(null);
  }

}