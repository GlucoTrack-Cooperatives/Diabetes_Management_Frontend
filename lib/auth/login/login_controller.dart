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

      final token = await _repository.login(request);

      // TODO: Securely save the token here (e.g., FlutterSecureStorage)
      await _storageService.saveToken(token);

      print('Login Success. Token: $token');
      // We don't need to return anything, "Success" is implied if no error is thrown
    });
  }

  // LOGOUT logic
  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // 1. Optional: Call server API
      await _repository.logout();

      // 2. Critical: Delete the token locally
      await _storageService.clearToken();
    });
  }
}