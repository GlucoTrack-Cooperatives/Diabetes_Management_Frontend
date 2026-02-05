// Instead of manually adding headers for authorization
// We have a central API client
// This Client will automatically intercept every request, check for a token, and attach it.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'secure_storage_service.dart';

// Provider that automatically gives you an authenticated client
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(storageServiceProvider));
});

class ApiClient {
  final SecureStorageService _storage;
  // Define your base URL here centrally - pointing to GKE production backend
  String get baseUrl {
    if (kIsWeb) return "http://127.0.0.1:8080/api/diabetes-management/api";
    // Android emulator uses 10.0.2.2 to reach host machine
    if (Platform.isAndroid) return "http://10.0.2.2:8080/api/diabetes-management/api";
    // iOS simulator can use localhost
    return "http://127.0.0.1:8080/api/diabetes-management/api";
  }

  ApiClient(this._storage);

  // Helper to get headers with Token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Generic GET
  Future<dynamic> get(String endpoint, {Map<String, String>? queryParameters}) async {
    Uri uri = Uri.parse('$baseUrl$endpoint');
    if (queryParameters != null) {
      uri = uri.replace(queryParameters: queryParameters);
    }

    final headers = await _getHeaders();

    if (kDebugMode) {
      print('=== API GET REQUEST ===');
      print('URL: $uri');
      print('Headers: ${headers.keys.join(", ")}');
      if (headers['Authorization'] != null) {
        print('Auth: ${headers['Authorization']!.substring(0, 20)}...');
      } else {
        print('Auth: NONE');
      }
    }

    final response = await http.get(uri, headers: headers);

    if (kDebugMode) {
      print('Response Status: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
      }
    }

    return _handleResponse(response, uri);
  }

  // Generic POST
  Future<dynamic> post(String endpoint, dynamic data) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();

    if (kDebugMode) {
      print('API POST: $uri');
    }

    final response = await http.post(uri, headers: headers, body: jsonEncode(data));
    return _handleResponse(response, uri);
  }

  // Generic PUT
  Future<dynamic> put(String endpoint, dynamic data) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();

    if (kDebugMode) {
      print('API PUT: $uri');
    }

    final response = await http.put(uri, headers: headers, body: jsonEncode(data));
    return _handleResponse(response, uri);
  }

  // Generic DELETE
  Future<dynamic> delete(String endpoint, [dynamic data]) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();

    if (kDebugMode) {
      print('API DELETE: $uri');
    }

    final response = data != null
        ? await http.delete(uri, headers: headers, body: jsonEncode(data))
        : await http.delete(uri, headers: headers);
    return _handleResponse(response, uri);
  }

  dynamic _handleResponse(http.Response response, Uri uri) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      if (kDebugMode) {
        print('API 401 Unauthorized: $uri');
      }
      throw Exception('Unauthorized: Please login again.');
    } else {
      // UPDATED: Extract message from error response
      String errorMessage = 'Error ${response.statusCode}';

      try {
        final responseData = jsonDecode(response.body);
        if (responseData is Map && responseData.containsKey('message')) {
          errorMessage = responseData['message'];
        } else {
          errorMessage = response.body;
        }
      } catch (e) {
        errorMessage = response.body;
      }

      if (kDebugMode) {
        print('API Error ${response.statusCode} from $uri: $errorMessage');
      }

      throw Exception(errorMessage);
    }
  }
}
