import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import '../models/health_data_point.dart' as model;

/// Provider for HealthApiService
final healthApiServiceProvider = Provider<HealthApiService>((ref) {
  return HealthApiService();
});

/// Service for interacting with device health data (HealthKit/Google Fit)
class HealthApiService {
  final Health _health = Health();

  // Define the health data types we're interested in for diabetes management
  static const List<HealthDataType> _healthTypes = [
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.WORKOUT,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.WATER,
    HealthDataType.TOTAL_CALORIES_BURNED
  ];

  /// Request permissions for all health data types
  /// Returns true if permissions granted, false otherwise
  Future<bool> requestPermissions() async {
    try {
      final permissions = _healthTypes
          .map((type) => HealthDataAccess.READ_WRITE)
          .toList();

      print("🔐 Requesting permissions for ${_healthTypes.length} data types...");
      final granted = await _health.requestAuthorization(
        _healthTypes,
        permissions: permissions,
      );

      print("🔐 Permissions result: $granted");

      // Check individual permissions
      for (final type in _healthTypes) {
        final hasAccess = await _health.hasPermissions(
          [type],
          permissions: [HealthDataAccess.READ],
        );
        print("  ${type.name}: ${hasAccess == true ? '✅' : '❌'}");
      }

      return granted;
    } catch (e) {
      print('❌ Error requesting health permissions: $e');
      return false;
    }
  }

  /// Check if permissions have been granted
  Future<bool> hasPermissions() async {
    try {
      return await _health.hasPermissions(
        _healthTypes,
        permissions: _healthTypes
            .map((type) => HealthDataAccess.READ_WRITE)
            .toList(),
      ) ?? false;
    } catch (e) {
      print('Error checking health permissions: $e');
      return false;
    }
  }

  /// Fetch blood glucose data for a given time range
  Future<List<model.HealthDataPoint>> getBloodGlucoseData(
      DateTime startTime,
      DateTime endTime,
      ) async {
    try {
      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.BLOOD_GLUCOSE],
        startTime: startTime,
        endTime: endTime,
      );

