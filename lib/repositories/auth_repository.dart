import 'dart:convert';
import 'dart:io';
import 'package:diabetes_management_system/models/login_request.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/patient_registration_request.dart';

// Provider to access the repository
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

class AuthRepository {
  // Helper to get base URL based on platform
  String _getBaseUrl() {
    if (kIsWeb) return "http://127.0.0.1:8080/api/diabetes-management/api/auth";
    if (Platform.isAndroid) return "http://10.0.2.2:8080/api/diabetes-management/api/auth";
    return "http://127.0.0.1:8080/api/diabetes-management/api/auth";
  }

  Future<void> registerPatient(PatientRegistrationRequest request) async {
    final url = Uri.parse('${_getBaseUrl()}/register/patient'); // Assumes this is your Spring endpoint

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Registration successful
        return;
      } else {
        // Parse backend error message if available
        throw Exception('Registration Failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Connection Error: $e');
    }
  }


  Future<String> login(LoginRequest request) async {
    final baseUrl = _getBaseUrl();
    final url = Uri.parse('$baseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(request.toJson()), // handle in models/login_request.dart
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        // Matches AuthToken.builder().jwt(token)
        final token = body['jwt'];

        if (token != null) {
          return token;
        } else {
          throw Exception('Token (jwt) not found in response body.');
        }
      } else {
        throw Exception('Failed to login. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error connecting to backend: $e');
    }
  }

  Future<void> logout() async {
    final url = Uri.parse('${_getBaseUrl()}/logout');
    await http.post(url);

    return;
  }

}