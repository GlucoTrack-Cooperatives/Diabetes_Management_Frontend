/// Model for glucose alert settings
class GlucoseAlertSettings {
  final double lowThreshold;
  final double highThreshold;
  final double criticalLowThreshold;
  final double criticalHighThreshold;
  final bool soundEnabled;
  final bool notificationsEnabled;
  final bool lowAlertMandatory; // Low threshold alert cannot be disabled
  final bool highAlertMandatory; // High threshold alert cannot be disabled

  GlucoseAlertSettings({
    this.lowThreshold = 70.0, // mg/dL
    this.highThreshold = 180.0, // mg/dL
    this.criticalLowThreshold = 54.0, // mg/dL
    this.criticalHighThreshold = 250.0, // mg/dL
    this.soundEnabled = true,
    this.notificationsEnabled = true,
    this.lowAlertMandatory = true,
    this.highAlertMandatory = true,
  });

  GlucoseAlertSettings copyWith({
    double? lowThreshold,
    double? highThreshold,
    double? criticalLowThreshold,
    double? criticalHighThreshold,
    bool? soundEnabled,
    bool? notificationsEnabled,
    bool? lowAlertMandatory,
    bool? highAlertMandatory,
  }) {
    return GlucoseAlertSettings(
      lowThreshold: lowThreshold ?? this.lowThreshold,
      highThreshold: highThreshold ?? this.highThreshold,
      criticalLowThreshold: criticalLowThreshold ?? this.criticalLowThreshold,
      criticalHighThreshold: criticalHighThreshold ?? this.criticalHighThreshold,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      lowAlertMandatory: lowAlertMandatory ?? this.lowAlertMandatory,
      highAlertMandatory: highAlertMandatory ?? this.highAlertMandatory,
    );
  }

  Map<String, dynamic> toJson() => {
        'lowThreshold': lowThreshold,
        'highThreshold': highThreshold,
        'criticalLowThreshold': criticalLowThreshold,
        'criticalHighThreshold': criticalHighThreshold,
        'soundEnabled': soundEnabled,
        'notificationsEnabled': notificationsEnabled,
        'lowAlertMandatory': lowAlertMandatory,
        'highAlertMandatory': highAlertMandatory,
      };

  factory GlucoseAlertSettings.fromJson(Map<String, dynamic> json) =>
      GlucoseAlertSettings(
        lowThreshold: (json['lowThreshold'] as num?)?.toDouble() ?? 70.0,
        highThreshold: (json['highThreshold'] as num?)?.toDouble() ?? 180.0,
        criticalLowThreshold: (json['criticalLowThreshold'] as num?)?.toDouble() ?? 54.0,
        criticalHighThreshold: (json['criticalHighThreshold'] as num?)?.toDouble() ?? 250.0,
        soundEnabled: json['soundEnabled'] as bool? ?? true,
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
        lowAlertMandatory: json['lowAlertMandatory'] as bool? ?? true,
        highAlertMandatory: json['highAlertMandatory'] as bool? ?? true,
      );

  @override
  String toString() =>
      'GlucoseAlertSettings(low: $lowThreshold, high: $highThreshold, criticalLow: $criticalLowThreshold, criticalHigh: $criticalHighThreshold)';
}

/// Alert severity levels
enum AlertSeverity {
  criticalLow,
  low,
  normal,
  high,
  criticalHigh,
}

/// Extension for alert severity
extension AlertSeverityExtension on AlertSeverity {
  String get title {
    switch (this) {
      case AlertSeverity.criticalLow:
        return 'CRITICAL LOW';
      case AlertSeverity.low:
        return 'Low Glucose';
      case AlertSeverity.normal:
        return 'Normal';
      case AlertSeverity.high:
        return 'High Glucose';
      case AlertSeverity.criticalHigh:
        return 'CRITICAL HIGH';
    }
  }

  String get colorHex {
    switch (this) {
      case AlertSeverity.criticalLow:
        return '#B71C1C'; // Dark red
      case AlertSeverity.low:
        return '#FF9800'; // Orange
      case AlertSeverity.normal:
        return '#4CAF50'; // Green
      case AlertSeverity.high:
        return '#FF9800'; // Orange
      case AlertSeverity.criticalHigh:
        return '#B71C1C'; // Dark red
    }
  }

  String getAdvice(double glucoseValue) {
    switch (this) {
      case AlertSeverity.criticalLow:
        return 'Your glucose is critically low at ${glucoseValue.toStringAsFixed(0)} mg/dL. Consume 15-20g of fast-acting carbs immediately and recheck in 15 minutes. If symptoms persist, seek medical help.';
      case AlertSeverity.low:
        return 'Your glucose is low at ${glucoseValue.toStringAsFixed(0)} mg/dL. Consume 15g of fast-acting carbs (juice, glucose tablets) and recheck in 15 minutes.';
      case AlertSeverity.normal:
        return 'Your glucose level of ${glucoseValue.toStringAsFixed(0)} mg/dL is within normal range. Keep up the good work!';
      case AlertSeverity.high:
        return 'Your glucose is high at ${glucoseValue.toStringAsFixed(0)} mg/dL. Check your insulin dosage, stay hydrated, and consider light exercise. Monitor closely.';
      case AlertSeverity.criticalHigh:
        return 'Your glucose is critically high at ${glucoseValue.toStringAsFixed(0)} mg/dL. Check for ketones, take corrective insulin if advised, stay hydrated, and contact your healthcare provider if it doesn\'t improve.';
    }
  }
}
