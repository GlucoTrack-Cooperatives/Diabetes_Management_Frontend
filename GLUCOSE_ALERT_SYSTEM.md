# Glucose Alert System - Implementation Guide

## Overview
Complete glucose monitoring and alert system with user-configurable thresholds, in-app alerts, and background notifications.

## Features Implemented

### ✅ User-Configurable Settings
- **4 Alert Thresholds:**
  - Critical Low (default: 54 mg/dL)
  - Low (default: 70 mg/dL)
  - High (default: 180 mg/dL)
  - Critical High (default: 250 mg/dL)

- **Alert Controls:**
  - Enable/disable notifications
  - Enable/disable alert sounds
  - High threshold alerts are mandatory (cannot be disabled)

### ✅ Two Alert Types

#### 1. In-App Alert Dialog
- Full-screen modal with severity indicator
- Large glucose value display
- Color-coded by severity (red for critical, orange for moderate, green for normal)
- Actionable advice specific to each alert type
- "Understood" and "View Details" buttons

#### 2. Background Notifications (Ready for Implementation)
- System notifications with banner
- Title shows severity and current glucose value
- Color-coded notifications
- Sound can be toggled
- Works even when app is in background

## Files Created

### Models
- **`lib/models/glucose_alert_settings.dart`**
  - Settings model with thresholds and preferences
  - AlertSeverity enum with 5 levels
  - Built-in advice for each severity level
  - Color codes for visual indicators

### Repositories
- **`lib/repositories/alert_settings_repository.dart`**
  - Save/load settings using secure storage
  - Persists user preferences

### Controllers
- **`lib/patient/settings/alert_settings_controller.dart`**
  - Manage alert settings state
  - Determine severity based on glucose value
  - Decide when alerts should trigger

### Services
- **`lib/services/glucose_monitoring_service.dart`**
  - Monitor glucose levels from Health API
  - Trigger alerts based on settings
  - Debounce alerts (15-minute minimum between same type)
  - Generate notification titles and bodies

### UI Components
- **`lib/patient/settings/alert_settings_screen.dart`**
  - Full settings screen for configuring thresholds
  - Live preview of alert ranges
  - Validation of threshold values
  - Toggle switches for sound and notifications

- **`lib/widgets/glucose_alert_dialog.dart`**
  - Beautiful in-app alert dialog
  - Gradient background with severity colors
  - Large glucose display
  - Contextual advice section
  - Action buttons

- **`lib/patient/logging/glucose_monitoring_example.dart`**
  - Example integration showing complete workflow
  - Fetch glucose from Health API
  - Display current glucose with color coding
  - Show threshold settings
  - Trigger alerts when needed

## Alert Logic

### Severity Determination
```dart
if (glucose <= criticalLowThreshold) → CRITICAL LOW
else if (glucose < lowThreshold) → LOW
else if (glucose >= criticalHighThreshold) → CRITICAL HIGH
else if (glucose > highThreshold) → HIGH
else → NORMAL
```

### Alert Triggering Rules
1. Normal glucose levels don't trigger alerts
2. Alerts are debounced (15-minute minimum between alerts)
3. Critical alerts bypass debounce if severity level changes
4. High/Critical High alerts always work (mandatory protection)
5. Other alerts respect notification settings

