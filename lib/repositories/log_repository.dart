import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/food_log_request.dart';

// 1. Provider to access this repository globally
final logRepositoryProvider = Provider<LogRepository>((ref) => LogRepository());

class LogRepository {
  // Replace with your backend URL. Use 10.0.2.2 for Android Emulator, localhost for iOS/Web.
  final String _baseUrl = "http://10.0.2.2:8080";

  Future<void> createFoodLog(String patientId, FoodLogRequest request) async {
    final url = Uri.parse('$_baseUrl/api/patients/$patientId/logs/food');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer $token', // TODO: Add Auth token here later
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201) {
        // Success
        return;
      } else {
        throw Exception('Failed to create log: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