      return _convertHealthDataPoints(healthData, 'BLOOD_GLUCOSE');
    } catch (e) {
      print('Error fetching blood glucose data: $e');
      return [];
    }
  }

  /// Fetch step count data for a given time range
  Future<List<model.HealthDataPoint>> getStepsData(
      DateTime startTime,
      DateTime endTime,
      ) async {
    try {
      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: startTime,
        endTime: endTime,
      );

      return _convertHealthDataPoints(healthData, 'STEPS');
    } catch (e) {
      print('Error fetching steps data: $e');
      return [];
    }
  }

  /// Fetch heart rate data for a given time range
  Future<List<model.HealthDataPoint>> getHeartRateData(
      DateTime startTime,
      DateTime endTime,
      ) async {
    try {
      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: startTime,
        endTime: endTime,
      );

      return _convertHealthDataPoints(healthData, 'HEART_RATE');
    } catch (e) {
      print('Error fetching heart rate data: $e');
      return [];
    }
  }

  /// Fetch weight data for a given time range
  Future<List<model.HealthDataPoint>> getWeightData(
      DateTime startTime,
      DateTime endTime,
      ) async {
    try {
      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WEIGHT],
        startTime: startTime,
        endTime: endTime,
      );

      return _convertHealthDataPoints(healthData, 'WEIGHT');
    } catch (e) {
      print('Error fetching weight data: $e');
      return [];
    }
  }

  /// Fetch all available health data for a given time range
  Future<List<model.HealthDataPoint>> getAllHealthData(
      DateTime startTime,
      DateTime endTime,
      ) async {
    try {
      final healthData = await _health.getHealthDataFromTypes(
        types: _healthTypes,
        startTime: startTime,
        endTime: endTime,
      );

      return _convertHealthDataPoints(healthData, null);
    } catch (e) {
      print('Error fetching all health data: $e');
      return [];
    }
  }

  // Add to HealthApiService class

  /// Write water intake (1 glass ≈ 250ml or 0.25L)
  Future<bool> writeWater(double liters, DateTime timestamp) async {
    try {
      return await _health.writeHealthData(
        value: liters,
        type: HealthDataType.WATER,
        startTime: timestamp,
        endTime: timestamp,
        unit: HealthDataUnit.LITER,
      );
    } catch (e) {
      print('Error writing water data: $e');
      return false;
    }
  }

  /// Fetch total water intake for the day in Liters
  Future<double> getTotalWaterLiters(DateTime startTime, DateTime endTime) async {
    try {
      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WATER],
        startTime: startTime,
        endTime: endTime,
      );

      double totalLiters = 0.0;
      for (var point in healthData) {
        final value = _extractNumericValue(point);
        if (value != null) totalLiters += value;
      }
      return totalLiters;
    } catch (e) {
      print('Error fetching water: $e');
      return 0.0;
    }
  }

  /// Write blood glucose data to health store
  Future<bool> writeBloodGlucose(double value, DateTime timestamp) async {
    try {
      return await _health.writeHealthData(
        value: value,
        type: HealthDataType.BLOOD_GLUCOSE,
        startTime: timestamp,
        endTime: timestamp,
        unit: HealthDataUnit.MILLIGRAM_PER_DECILITER,
      );
    } catch (e) {
      print('Error writing blood glucose data: $e');
      return false;
    }
  }

  /// Write weight data to health store
  Future<bool> writeWeight(double value, DateTime timestamp) async {
    try {
      return await _health.writeHealthData(
        value: value,
        type: HealthDataType.WEIGHT,
        startTime: timestamp,
        endTime: timestamp,
        unit: HealthDataUnit.KILOGRAM,
      );
    } catch (e) {
      print('Error writing weight data: $e');
      return false;
    }
  }

  /// Write steps data to health store
  Future<bool> writeSteps(int steps, DateTime startTime, DateTime endTime) async {
    try {
      return await _health.writeHealthData(
        value: steps.toDouble(),
        type: HealthDataType.STEPS,
        startTime: startTime,
        endTime: endTime,
        unit: HealthDataUnit.COUNT,
      );
    } catch (e) {
      print('Error writing steps data: $e');
      return false;
    }
  }

  /// Get aggregate step count for a given day
  Future<int?> getTotalStepsForDay(DateTime day) async {
    try {
      final startOfDay = DateTime(day.year, day.month, day.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final steps = await _health.getTotalStepsInInterval(startOfDay, endOfDay);
      return steps;
    } catch (e) {
      print('Error getting total steps: $e');
      return null;
    }
  }

  /// Convert Health package data points to our model
  List<model.HealthDataPoint> _convertHealthDataPoints(
      List<HealthDataPoint> healthData,
      String? filterType,
      ) {
    return healthData
        .where((point) => filterType == null || point.type.name == filterType)
        .map((point) {
      // Extract numeric value from the health data point
      final value = _extractNumericValue(point);
      if (value == null) return null;

      return model.HealthDataPoint(
        type: point.type.name,
        value: value,
        unit: point.unitString,
        timestamp: point.dateFrom,
        source: point.sourceName,
      );
    })
        .whereType<model.HealthDataPoint>()
        .toList();
  }

  /// Extract numeric value from HealthDataPoint
  double? _extractNumericValue(HealthDataPoint point) {
    try {
      final value = point.value;
      if (value is NumericHealthValue) {
        return value.numericValue.toDouble();
      }
      return null;
    } catch (e) {
      print('Error extracting numeric value: $e');
      return null;
    }
  }

  /// Get available data types on the current platform
  Future<List<HealthDataType>> getAvailableDataTypes() async {
    final available = <HealthDataType>[];

    for (final type in _healthTypes) {
      try {
        // Try to fetch a small amount of data to test availability
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));

        await _health.getHealthDataFromTypes(
          types: [type],
          startTime: yesterday,
          endTime: now,
        );

        available.add(type);
      } catch (e) {
        // Type not available on this platform
        continue;
      }
    }

    return available;
  }

  /// Fetch sleep data and return total duration in minutes
  /// Uses SLEEP_SESSION for Health Connect compatibility
  /// Deduplicates entries with same time range from different sources
  /// Prefer the original APP !! (e.g Sleep as Android) over google fit
  Future<double> getTotalSleepMinutes(DateTime startTime, DateTime endTime) async {
    try {
      print('😴 Querying sleep from $startTime to $endTime');
      print('😴 Local timezone: ${DateTime.now().timeZoneName}');

      // Convert to local time explicitly
      final localStart = startTime.toLocal();
      final localEnd = endTime.toLocal();

      print('😴 Local time range: $localStart to $localEnd');

      // Try both SLEEP_SESSION (Health Connect) and SLEEP_ASLEEP (older)
      final sleepSession = await _health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_SESSION],
        startTime: localStart,
        endTime: localEnd,
      );

      final sleepAsleep = await _health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_ASLEEP],
        startTime: localStart,
        endTime: localEnd,
      );

      final healthData = [...sleepSession, ...sleepAsleep];

      print('😴 Raw sleep data points: ${healthData.length} (${sleepSession.length} sessions, ${sleepAsleep.length} asleep)');

      if (healthData.isEmpty) {
        print('😴 ⚠️ No sleep data returned. Checking permissions...');
        final hasSessionPermission = await _health.hasPermissions(
          [HealthDataType.SLEEP_SESSION],
          permissions: [HealthDataAccess.READ],
        );
        final hasAsleepPermission = await _health.hasPermissions(
          [HealthDataType.SLEEP_ASLEEP],
          permissions: [HealthDataAccess.READ],
        );
        print('😴 Sleep session permission: $hasSessionPermission');
        print('😴 Sleep asleep permission: $hasAsleepPermission');
      }

      // Deduplicate entries with same start/end times
      final uniqueSessions = <String, HealthDataPoint>{};

      for (final point in healthData) {
        // Create a unique key based on start and end times (rounded to nearest minute)
        final startKey = point.dateFrom.millisecondsSinceEpoch ~/ 60000;
        final endKey = point.dateTo.millisecondsSinceEpoch ~/ 60000;
        final key = '$startKey-$endKey';

        // Only keep one entry per unique time range
        // Prefer non-Google Fit sources (original apps like Sleep as Android)
        if (!uniqueSessions.containsKey(key) ||
            !point.sourceName.contains('fitness')) {
          uniqueSessions[key] = point;
        }
      }

      print('😴 Unique sleep sessions after deduplication: ${uniqueSessions.length}');

      double totalMinutes = 0.0;

      for (final point in uniqueSessions.values) {
        // Calculate duration from dateFrom and dateTo
        final duration = point.dateTo.difference(point.dateFrom);
        final minutes = duration.inMinutes.toDouble();

        print('  Sleep session: ${point.dateFrom.toLocal()} to ${point.dateTo.toLocal()} = $minutes min (source: ${point.sourceName}, type: ${point.type.name})');
        totalMinutes += minutes;
      }

      print('😴 Total sleep minutes calculated: $totalMinutes');
      return totalMinutes;
    } catch (e) {
      print('❌ Error fetching sleep data: $e');
      print('Stack trace: ${StackTrace.current}');
      return 0.0;
    }
  }

  /// Fetch sleep data (DEPRECATED - use getTotalSleepMinutes instead)
  /// This returns individual sleep sessions as data points
  Future<List<model.HealthDataPoint>> getSleepData(
      DateTime startTime,
      DateTime endTime,
      ) async {
    try {
      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_ASLEEP],
        startTime: startTime,
        endTime: endTime,
      );

      // For sleep, we need to calculate duration from intervals
      return healthData.map((point) {
        final duration = point.dateTo.difference(point.dateFrom);
        final minutes = duration.inMinutes.toDouble();

        return model.HealthDataPoint(
          type: point.type.name,
          value: minutes,
          unit: 'minutes',
          timestamp: point.dateFrom,
          source: point.sourceName,
        );
      }).toList();
    } catch (e) {
      print('Error fetching sleep data: $e');
      return [];
    }
  }

  /// Fetch active energy burned (Calories) with deduplication
  Future<List<model.HealthDataPoint>> getTotalEnergyData(
      DateTime startTime,
      DateTime endTime,
      ) async {
    try {
      print('🔥 Querying calories from $startTime to $endTime');

      // Try both ACTIVE_ENERGY_BURNED and TOTAL_CALORIES_BURNED
      final activeEnergy = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: startTime.toLocal(),
        endTime: endTime.toLocal(),
      );

      final totalCalories = await _health.getHealthDataFromTypes(
        types: [HealthDataType.TOTAL_CALORIES_BURNED],
        startTime: startTime.toLocal(),
        endTime: endTime.toLocal(),
      );

      print('🔥 Active energy points: ${activeEnergy.length}');
      print('🔥 Total calories points: ${totalCalories.length}');

      if (activeEnergy.isEmpty && totalCalories.isEmpty) {
        print('🔥 ⚠️ No calorie data returned. Checking permissions...');
        final hasActivePermission = await _health.hasPermissions(
          [HealthDataType.ACTIVE_ENERGY_BURNED],
          permissions: [HealthDataAccess.READ],
        );
        final hasTotalPermission = await _health.hasPermissions(
          [HealthDataType.TOTAL_CALORIES_BURNED],
          permissions: [HealthDataAccess.READ],
        );
        print('🔥 Active energy permission: $hasActivePermission');
        print('🔥 Total calories permission: $hasTotalPermission');
      }

      // Combine and deduplicate
      final allCalories = [...activeEnergy, ...totalCalories];
      final uniqueCalories = <String, HealthDataPoint>{};

      for (final point in allCalories) {
        // Create unique key based on timestamp and value (rounded)
        final timeKey = point.dateFrom.millisecondsSinceEpoch ~/ 60000;
        final value = _extractNumericValue(point) ?? 0;
        final valueKey = (value * 10).round(); // Round to 1 decimal
        final key = '$timeKey-$valueKey-${point.type.name}';

        // Prefer non-Google Fit sources
        if (!uniqueCalories.containsKey(key) ||
            !point.sourceName.contains('fitness')) {
          uniqueCalories[key] = point;
        }
      }

      print('🔥 Unique calorie entries after deduplication: ${uniqueCalories.length}');

      for (final point in uniqueCalories.values) {
        print('  Calorie point: ${point.type.name} = ${_extractNumericValue(point)} at ${point.dateFrom.toLocal()} (source: ${point.sourceName})');
      }

      return _convertHealthDataPoints(uniqueCalories.values.toList(), null);
    } catch (e) {
      print('❌ Error fetching calorie data: $e');
      return [];
    }
  }
}