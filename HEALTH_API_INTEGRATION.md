# Health API Integration

## Overview
The Health API integration allows the diabetes management app to sync with native health platforms:
- **iOS**: Apple HealthKit
- **Android**: Google Health Connect (Android 14+) and Google Fit (older versions)

## Files Created

### 1. Service Layer
- **`lib/services/health_api_service.dart`**: Core service for interacting with device health data
  - Request/check permissions
  - Read health data (blood glucose, steps, heart rate, weight, etc.)
  - Write health data back to the health store

### 2. Models
- **`lib/models/health_data_point.dart`**: Model representing a single health data point

### 3. Controller
- **`lib/patient/logging/health_data_controller.dart`**: Riverpod controller for managing health data state
  - Provides easy-to-use methods for UI components
  - Handles AsyncValue state management

### 4. Example Widget
- **`lib/patient/logging/health_data_integration_example.dart`**: Example UI showing health API usage

## Configuration

### iOS (Info.plist)
Added required permission strings to `/ios/Runner/Info.plist`:
- `NSHealthShareUsageDescription`: Read health data permission
- `NSHealthUpdateUsageDescription`: Write health data permission

### Android (AndroidManifest.xml)
Added permissions to `/android/app/src/main/AndroidManifest.xml`:
- Health Connect permissions (Android 14+)
- Google Fit permissions (older versions)
- Activity recognition permission

## Usage

### 1. Request Permissions

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diabetes_management_system/patient/logging/health_data_controller.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(healthDataControllerProvider.notifier);
    
    return ElevatedButton(
      onPressed: () async {
        final granted = await controller.requestPermissions();
        if (granted) {
          // Permissions granted, proceed with health data access
        }
      },
      child: Text('Request Health Permissions'),
    );
  }
}
```

### 2. Fetch Blood Glucose Data

```dart
final controller = ref.read(healthDataControllerProvider.notifier);
final glucoseData = await controller.fetchRecentBloodGlucose();

for (final reading in glucoseData) {
  print('${reading.value} ${reading.unit} at ${reading.timestamp}');
}
```

### 3. Fetch Today's Steps

```dart
final controller = ref.read(healthDataControllerProvider.notifier);
final steps = await controller.fetchTodaySteps();
print('Steps today: $steps');
```

### 4. Save Blood Glucose to Health Store

```dart
final controller = ref.read(healthDataControllerProvider.notifier);
final success = await controller.saveBloodGlucose(
  120.0, // mg/dL
  DateTime.now(),
);
```

### 5. Fetch All Health Data

```dart
final controller = ref.read(healthDataControllerProvider.notifier);
await controller.fetchTodayHealthData();

// Watch the state
final healthDataState = ref.watch(healthDataControllerProvider);

healthDataState.when(
  data: (dataPoints) {
    // Display health data
    for (final point in dataPoints) {
      print('${point.type}: ${point.value} ${point.unit}');
    }
  },
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);
```

## Supported Health Data Types

The implementation supports the following health metrics:
- Blood Glucose (mg/dL)
- Steps (count)
- Heart Rate (bpm)
- Blood Pressure (systolic/diastolic)
- Weight (kg)
- Height (cm)
- Active Energy Burned (kcal)
- Workout/Exercise data
- Sleep data
- Water/Hydration (ml)

## Integration with Existing Screens

### In Logging Screens
You can integrate health data import in your logging screens:

```dart
// In your food/biometrics logging screen
FloatingActionButton(
  onPressed: () async {
    final controller = ref.read(healthDataControllerProvider.notifier);
    final glucoseData = await controller.fetchRecentBloodGlucose();
    
    // Use the fetched data to pre-fill forms
    if (glucoseData.isNotEmpty) {
      final latest = glucoseData.last;
      // Pre-fill your glucose input field with latest.value
    }
  },
  child: Icon(Icons.sync),
  tooltip: 'Import from Health',
);
```

### In Dashboard
Show health metrics synced from the device:

```dart
class DashboardHealthWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(healthDataControllerProvider.notifier);
    
    useEffect(() {
      controller.fetchTodayHealthData();
      return null;
    }, []);
    
    final healthData = ref.watch(healthDataControllerProvider);
    
    return healthData.when(
      data: (points) => HealthMetricsDisplay(points: points),
      loading: () => CircularProgressIndicator(),
      error: (e, _) => Text('Error loading health data'),
    );
  }
}
```

## Backend Sync Strategy

To sync health data with your backend:

1. Fetch health data using the controller
2. Transform to your backend DTOs
3. Send via existing repositories

Example:

```dart
// Fetch from Health API
final glucoseData = await healthController.fetchRecentBloodGlucose();

// Transform and send to backend
final logRepo = ref.read(logRepositoryProvider);
for (final reading in glucoseData) {
  await logRepo.createBiometricsLog(
    patientId,
    BiometricsLogRequest(
      glucoseLevel: reading.value,
      timestamp: reading.timestamp,
      source: 'HEALTH_KIT', // or 'GOOGLE_FIT'
    ),
  );
}
```

## Testing

### iOS Simulator
The iOS Simulator includes a Health app where you can add test data:
1. Open Health app in simulator
2. Add sample data (blood glucose, steps, etc.)
3. Run your app and fetch the data

### Android Emulator
For Android 14+, you need to install Health Connect:
1. Install Health Connect APK on emulator
2. Add sample data
3. Grant permissions to your app

## Important Notes

1. **Privacy**: Always explain to users why you need health data access
2. **Permissions**: Request permissions at the right time (not on app startup)
3. **Background Sync**: For continuous monitoring, consider implementing background fetch
4. **Data Validation**: Always validate health data before using it
5. **Platform Differences**: iOS and Android have different health data ecosystems

## Next Steps

1. Integrate health data import buttons in logging screens
2. Add automatic background sync for glucose readings
3. Show health metrics in dashboard
4. Sync health data with backend periodically
5. Add settings to enable/disable health sync

## Dependencies

- `health: ^13.2.1` - Flutter plugin for accessing health data
- `flutter_riverpod: ^3.1.0` - State management

## Troubleshooting

### iOS
- Ensure Info.plist has usage descriptions
- Check that device/simulator has Health app enabled
- Verify app has requested permissions

### Android
- For Android 14+, ensure Health Connect is installed
- Check AndroidManifest.xml has all required permissions
- Verify runtime permissions are granted
