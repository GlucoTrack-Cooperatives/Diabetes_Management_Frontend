import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/glucose_alert_settings.dart';
import '../../repositories/alert_settings_repository.dart';

/// Provider for alert settings state
final alertSettingsProvider = StateProvider<GlucoseAlertSettings>((ref) {
  return GlucoseAlertSettings();
});

/// Provider for alert settings controller
final alertSettingsControllerProvider = Provider<AlertSettingsController>((ref) {
  return AlertSettingsController(
    ref.watch(alertSettingsRepositoryProvider),
    ref,
  );
});

/// Controller for managing alert settings
class AlertSettingsController {
  final AlertSettingsRepository _repository;
  final Ref _ref;

  AlertSettingsController(this._repository, this._ref);

  /// Load settings from storage
  Future<void> loadSettings() async {
    try {
      final settings = await _repository.loadSettings();
      _ref.read(alertSettingsProvider.notifier).state = settings;
    } catch (e) {
      print('Error loading settings: $e');
    }
  }
  /// Update display unit preference
  Future<void> updateDisplayUnit(GlucoseUnit unit) async {
    final currentSettings = _ref.read(alertSettingsProvider);
    final updatedSettings = currentSettings.copyWith(displayUnit: unit);

    await _repository.saveSettings(updatedSettings);
    _ref.read(alertSettingsProvider.notifier).state = updatedSettings;
  }

  /// Update threshold values
  Future<void> updateThresholds({
    double? lowThreshold,
    double? highThreshold,
    double? criticalLowThreshold,
    double? criticalHighThreshold,
  }) async {
    final currentSettings = _ref.read(alertSettingsProvider);
    final updatedSettings = currentSettings.copyWith(
      lowThreshold: lowThreshold,
      highThreshold: highThreshold,
      criticalLowThreshold: criticalLowThreshold,
      criticalHighThreshold: criticalHighThreshold,
    );

    await _repository.saveSettings(updatedSettings);
    _ref.read(alertSettingsProvider.notifier).state = updatedSettings;
  }

  /// Toggle sound
  Future<void> toggleSound(bool enabled) async {
    final currentSettings = _ref.read(alertSettingsProvider);
    final updatedSettings = currentSettings.copyWith(soundEnabled: enabled);

    await _repository.saveSettings(updatedSettings);
    _ref.read(alertSettingsProvider.notifier).state = updatedSettings;
  }

  /// Toggle notifications (except high alert if mandatory)
  Future<void> toggleNotifications(bool enabled) async {
    final currentSettings = _ref.read(alertSettingsProvider);
    final updatedSettings = currentSettings.copyWith(notificationsEnabled: enabled);

    await _repository.saveSettings(updatedSettings);
    _ref.read(alertSettingsProvider.notifier).state = updatedSettings;
  }

  /// Determine alert severity based on glucose value
  AlertSeverity getSeverity(double glucoseValue) {
    final settings = _ref.read(alertSettingsProvider);

    if (glucoseValue <= settings.criticalLowThreshold) {
      return AlertSeverity.criticalLow;
    } else if (glucoseValue < settings.lowThreshold) {
      return AlertSeverity.low;
    } else if (glucoseValue >= settings.criticalHighThreshold) {
      return AlertSeverity.criticalHigh;
    } else if (glucoseValue > settings.highThreshold) {
      return AlertSeverity.high;
    } else {
      return AlertSeverity.normal;
    }
  }

  /// Check if alert should be triggered
  bool shouldAlert(double glucoseValue) {
    final settings = _ref.read(alertSettingsProvider);
    
    if (!settings.notificationsEnabled) {
      // High alerts are always enabled if mandatory
      if (settings.highAlertMandatory) {
        return glucoseValue > settings.highThreshold || 
               glucoseValue >= settings.criticalHighThreshold;
      }
      if (settings.lowAlertMandatory) {
        return glucoseValue < settings.lowThreshold || 
               glucoseValue <= settings.criticalLowThreshold;
      }
      return false;
    }

    final severity = getSeverity(glucoseValue);
    return severity != AlertSeverity.normal;
  }
}
