import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/patient_profile.dart';
import '../../repositories/dashboard_repository.dart';
import '../../models/dashboard_models.dart';

class DashboardState {
  final GlucoseReading? latestGlucose;
  final List<GlucoseReading> history;
  final DashboardStats? stats;
  final List<RecentMeal> recentMeals;
  final Patient? patient;

  DashboardState({
    this.latestGlucose,
    this.history = const [],
    this.stats,
    this.recentMeals = const [],
    this.patient,
  });
}

final dashboardControllerProvider = StateNotifierProvider<DashboardController, AsyncValue<DashboardState>>((ref) {
  final controller = DashboardController(ref.watch(dashboardRepositoryProvider));
  ref.onDispose(() => controller.dispose());
  return controller;
});

class DashboardController extends StateNotifier<AsyncValue<DashboardState>> {
  final DashboardRepository _repository;
  Timer? _refreshTimer;

  DashboardController(this._repository) : super(const AsyncValue.loading()) {
    refreshData();
    _startPolling();
  }

  void _startPolling() {
    _refreshTimer?.cancel();
    // Faster polling for better real-time monitoring
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
    // Keep showing old data while fetching new data (don't show loading spinner every minute)
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
      ]);

      final dashboardState = DashboardState(
        latestGlucose: results[0] as GlucoseReading?,
        history: results[1] as List<GlucoseReading>,
        stats: results[2] as DashboardStats?,
        recentMeals: results[3] as List<RecentMeal>,
        patient: results[4] as Patient?,
      );

      // Debug print to see if new data is arriving
      print("Dashboard Data Refreshed. Readings: ${dashboardState.history.length}");

      state = AsyncValue.data(dashboardState);
    } catch (e, stack) {
      print("Error refreshing dashboard: $e");
      if (!state.hasValue) {
        state = AsyncValue.error(e, stack);
      }
    }
  }
}
