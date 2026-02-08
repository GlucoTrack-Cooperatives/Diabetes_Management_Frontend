import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/patient_profile.dart';
import '../../repositories/dashboard_repository.dart';
import '../../models/dashboard_models.dart';
import '../../models/log_entry_dto.dart';
import '../../services/health_api_service.dart';
import 'package:health/health.dart';

class DashboardState {
  final GlucoseReading? latestGlucose;
  final List<GlucoseReading> history;
  final DashboardStats? stats;
  final List<RecentMeal> recentMeals;
  final Patient? patient;
  final Map<String, dynamic>? thresholds;
  final List<LogEntryDTO> insulinLogs;

  DashboardState({
    this.latestGlucose,
    this.history = const [],
    this.stats,
    this.recentMeals = const [],
    this.patient,
    this.thresholds,
    this.insulinLogs = const [],
  });
}

final dashboardControllerProvider = StateNotifierProvider<DashboardController, AsyncValue<DashboardState>>((ref) {
  return DashboardController(
    ref.watch(dashboardRepositoryProvider),
    ref.watch(healthApiServiceProvider),
  );
});

class DashboardController extends StateNotifier<AsyncValue<DashboardState>> {
  final DashboardRepository _repository;
  final HealthApiService _healthService;
  Timer? _refreshTimer;

  DashboardController(this._repository, this._healthService) : super(const AsyncValue.loading()) {
    refreshData();
    _startPolling();
  }

  void _startPolling() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      refreshData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> refreshData({int historyHours = 24}) async {
    if (!mounted) return;

    if (!state.hasValue) {
      state = const AsyncValue.loading();
    }

    try {
      print('🔍 CONTROLLER: Starting refresh at ${DateTime.now()}');

      final results = await Future.wait([
        _repository.getLatestGlucose(),
        _repository.getGlucoseHistory(24),
        _repository.getStats(),
        _repository.getRecentMeals(),
        _repository.getPatientProfile(),
        _repository.getPatientThresholds(),
        _repository.getRecentInsulinLogs(),
      ]);

      if (!mounted) return;

      final latestGlucose = results[0] as GlucoseReading?;
      final history = results[1] as List<GlucoseReading>;

      print('🔍 LATEST: ${latestGlucose?.timestamp} = ${latestGlucose?.value} mg/dL');
      print('🔍 HISTORY: ${history.length} readings');
      if (history.isNotEmpty) {
        print('🔍 HISTORY RANGE: ${history.first.timestamp} to ${history.last.timestamp}');
        print('🔍 HISTORY LAST: ${history.last.timestamp} = ${history.last.value} mg/dL');
      }

      // Check if latest is in history
      final isInHistory = latestGlucose != null && history.any((r) =>
      r.timestamp.difference(latestGlucose.timestamp).abs().inSeconds < 5
      );
      print('🔍 IS LATEST IN HISTORY? $isInHistory');

      // BEFORE merge
      print('🔍 BEFORE MERGE: history.length = ${history.length}');

      // Merge
      final mergedHistory = _mergeLatestIntoHistory(latestGlucose, history);

      // AFTER merge
      print('🔍 AFTER MERGE: mergedHistory.length = ${mergedHistory.length}');
      if (mergedHistory.isNotEmpty) {
        print('🔍 MERGED LAST: ${mergedHistory.last.timestamp} = ${mergedHistory.last.value} mg/dL');
      }

      final dashboardState = DashboardState(
        latestGlucose: results[0] as GlucoseReading?,
        history: mergedHistory,
        stats: results[2] as DashboardStats?,
        recentMeals: results[3] as List<RecentMeal>,
        patient: results[4] as Patient?,
        thresholds: results[5] as Map<String, dynamic>?,
        insulinLogs: results[6] as List<LogEntryDTO>,
      );

      state = AsyncValue.data(dashboardState);
      print('🔍 CONTROLLER: State updated successfully');
    } catch (e, stack) {
      print("Error refreshing dashboard: $e");
      if (mounted && !state.hasValue) {
        state = AsyncValue.error(e, stack);
      }
    }
  }
}


List<GlucoseReading> _mergeLatestIntoHistory(GlucoseReading? latest, List<GlucoseReading> history) {
  print('🔍 MERGE CALLED: latest = ${latest?.timestamp}, history.length = ${history.length}');

  if (latest == null) {
    print('🔍 MERGE: Latest is null, returning original');
    return history;
  }

  // Check if latest already exists (within 5 seconds tolerance)
  final exists = history.any((r) {
    final diff = r.timestamp.difference(latest.timestamp).abs().inSeconds;
    if (diff < 5) {
      print('🔍 MERGE: Found matching reading (diff: ${diff}s)');
      return true;
    }
    return false;
  });

  if (exists) {
    print('🔍 MERGE: Latest already in history, returning original');
    return history;
  }

  // Add latest to history
  print('🔍 MERGE: Adding latest ${latest.value} mg/dL at ${latest.timestamp}');
  final merged = [...history, latest];
  merged.sort((a, b) => a.timestamp.compareTo(b.timestamp));

  print('🔍 MERGE: SUCCESS - ${history.length} → ${merged.length} readings');
  return merged;
}