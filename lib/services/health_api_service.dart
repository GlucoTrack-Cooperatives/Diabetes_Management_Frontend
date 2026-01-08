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
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.WATER,
  ];

  /// Request permissions for all health data types
  /// Returns true if permissions granted, false otherwise
  Future<bool> requestPermissions() async {
    try {
      final permissions = _healthTypes
          .map((type) => HealthDataAccess.READ_WRITE)
          .toList();

      final granted = await _health.requestAuthorization(
        _healthTypes,
        permissions: permissions,
      );

      return granted;
    } catch (e) {
      print('Error requesting health permissions: $e');
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
}
