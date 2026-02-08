// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../models/glucose_alert_settings.dart';
// import '../models/health_data_point.dart';
// import '../patient/settings/alert_settings_controller.dart';
//
// /// Provider for glucose monitoring service
// final glucoseMonitoringServiceProvider = Provider<GlucoseMonitoringService>((ref) {
//   return GlucoseMonitoringService(ref);
// });
//
// /// Service for monitoring glucose levels and triggering alerts
// class GlucoseMonitoringService {
//   final Ref _ref;
//   double? _lastGlucoseValue;
//   DateTime? _lastAlertTime;
//
//   GlucoseMonitoringService(this._ref);
//
//   /// Check glucose value and determine if alert should be triggered
//   /// Returns alert severity if alert should be shown, null otherwise
//   AlertSeverity? checkGlucoseLevel(double glucoseValue) {
//     final controller = _ref.read(alertSettingsControllerProvider);
//
//     // Check if alert should be triggered
//     if (!controller.shouldAlert(glucoseValue)) {
//       return null;
//     }
//
//     // Get severity
//     final severity = controller.getSeverity(glucoseValue);
//
//     // Don't alert for normal levels
//     if (severity == AlertSeverity.normal) {
//       return null;
//     }
//
//     // Debounce alerts - don't show same type of alert within 15 minutes
//     if (_shouldDebounce(glucoseValue, severity)) {
//       return null;
//     }
//
//     // Update tracking
//     _lastGlucoseValue = glucoseValue;
//     _lastAlertTime = DateTime.now();
//
//     return severity;
//   }
//
//   /// Check if alert should be debounced
//   bool _shouldDebounce(double glucoseValue, AlertSeverity severity) {
//     if (_lastAlertTime == null || _lastGlucoseValue == null) {
//       return false;
//     }
//
//     // Allow immediate alerts for critical changes
//     if (severity == AlertSeverity.criticalLow || severity == AlertSeverity.criticalHigh) {
//       // Always alert for critical if it wasn't critical before
//       final lastSeverity = _ref.read(alertSettingsControllerProvider).getSeverity(_lastGlucoseValue!);
//       if (lastSeverity != AlertSeverity.criticalLow && lastSeverity != AlertSeverity.criticalHigh) {
//         return false;
//       }
//     }
//
//     // Debounce if less than 15 minutes since last alert
//     final timeSinceLastAlert = DateTime.now().difference(_lastAlertTime!);
//     return timeSinceLastAlert.inMinutes < 15;
//   }
//
//   /// Process a new glucose reading from health data
//   AlertSeverity? processHealthDataPoint(HealthDataPoint dataPoint) {
//     if (dataPoint.type != 'BLOOD_GLUCOSE') {
//       return null;
//     }
//
//     return checkGlucoseLevel(dataPoint.value);
//   }
//
//   /// Generate notification title for background notification
//   String getNotificationTitle(AlertSeverity severity, double glucoseValue) {
//     switch (severity) {
//       case AlertSeverity.criticalLow:
//         return '🚨 CRITICAL LOW - ${glucoseValue.toStringAsFixed(0)} mg/dL';
//       case AlertSeverity.low:
//         return '⚠️ Low Glucose - ${glucoseValue.toStringAsFixed(0)} mg/dL';
//       case AlertSeverity.high:
//         return '⚠️ High Glucose - ${glucoseValue.toStringAsFixed(0)} mg/dL';
//       case AlertSeverity.criticalHigh:
//         return '🚨 CRITICAL HIGH - ${glucoseValue.toStringAsFixed(0)} mg/dL';
//       case AlertSeverity.normal:
//         return 'Normal Glucose - ${glucoseValue.toStringAsFixed(0)} mg/dL';
//     }
//   }
//
//   /// Generate notification body for background notification
//   String getNotificationBody(AlertSeverity severity) {
//     switch (severity) {
//       case AlertSeverity.criticalLow:
//         return 'Your glucose is critically low. Take immediate action.';
//       case AlertSeverity.low:
//         return 'Your glucose is below target range. Consider a snack.';
//       case AlertSeverity.high:
//         return 'Your glucose is above target range. Check your insulin.';
//       case AlertSeverity.criticalHigh:
//         return 'Your glucose is critically high. Contact your doctor if needed.';
//       case AlertSeverity.normal:
//         return 'Your glucose level is within normal range.';
//     }
//   }
//
//   /// Reset monitoring state
//   void reset() {
//     _lastGlucoseValue = null;
//     _lastAlertTime = null;
//   }
// }
