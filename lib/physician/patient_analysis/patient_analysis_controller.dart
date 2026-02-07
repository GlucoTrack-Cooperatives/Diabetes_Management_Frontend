import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart'; // For Colors
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/log_entry_dto.dart';
import '../../models/dashboard_models.dart';
import '../../models/patient_profile.dart';
import 'package:diabetes_management_system/models/patient_alert_settings.dart';
import '../../repositories/patient_analysis_repository.dart';

// --- State Model ---
class PatientAnalysisState {
  final bool isLoading;
  final String tir; // Time in Range
  final String tbr; // Time Below Range
  final String cv;  // Coefficient of Variation
  final String gmi; // Glucose Management Indicator
  final List<FlSpot> glucoseSpots;
  final double averageGlucose;
  final List<LogEntryDTO> foodLogs;
  final List<LogEntryDTO> insulinLogs;
  final Map<String, String> derivedInsulinSettings; // e.g., {'Basal': 'Lantus', 'Bolus': 'Novolog'}
  final PatientAlertSettings? alertSettings;

  PatientAnalysisState({
    this.isLoading = true,
    this.tir = '--',
    this.tbr = '--',
    this.cv = '--',
    this.gmi = '--',
    this.glucoseSpots = const [],
    this.averageGlucose = 0,
    this.foodLogs = const [],
    this.insulinLogs = const [],
    this.derivedInsulinSettings = const {},
    this.alertSettings,
  });
}

// --- Controller ---
class PatientAnalysisController extends StateNotifier<PatientAnalysisState> {
  final PatientAnalysisRepository _repository;
  final String _patientId;

  PatientAnalysisController(this._repository, this._patientId) : super(PatientAnalysisState()) {
    loadData();
  }

  Future<void> loadData() async {
    try {
      state = PatientAnalysisState(isLoading: true);

      final results = await Future.wait([
        _repository.getGlucoseHistory(24, _patientId),
        _repository.getPatientRecentLogs(_patientId),
        _repository.getPatientProfile(_patientId),
      ]);
      
      final glucoseReadings = results[0] as List<GlucoseReading>;
      final allLogs = results[1] as List<LogEntryDTO>;
      final patientProfile = results[2] as Patient?;

      final foodLogs = allLogs.where((l) => l.type.toLowerCase() == 'food').toList();
      final insulinLogs = allLogs.where((l) => l.type.toLowerCase() == 'insulin').toList();

      // 3. Calculate Clinical Stats using GlucoseReading
      final stats = _calculateStats(glucoseReadings);

      // 4. Prepare Graph Data using GlucoseReading
      final spots = _generateSpots(glucoseReadings);

      // 4. Derive Medication Info
      final insulinSettings = _deriveMedicationUsage(insulinLogs);

      state = PatientAnalysisState(
        isLoading: false,
        tir: stats['TIR']!,
        tbr: stats['TBR']!,
        cv: stats['CV']!,
        gmi: stats['GMI']!,
        averageGlucose: stats['AVG'] != null ? double.parse(stats['AVG']!) : 0.0,
        glucoseSpots: spots,
        foodLogs: foodLogs,
        insulinLogs: insulinLogs,
        derivedInsulinSettings: insulinSettings,
        alertSettings: patientProfile?.alertSettings,
      );
    } catch (e) {
      // Handle error state appropriately
      print("Error loading analysis: $e");
      state = PatientAnalysisState(isLoading: false);
    }
  }

  Map<String, String> _calculateStats(List<GlucoseReading> readings) {
    if (readings.isEmpty) return {'TIR': 'N/A', 'TBR': 'N/A', 'CV': 'N/A', 'GMI': 'N/A', 'AVG': '0'};

    int total = readings.length;
    int inRange = 0;
    int belowRange = 0;
    double sum = 0;
    List<double> values = [];

    for (var reading in readings) {
      double val = reading.value;
      values.add(val);
      sum += val;

      if (val < 70) belowRange++;
      if (val >= 70 && val <= 180) inRange++;
    }

    double mean = sum / total;

    // GMI (%) = 3.31 + 0.02392 * [mean glucose in mg/dL]
    double gmiValue = 3.31 + (0.02392 * mean);

    // Calculate Standard Deviation for CV
    double sumSquaredDiff = 0;
    for (var val in values) {
      sumSquaredDiff += pow(val - mean, 2);
    }
    double stdDev = sqrt(sumSquaredDiff / total);
    double cv = (mean == 0) ? 0 : (stdDev / mean) * 100;

    return {
      'TIR': '${((inRange / total) * 100).toStringAsFixed(0)}%', //time in range
      'TBR': '${((belowRange / total) * 100).toStringAsFixed(0)}%', //time below range
      'CV': '${cv.toStringAsFixed(1)}%', // coefficient of variation
      'GMI': '${gmiValue.toStringAsFixed(1)}%',
      'AVG': mean.toStringAsFixed(0),
    };
  }

  List<FlSpot> _generateSpots(List<GlucoseReading> readings) {
    if (readings.isEmpty) return [];

    // 1. Define the start of the window (24 hours ago)
    final now = DateTime.now();
    final startTime = now.subtract(const Duration(hours: 24));

    readings.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return readings.map((reading) {
      // 2. Calculate x as "Hours passed since startTime"
      // If reading is at startTime, x = 0. If reading is 'now', x = 24.
      final difference = reading.timestamp.difference(startTime);

      // We use minutes / 60.0 to get decimal hours (e.g., 90 mins = 1.5 hours)
      double x = difference.inMinutes / 60.0;

      return FlSpot(x, reading.value);
    }).toList();
  }

  Map<String, String> _deriveMedicationUsage(List<LogEntryDTO> insulinLogs) {
    // Simple logic: find most frequent names used
    if (insulinLogs.isEmpty) return {'Basal': 'None detected', 'Bolus': 'None detected'};

    // You might differentiate by checking specific keywords or database fields if available
    // For now, let's assume logs might have subtypes or we just grab the most common one.
    // Ideally LogEntryDTO has a 'subtype' or 'name' field.

    // Placeholder logic:
    return {
      'Basal': 'Lantus (Derived)',
      'Bolus': 'Novolog (Derived)',
      // Real logic would count occurrences of insulin names here
    };
  }
}

// Provider
final patientAnalysisControllerProvider = StateNotifierProvider.family<PatientAnalysisController, PatientAnalysisState, String>((ref, patientId) {
  final repo = ref.watch(patientAnalysisRepositoryProvider);
  return PatientAnalysisController(repo, patientId);
});