### Color Coding
- **Critical (Red #B71C1C)**: Critical Low / Critical High
- **Warning (Orange #FF9800)**: Low / High
- **Normal (Green #4CAF50)**: Within range

## Usage Examples

### 1. Configure Alert Settings
```dart
// Navigate to settings screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AlertSettingsScreen(),
  ),
);
```

### 2. Monitor Glucose and Show Alerts
```dart
final healthService = ref.read(healthApiServiceProvider);
final monitoringService = ref.read(glucoseMonitoringServiceProvider);

// Fetch latest glucose
final glucoseData = await healthService.getBloodGlucoseData(
  DateTime.now().subtract(Duration(hours: 24)),
  DateTime.now(),
);

if (glucoseData.isNotEmpty) {
  final latest = glucoseData.last;
  
  // Check if alert needed
  final severity = monitoringService.processHealthDataPoint(latest);
  
  if (severity != null) {
    // Show in-app alert
    await GlucoseAlertDialog.show(
      context,
      glucoseValue: latest.value,
      severity: severity,
    );
  }
}
```

### 3. Load Settings on App Start
```dart
@override
void initState() {
  super.initState();
  // Load alert settings
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(alertSettingsControllerProvider).loadSettings();
  });
}
```

## Integration with Existing Code

### Add to Navigation Routes
```dart
// In your main navigation
'/alert-settings': (context) => const AlertSettingsScreen(),
'/glucose-monitoring': (context) => const GlucoseMonitoringExample(),
```

### Add Settings Link in Patient Settings
```dart
ListTile(
  leading: const Icon(Icons.notifications_active),
  title: const Text('Glucose Alerts'),
  subtitle: const Text('Configure alert thresholds'),
  onTap: () {
    Navigator.pushNamed(context, '/alert-settings');
  },
)
```

### Integrate with Dashboard
```dart
// In your dashboard, periodically check glucose
Timer.periodic(Duration(minutes: 5), (timer) async {
  final healthService = ref.read(healthApiServiceProvider);
  final monitoringService = ref.read(glucoseMonitoringServiceProvider);
  
  // Check latest glucose
  final now = DateTime.now();
  final fiveMinAgo = now.subtract(Duration(minutes: 5));
  final readings = await healthService.getBloodGlucoseData(fiveMinAgo, now);
  
  if (readings.isNotEmpty) {
    final severity = monitoringService.processHealthDataPoint(readings.last);
    if (severity != null && mounted) {
      GlucoseAlertDialog.show(context, 
        glucoseValue: readings.last.value,
        severity: severity,
      );
    }
  }
});
```

## Background Notifications Setup

To enable background notifications, add these dependencies to `pubspec.yaml`:

```yaml
dependencies:
  flutter_local_notifications: ^17.0.0
  workmanager: ^0.5.2  # For background tasks
```

### Initialize Notifications
```dart
// In main.dart or initialization code
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings();

const InitializationSettings initializationSettings = InitializationSettings(
  android: initializationSettingsAndroid,
  iOS: initializationSettingsIOS,
);

await flutterLocalNotificationsPlugin.initialize(initializationSettings);
```

### Trigger Notification
```dart
void _showNotification(double glucose, AlertSeverity severity) async {
  final settings = ref.read(alertSettingsProvider);
  final monitoringService = ref.read(glucoseMonitoringServiceProvider);
  
  await flutterLocalNotificationsPlugin.show(
    0,
    monitoringService.getNotificationTitle(severity, glucose),
    monitoringService.getNotificationBody(severity),
    NotificationDetails(
      android: AndroidNotificationDetails(
        'glucose_alerts',
        'Glucose Alerts',
        channelDescription: 'Alerts for blood glucose levels',
        importance: Importance.max,
        priority: Priority.high,
        color: _parseColor(severity.colorHex),
        playSound: settings.soundEnabled,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: settings.soundEnabled,
      ),
    ),
  );
}
```

## Alert Advice Messages

### Critical Low (≤54 mg/dL)
*"Your glucose is critically low at X mg/dL. Consume 15-20g of fast-acting carbs immediately and recheck in 15 minutes. If symptoms persist, seek medical help."*

### Low (<70 mg/dL)
*"Your glucose is low at X mg/dL. Consume 15g of fast-acting carbs (juice, glucose tablets) and recheck in 15 minutes."*

### High (>180 mg/dL)
*"Your glucose is high at X mg/dL. Check your insulin dosage, stay hydrated, and consider light exercise. Monitor closely."*

### Critical High (≥250 mg/dL)
*"Your glucose is critically high at X mg/dL. Check for ketones, take corrective insulin if advised, stay hydrated, and contact your healthcare provider if it doesn't improve."*

## Testing

### Test Alert Display
```dart
// Manually trigger alert for testing
GlucoseAlertDialog.show(
  context,
  glucoseValue: 55.0,  // Test critical low
  severity: AlertSeverity.criticalLow,
);
```

### Test Different Severities
```dart
// Test all severities
final testCases = [
  (50.0, AlertSeverity.criticalLow),
  (65.0, AlertSeverity.low),
  (200.0, AlertSeverity.high),
  (280.0, AlertSeverity.criticalHigh),
];

for (final test in testCases) {
  await GlucoseAlertDialog.show(
    context,
    glucoseValue: test.$1,
    severity: test.$2,
  );
  await Future.delayed(Duration(seconds: 2));
}
```

## Security & Safety Features

1. **High Alert Mandatory**: Cannot be fully disabled to protect user safety
2. **Persistent Storage**: Settings saved in secure storage
3. **Debounce Logic**: Prevents alert fatigue
4. **Critical Escalation**: Critical alerts bypass debounce
5. **Validation**: Threshold values validated before saving

## Next Steps

1. ✅ Complete - Alert settings UI
2. ✅ Complete - In-app alert dialog
3. ✅ Complete - Monitoring service
4. 🔄 TODO - Implement background notifications
5. 🔄 TODO - Add background glucose monitoring
6. 🔄 TODO - Sync alerts with backend
7. 🔄 TODO - Alert history/log
8. 🔄 TODO - Customize alert sounds

## Notes

- Settings are persisted in secure storage
- High alerts are always enabled for safety
- 15-minute debounce prevents alert spam
- Critical alerts can bypass debounce
- Color-coded for quick severity recognition
- Contextual advice helps users respond appropriately

---

**Status**: ✅ Core alert system ready  
**Next**: Implement background notifications with flutter_local_notifications
