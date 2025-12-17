// lib/auth/login/auth_provider.dart

import 'package:diabetes_management_system/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Create a simple provider for your AuthService
// This allows Riverpod to provide an instance of AuthService wherever it's needed.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// 2. Define the states our authentication can be in
// We add a 'token' to the success state to hold the login token.
class AuthState {
  final AuthStatus status;
  final String? errorMessage;

  AuthState(this.status, {this.errorMessage});
}

enum AuthStatus { initial, loading, success, error }


// 3. Create the Notifier class that uses the AuthService
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  // The notifier now requires an AuthService to be passed in.
  AuthNotifier(this._authService) : super(AuthState(AuthStatus.initial));

  Future<void> login(String email, String password) async {
    state = AuthState(AuthStatus.loading);
    try {
      // Call the login method from our service
      final token = await _authService.login(email, password);

      // IMPORTANT: Here you would save the token securely, for example using flutter_secure_storage
      print('Login successful. Token: $token');

      state = AuthState(AuthStatus.success);
    } catch (e) {
      state = AuthState(AuthStatus.error, errorMessage: e.toString());
    }
  }
}

// 4. Create the final StateNotifierProvider
// This provider will create an instance of AuthNotifier.
// It uses 'ref.watch' to get the AuthService instance from the 'authServiceProvider'.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
