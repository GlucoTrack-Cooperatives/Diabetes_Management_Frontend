class PatientAlertSettings {
  final double lowThreshold;       // e.g., 3.9 mmol/L
  final double highThreshold;      // e.g., 10.0 mmol/L
  final double criticalLowThreshold; // e.g., 3.0 mmol/L
  final double criticalHighThreshold; // e.g., 14.0 mmol/L
  final bool isSoundEnabled;
  final bool isNotificationEnabled;

  PatientAlertSettings({
    required this.lowThreshold,
    required this.highThreshold,
    required this.criticalLowThreshold,
    required this.criticalHighThreshold,
    required this.isSoundEnabled,
    required this.isNotificationEnabled,
  });

  // Default factory for new users
  factory PatientAlertSettings.defaults() {
    return PatientAlertSettings(
      lowThreshold: 3.9,
      highThreshold: 10.0,
      criticalLowThreshold: 3.0,
      criticalHighThreshold: 13.9,
      isSoundEnabled: true,
      isNotificationEnabled: true,
    );
  }

  Map<String, dynamic> toJson() => {
    'low_threshold': lowThreshold,
    'high_threshold': highThreshold,
    'critical_low_threshold': criticalLowThreshold,
    'critical_high_threshold': criticalHighThreshold,
    'is_sound_enabled': isSoundEnabled,
    'is_notification_enabled': isNotificationEnabled,
  };

  factory PatientAlertSettings.fromJson(Map<String, dynamic> json) {
    return PatientAlertSettings(
      lowThreshold: (json['low_threshold'] as num?)?.toDouble() ?? 3.9,
      highThreshold: (json['high_threshold'] as num?)?.toDouble() ?? 10.0,
      criticalLowThreshold: (json['critical_low_threshold'] as num?)?.toDouble() ?? 3.0,
      criticalHighThreshold: (json['critical_high_threshold'] as num?)?.toDouble() ?? 13.9,
      isSoundEnabled: json['is_sound_enabled'] ?? true,
      isNotificationEnabled: json['is_notification_enabled'] ?? true,
    );
  }
}
