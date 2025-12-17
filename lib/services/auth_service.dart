// lib/services/auth_service.dart
//
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // UPDATED: Added '/api/diabetes-management' to the path
  // Android Emulator: 10.0.2.2
  // iOS Simulator: localhost
  final String _baseUrl = "http://10.0.2.2:8080/api/diabetes-management/api/auth";

  Future<String> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/login');

    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
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
}