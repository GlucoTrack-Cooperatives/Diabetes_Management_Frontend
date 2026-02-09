import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import '../models/health_data_point.dart' as model;
import 'dart:io' show Platform;

/// Provider for HealthApiService
final healthApiServiceProvider = Provider<HealthApiService>((ref) {
  return HealthApiService();
});

/// Service for interacting with device health data (HealthKit/Google Fit)
class HealthApiService {
  final Health _health = Health();
  bool _didTestBloodGlucoseWrite = false;

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
    HealthDataType.SLEEP_IN_BED,   // iOS only
    HealthDataType.WATER,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.BASAL_ENERGY_BURNED, // iOS only
  ];

  List<HealthDataType> get _platformHealthTypes {
    if (Platform.isIOS) {
      return [
        HealthDataType.BLOOD_GLUCOSE,
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
        HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
        HealthDataType.WEIGHT,
        HealthDataType.HEIGHT,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.BASAL_ENERGY_BURNED,
        HealthDataType.WORKOUT,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_AWAKE,
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_REM,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.WATER,
      ];
    }

    if (Platform.isAndroid) {
      return [
        HealthDataType.BLOOD_GLUCOSE,
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
        HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
        HealthDataType.WEIGHT,
        HealthDataType.HEIGHT,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.TOTAL_CALORIES_BURNED,
        HealthDataType.WORKOUT,
        HealthDataType.SLEEP_SESSION,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.WATER,
      ];
    }

    return _healthTypes;
  }

  /// Request permissions for all health data types
  /// Returns true if permissions granted, false otherwise
  Future<bool> requestPermissions() async {
    try {
      // Configure HealthKit first
      print("🔐 Configuring HealthKit...");
      await _health.configure();
      
      final permissions = _platformHealthTypes
          .map((type) => HealthDataAccess.READ_WRITE)
          .toList();

      print("🔐 Requesting permissions for ${_platformHealthTypes.length} data types...");
      final granted = await _health.requestAuthorization(
        _platformHealthTypes,
        permissions: permissions,
      );

      print("🔐 Permissions result: $granted");

      // Check individual permissions
      for (final type in _platformHealthTypes) {
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
        _platformHealthTypes,
        permissions: _platformHealthTypes
            .map((type) => HealthDataAccess.READ_WRITE)
            .toList(),
      ) ?? false;
    } catch (e) {
      print('Error checking health permissions: $e');
      return false;
    }
  }

  Future<bool> hasBloodGlucoseWritePermission() async {
    try {
      return await _health.hasPermissions(
        [HealthDataType.BLOOD_GLUCOSE],
        permissions: [HealthDataAccess.WRITE],
      ) ?? false;
    } catch (e) {
      print('Error checking blood glucose write permission: $e');
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
      print('⚖️ Querying weight data from $startTime to $endTime');
      final healthData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WEIGHT],
        startTime: startTime.toLocal(),
        endTime: endTime.toLocal(),
      );

      print('⚖️ Raw weight data points: ${healthData.length}');
      for (var point in healthData) {
        final raw = _extractNumericValue(point);
        print('  Raw: $raw ${point.unitString} from ${point.sourceName}');
      }

      return _convertHealthDataPoints(healthData, 'WEIGHT');
    } catch (e, stackTrace) {
      print('❌ Error fetching weight data: $e');
      print('Stack trace: $stackTrace');
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
        types: _platformHealthTypes,
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
      final endTime = _endTimeFromInstant(timestamp);
      return await _health.writeHealthData(
        value: liters,
        type: HealthDataType.WATER,
        startTime: timestamp,
        endTime: endTime,
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
      final endTime = _endTimeFromInstant(timestamp);
      return await _health.writeHealthData(
        value: value,
        type: HealthDataType.BLOOD_GLUCOSE,
        startTime: timestamp,
        endTime: endTime,
        unit: HealthDataUnit.MILLIGRAM_PER_DECILITER,
      );
    } catch (e) {
      print('Error writing blood glucose data: $e');
      return false;
    }
  }

  Future<void> debugWriteAndReadBloodGlucoseOnce() async {
    if (_didTestBloodGlucoseWrite || !Platform.isAndroid) return;
    _didTestBloodGlucoseWrite = true;

    try {
      final now = DateTime.now();
      const testValue = 123.0;
      print('🧪 BG write test: writing $testValue mg/dL at $now');
      final writeOk = await writeBloodGlucose(testValue, now);
      print('🧪 BG write test: write result = $writeOk');

      final readStart = now.subtract(const Duration(minutes: 15)).toLocal();
      final readEnd = now.add(const Duration(minutes: 1)).toLocal();
      final results = await _health.getHealthDataFromTypes(
        types: [HealthDataType.BLOOD_GLUCOSE],
        startTime: readStart,
        endTime: readEnd,
      );

      print('🧪 BG write test: readback count = ${results.length}');
      for (final p in results) {
        final rawValue = _extractNumericValue(p);
        print('  source=${p.sourceName}, value=$rawValue ${p.unitString}, at=${p.dateFrom.toLocal()}');
      }
    } catch (e) {
      print('🧪 BG write test error: $e');
    }
  }

  /// Write weight data to health store
  Future<bool> writeWeight(double value, DateTime timestamp) async {
    try {
      final endTime = _endTimeFromInstant(timestamp);
      return await _health.writeHealthData(
        value: value,
        type: HealthDataType.WEIGHT,
        startTime: timestamp,
        endTime: endTime,
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
      final rawValue = _extractNumericValue(point);
      if (rawValue == null) return null;
      final value = _normalizeValue(point, rawValue);

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
      final parsed = double.tryParse(value.toString());
      if (parsed != null) return parsed;
      return null;
    } catch (e) {
      print('Error extracting numeric value: $e');
      return null;
    }
  }

  DateTime _endTimeFromInstant(DateTime timestamp) {
    // Health Connect requires endTime > startTime for interval-based records.
    return timestamp.add(const Duration(seconds: 1));
  }

  double _normalizeValue(HealthDataPoint point, double value) {
    final unit = point.unitString.toLowerCase();

    if (point.type == HealthDataType.WEIGHT) {
      if (unit.contains('lb') || unit.contains('pound')) {
        return value * 0.45359237; // lb -> kg
      }
      // Only convert grams to kg, not kilograms (which already contains "gram")
      if (unit == 'g' || (unit.contains('gram') && !unit.contains('kg') && !unit.contains('kilo'))) {
        return value / 1000.0; // g -> kg
      }
    }

    if (point.type == HealthDataType.ACTIVE_ENERGY_BURNED ||
        point.type == HealthDataType.TOTAL_CALORIES_BURNED ||
        point.type == HealthDataType.BASAL_ENERGY_BURNED) {
      if (unit.contains('kj')) {
        return value * 0.239005736; // kJ -> kcal
      }
      if (unit.contains('j') && !unit.contains('kj')) {
        return value * 0.000239005736; // J -> kcal
      }
    }

    return value;
  }

  double _sumMergedSleepMinutes(List<HealthDataPoint> points) {
    if (points.isEmpty) return 0.0;

    points.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));

    DateTime currentStart = points.first.dateFrom;
    DateTime currentEnd = points.first.dateTo;
    double totalMinutes = 0.0;

    for (final point in points.skip(1)) {
      if (!point.dateFrom.isAfter(currentEnd)) {
        if (point.dateTo.isAfter(currentEnd)) {
          currentEnd = point.dateTo;
        }
      } else {
        totalMinutes += currentEnd.difference(currentStart).inMinutes.toDouble();
        currentStart = point.dateFrom;
        currentEnd = point.dateTo;
      }
    }

    totalMinutes += currentEnd.difference(currentStart).inMinutes.toDouble();
    return totalMinutes;
  }

  /// Get available data types on the current platform
  Future<List<HealthDataType>> getAvailableDataTypes() async {
    final available = <HealthDataType>[];

    for (final type in _platformHealthTypes) {
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
  /// Fetch sleep data and return total duration in minutes
  /// Uses platform-specific sleep types (iOS: SLEEP_IN_BED, Android: SLEEP_SESSION)
  Future<double> getTotalSleepMinutes(DateTime startTime, DateTime endTime) async {
    try {
      print('😴 ========== SLEEP QUERY DEBUG ==========');
      print('😴 Input times: $startTime to $endTime');
      print('😴 Platform: ${Platform.isIOS ? 'iOS' : Platform.isAndroid ? 'Android' : 'Other'}');

      // Check permissions explicitly for sleep
      if (Platform.isIOS) {
        final hasSleepInBed = await _health.hasPermissions([HealthDataType.SLEEP_IN_BED], permissions: [HealthDataAccess.READ]);
        final hasSleepAsleep = await _health.hasPermissions([HealthDataType.SLEEP_ASLEEP], permissions: [HealthDataAccess.READ]);
        print('😴 Sleep permissions: SLEEP_IN_BED=$hasSleepInBed, SLEEP_ASLEEP=$hasSleepAsleep');
        print('😴 Note: null permissions may still work - iOS health package bug');
      }

      final localStart = startTime.toLocal();
      final localEnd = endTime.toLocal();
      
      print('😴 Local times: $localStart to $localEnd');
      print('😴 UTC times: ${startTime.toUtc()} to ${endTime.toUtc()}');

      List<HealthDataPoint> healthData = [];

      if (Platform.isIOS) {
        print('😴 ========== EXHAUSTIVE SLEEP QUERY ==========');
        print('😴 Time range: $localStart to $localEnd');
        
        // Try all possible iOS sleep types
        final sleepTypesToQuery = <(HealthDataType, String)>[
          (HealthDataType.SLEEP_IN_BED, 'SLEEP_IN_BED'),
          (HealthDataType.SLEEP_ASLEEP, 'SLEEP_ASLEEP'),
          (HealthDataType.SLEEP_AWAKE, 'SLEEP_AWAKE'),
          (HealthDataType.SLEEP_DEEP, 'SLEEP_DEEP'),
          (HealthDataType.SLEEP_REM, 'SLEEP_REM'),
          (HealthDataType.SLEEP_LIGHT, 'SLEEP_LIGHT (asleepCore in Apple Health)'),
        ];
        
        final allResults = <HealthDataPoint>[];
        
        for (final (type, name) in sleepTypesToQuery) {
          try {
            print('😴 Querying $name...');
            final results = await _health.getHealthDataFromTypes(
              types: [type],
              startTime: localStart,
              endTime: localEnd,
            );
            
            print('😴 $name: ${results.length} entries');
            
            if (results.isNotEmpty) {
              for (var p in results) {
                final mins = p.dateTo.difference(p.dateFrom).inMinutes;
                final hours = mins / 60.0;
                print('  $hours h ($mins min): ${p.dateFrom.hour}:${p.dateFrom.minute.toString().padLeft(2, '0')} to ${p.dateTo.hour}:${p.dateTo.minute.toString().padLeft(2, '0')}');
              }
              allResults.addAll(results);
            }
          } catch (e) {
            print('😴 $name error: $e');
          }
        }
        
        print('😴 ========== SUMMARY ==========');
        print('😴 Total sleep entries found: ${allResults.length}');
        
        final totalMins = allResults.fold<int>(0, (sum, p) => sum + p.dateTo.difference(p.dateFrom).inMinutes);
        final totalHours = totalMins / 60.0;
        print('😴 TOTAL DURATION: ${totalHours.toStringAsFixed(2)} hours ($totalMins minutes)');
        
        // Prefer SLEEP_LIGHT + SLEEP_DEEP + SLEEP_REM combined, otherwise fall back to SLEEP_IN_BED
        final lightDeepRem = allResults.where((p) => 
          p.type == HealthDataType.SLEEP_LIGHT || 
          p.type == HealthDataType.SLEEP_DEEP || 
          p.type == HealthDataType.SLEEP_REM
        ).toList();
        if (lightDeepRem.isNotEmpty) {
          print('😴 Using SLEEP_LIGHT + SLEEP_DEEP + SLEEP_REM combined (${lightDeepRem.length} entries)');
          healthData = lightDeepRem;
        } else {
          final inBed = allResults.where((p) => p.type == HealthDataType.SLEEP_IN_BED).toList();
          if (inBed.isNotEmpty) {
            print('😴 Using SLEEP_IN_BED fallback (${inBed.length} entries)');
            healthData = inBed;
          } else {
            print('😴 Using all available sleep data (${allResults.length} entries)');
            healthData = allResults;
          }
        }
      } else if (Platform.isAndroid) {
        // Android: Prefer SLEEP_SESSION, fallback to SLEEP_ASLEEP
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

        if (sleepSession.isNotEmpty) {
          healthData = sleepSession;
          print('😴 Android sleep data: ${sleepSession.length} sessions (using session)');
        } else {
          healthData = sleepAsleep;
          print('😴 Android sleep data: ${sleepAsleep.length} asleep (using asleep)');
        }
      }

      print('😴 Total raw sleep data points: ${healthData.length}');

      if (healthData.isEmpty) {
        print('😴 ⚠️ No sleep data returned');
        return 0.0;
      }

      final totalMinutes = _sumMergedSleepMinutes(healthData);
      print('😴 Total sleep minutes: $totalMinutes');
      return totalMinutes;
    } catch (e) {
        print('❌ Error fetching sleep data: $e');
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

      // iOS: Use only ACTIVE_ENERGY_BURNED (not BASAL) to avoid inflated totals
      // BASAL is resting metabolic rate and would double-count with active
      final types = Platform.isIOS
          ? [HealthDataType.ACTIVE_ENERGY_BURNED]
          : [HealthDataType.ACTIVE_ENERGY_BURNED, HealthDataType.TOTAL_CALORIES_BURNED];

      final dataSets = await Future.wait(types.map((type) {
        return _health.getHealthDataFromTypes(
          types: [type],
          startTime: startTime.toLocal(),
          endTime: endTime.toLocal(),
        );
      }));

      final allCalories = dataSets.expand((e) => e).toList();

      final typeCount = <String, int>{};
      for (var i = 0; i < types.length; i++) {
        typeCount[types[i].name] = dataSets[i].length;
      }
      print('🔥 Calorie points by type: $typeCount');

      if (allCalories.isEmpty) {
        print('🔥 ⚠️ No calorie data returned. Checking permissions...');
        for (final type in types) {
          final hasPermission = await _health.hasPermissions(
            [type],
            permissions: [HealthDataAccess.READ],
          );
          print('🔥 ${type.name} permission: $hasPermission');
        }
      }

      // Deduplicate
      final uniqueCalories = <String, HealthDataPoint>{};

      for (final point in allCalories) {
        // Create unique key based on timestamp and value (rounded)
        final timeKey = point.dateFrom.millisecondsSinceEpoch ~/ 60000;
        final rawValue = _extractNumericValue(point) ?? 0;
        final value = _normalizeValue(point, rawValue);
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
        final rawValue = _extractNumericValue(point) ?? 0;
        final value = _normalizeValue(point, rawValue);
        print('  Calorie point: ${point.type.name} = $value kcal (raw: $rawValue ${point.unitString}) at ${point.dateFrom.toLocal()} (source: ${point.sourceName})');
      }

      return _convertHealthDataPoints(uniqueCalories.values.toList(), null);
    } catch (e) {
      print('❌ Error fetching calorie data: $e');
      return [];
    }
  }
}