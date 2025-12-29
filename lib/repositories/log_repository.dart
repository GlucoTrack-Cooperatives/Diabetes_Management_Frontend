import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/food_log_request.dart';
import '../models/insulin_log_request.dart';
import '../models/log_entry_dto.dart';
import '../services/secure_storage_service.dart';

// 1. Provider to access this repository globally
final logRepositoryProvider = Provider<LogRepository>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return LogRepository(storageService);
});

class LogRepository {
  final SecureStorageService _storage;

  LogRepository(this._storage);

  String get _baseUrl {
    if (kIsWeb) {
      return "http://127.0.0.1:8080/api/diabetes-management"; // Web (Localhost)
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return "http://10.0.2.2:8080/api/diabetes-management"; // Android Emulator
    } else {
      return "http://127.0.0.1:8080/api/diabetes-management"; // iOS / Desktop
    }
  }

  Future<void> createFoodLog(String patientId, FoodLogRequest request) async {
    final url = Uri.parse('$_baseUrl/api/patients/$patientId/logs/food');

    final token = await _storage.getToken();

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
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

  Future<List<LogEntryDTO>> getRecentLogs(String patientId) async {
    final url = Uri.parse('$_baseUrl/api/patients/$patientId/logs/recent');
    final token = await _storage.getToken();

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body.map((json) => LogEntryDTO.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch logs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }


  Future<void> createInsulinLog(String patientId, InsulinLogRequest request) async {
    final url = Uri.parse('$_baseUrl/api/patients/$patientId/logs/insulin');
    final token = await _storage.getToken();

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to log insulin: ${response.body}');
    }
  }

}
