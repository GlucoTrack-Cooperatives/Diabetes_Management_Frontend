import 'dart:async';
import 'dart:io';
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
  final Set<String> _syncedGlucoseKeys = <String>{};

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

      final dashboardState = DashboardState(
        latestGlucose: results[0] as GlucoseReading?,
        history: results[1] as List<GlucoseReading>,
        stats: results[2] as DashboardStats?,
        recentMeals: results[3] as List<RecentMeal>,
        patient: results[4] as Patient?,
        thresholds: results[5] as Map<String, dynamic>?,
        insulinLogs: results[6] as List<LogEntryDTO>,
      );

      state = AsyncValue.data(dashboardState);

      await _syncBloodGlucoseToHealthConnect(dashboardState.history);
    } catch (e, stack) {
      print("Error refreshing dashboard: $e");
      if (mounted && !state.hasValue) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<void> _syncBloodGlucoseToHealthConnect(List<GlucoseReading> history) async {
    if (!Platform.isAndroid || history.isEmpty) return;

    final canWrite = await _healthService.hasBloodGlucoseWritePermission();
    if (!canWrite) {
      print('Blood glucose write permission not granted. Skipping Health Connect sync.');
      return;
    }

    if (_syncedGlucoseKeys.length > 5000) {
      _syncedGlucoseKeys.clear();
    }

    for (final reading in history) {
      final timestamp = reading.timestamp.toLocal();
      final key = '${timestamp.millisecondsSinceEpoch ~/ 60000}-${reading.value.round()}';
      if (_syncedGlucoseKeys.contains(key)) continue;

      final wrote = await _healthService.writeBloodGlucose(reading.value, timestamp);
      if (wrote) {
        _syncedGlucoseKeys.add(key);
      }
    }
  }
}
