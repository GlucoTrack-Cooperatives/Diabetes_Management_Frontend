import 'package:diabetes_management_system/models/login_request.dart';
import 'package:diabetes_management_system/models/physician_registration_request.dart';
import 'package:diabetes_management_system/models/patient_registration_request.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';

// Provider to access the repository - now depends on apiClientProvider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

class AuthResult {
  final String token;
  final String role;
  final String userId;

  AuthResult({
    required this.token,
    required this.role,
    required this.userId,
  });
}

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<void> registerPatient(PatientRegistrationRequest request) async {
    try {
      await _apiClient.post('/patients/sign-up', request.toJson());
      // Registration successful
    } catch (e) {
      if (e.toString().contains('Error')) {
        throw Exception('Registration Failed: $e');
      }
      throw Exception('Connection Error: $e');
    }
  }

  Future<void> registerPhysician(PhysicianRegistrationRequest request) async {
    try {
      await _apiClient.post('/physicians/sign-up', request.toJson());
      // Registration successful
    } catch (e) {
      if (e.toString().contains('Error')) {
        throw Exception('Registration Failed: $e');
      }
      throw Exception('Connection Error: $e');
    }
  }

  Future<AuthResult> login(LoginRequest request) async {
    try {
      final response = await _apiClient.post('/auth/login', request.toJson());

      final token = response['jwt'];
      final role = response['role'];
      final userId = response['userId'];

      if (token != null && role != null && userId != null) {
        return AuthResult(
          token: token,
          role: role,
          userId: userId.toString(), // Convert to String if it's an int
        );
      } else {
        throw Exception('Token (jwt), role, or userId not found in response body.');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout', {});
    } catch (e) {
      // Even if logout fails on backend, we might want to continue
      // to clear local storage
      throw Exception('Logout failed: $e');
    }
  }
}