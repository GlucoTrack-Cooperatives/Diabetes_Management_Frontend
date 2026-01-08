import 'dart:convert';
import 'package:diabetes_management_system/services/api_client.dart';
import 'package:diabetes_management_system/services/secure_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// Provider for the service
final foodAnalysisRepositoryProvider = Provider<FoodAnalysisRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storageService = ref.watch(storageServiceProvider);
  return FoodAnalysisRepository(apiClient, storageService);
});

class FoodAnalysisRepository {
  final ApiClient _client;
  final SecureStorageService _storage;

  FoodAnalysisRepository(this._client, this._storage);

  Future<Map<String, dynamic>?> analyzeFoodImage(String patientId,
      XFile image) async {
    try {
      final uri = Uri.parse(
          '${_client.baseUrl}/patients/$patientId/logs/analyze');
      var request = http.MultipartRequest('POST', uri);

      final token = await _storage.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // 3. Add the file
      final bytes = await image.readAsBytes();
      request.files.add(
          http.MultipartFile.fromBytes(
              'file', // Matches @RequestParam("file") in Spring Boot
              bytes,
              filename: image.name
          )
      );

      // 4. Send Request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("Flutter: Status Code: ${response.statusCode}");
      print("Flutter: Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);

        // Safety check: ensure we actually got a map back
        if (decoded is! Map<String, dynamic>) {
          print("Flutter: Error - Expected JSON Map but got ${decoded
              .runtimeType}");
          return null;
        }

        final data = decoded;

        // SAFE PARSING: Handles Int, String, or Null safely
        return {
          'description': data['description']?.toString() ?? 'Unknown Food',
          'calories': data['calories']?.toString() ?? '0',
          'carbs': data['carbs']?.toString() ?? '0',
        };
      } else {
        print('Backend Analysis Error: ${response.statusCode} - ${response
            .body}');
        return null;
      }
    } catch (e, stack) {
      // Print stack trace to see EXACTLY why it crashed
      print('Exception during analysis: $e');
      print('Stack trace: $stack');
      return null;
    }
  }
}