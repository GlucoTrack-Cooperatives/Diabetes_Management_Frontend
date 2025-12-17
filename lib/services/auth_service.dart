// lib/services/auth_service.dart

import 'dart:convert'; // Required for jsonEncode and jsonDecode
import 'package:http/http.dart' as http;

class AuthService {
  // Define the base URL of your Spring Boot backend.
  // Replace 'localhost:8080' with your actual backend address.
  // For Android emulator, use '10.0.2.2:8080'. For iOS simulator, 'localhost' is fine.
  final String _baseUrl = "http://10.0.2.2:8080/api/auth";

  // The login method that makes the POST request
  Future<String> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'), // Your specific login endpoint path
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-TF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );

    // Check the response status code
    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the token.
      // Assuming your Spring Boot backend returns a JSON object like: {"token": "your_jwt_token"}
      final body = jsonDecode(response.body);
      final token = body['token'];
      if (token != null) {
        return token;
      } else {
        throw Exception('Token not found in response.');
      }
    } else {
      // If the server did not return a 200 OK response, throw an error.
      // You can parse the error message from the response body if your backend provides one.
      throw Exception('Failed to login. Status code: ${response.statusCode}');
    }
  }
}
