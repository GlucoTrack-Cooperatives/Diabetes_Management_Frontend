class UpdateAlertSettingsRequest {
  final double lowThreshold;
  final double highThreshold;
  final double criticalLowThreshold;
  final double criticalHighThreshold;
  final bool isSoundEnabled;
  final bool isNotificationEnabled;

  UpdateAlertSettingsRequest({
    required this.lowThreshold,
    required this.highThreshold,
    required this.criticalLowThreshold,
    required this.criticalHighThreshold,
    required this.isSoundEnabled,
    required this.isNotificationEnabled,
  });

  Map<String, dynamic> toJson() => {
    'low_threshold': lowThreshold,
    'high_threshold': highThreshold,
    'critical_low_threshold': criticalLowThreshold,
    'critical_high_threshold': criticalHighThreshold,
    'is_sound_enabled': isSoundEnabled,
    'is_notification_enabled': isNotificationEnabled,
  };
}