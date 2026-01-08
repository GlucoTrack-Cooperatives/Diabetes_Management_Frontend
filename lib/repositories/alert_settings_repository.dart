import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/secure_storage_service.dart';
import '../models/glucose_alert_settings.dart';
import 'dart:convert';

/// Provider for alert settings repository
final alertSettingsRepositoryProvider = Provider<AlertSettingsRepository>((ref) {
  return AlertSettingsRepository(ref.watch(storageServiceProvider));
});

/// Repository for managing glucose alert settings
class AlertSettingsRepository {
  final SecureStorageService _storage;
  static const String _settingsKey = 'glucose_alert_settings';

  AlertSettingsRepository(this._storage);

  /// Load alert settings from storage
  Future<GlucoseAlertSettings> loadSettings() async {
    try {
      final jsonString = await _storage.read(_settingsKey);
      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return GlucoseAlertSettings.fromJson(json);
      }
    } catch (e) {
      print('Error loading alert settings: $e');
    }
    // Return default settings if none exist
    return GlucoseAlertSettings();
  }

  /// Save alert settings to storage
  Future<void> saveSettings(GlucoseAlertSettings settings) async {
    try {
      final jsonString = jsonEncode(settings.toJson());
      await _storage.write(_settingsKey, jsonString);
    } catch (e) {
      print('Error saving alert settings: $e');
      rethrow;
    }
  }

  /// Clear alert settings
  Future<void> clearSettings() async {
    try {
      await _storage.delete(_settingsKey);
    } catch (e) {
      print('Error clearing alert settings: $e');
    }
  }
}
