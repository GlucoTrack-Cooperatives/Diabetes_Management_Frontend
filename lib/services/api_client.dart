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
  // Define your base URL here centrally
  String get baseUrl {
    if (kIsWeb) return "http://127.0.0.1:8080/api/diabetes-management/api";
    // if (Platform.isAndroid) return "http://10.0.2.2:8080/api/diabetes-management/api";
    if (Platform.isAndroid) return "http://127.0.0.1:8080/api/diabetes-management/api"; //TODO: CHANGE THIS, THIS WORK FOR PHYSICAL DEVICE BASE ON YOUR IPV4 ADDRESS COMPUTER
    return "http://127.0.0.1:8080/api/diabetes-management/api/diabetes-management/api";
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
  Future<dynamic> get(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();

    final response = await http.get(uri, headers: headers);
    return _handleResponse(response);
  }

  // Generic POST
  Future<dynamic> post(String endpoint, dynamic data) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();

    final response = await http.post(uri, headers: headers, body: jsonEncode(data));
    return _handleResponse(response);
  }

  // Generic PUT
  Future<dynamic> put(String endpoint, dynamic data) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();

    final response = await http.put(uri, headers: headers, body: jsonEncode(data));
    return _handleResponse(response);
  }

  // Generic DELETE
  Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();

    final response = await http.delete(uri, headers: headers);
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      // Handle Token Expiry (Optional: Trigger logout logic here)
      // TODO: Add logout logic here?
      throw Exception('Unauthorized: Please login again.');
    } else {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }
}
