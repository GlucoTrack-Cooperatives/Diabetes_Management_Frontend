import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/dashboard_repository.dart';
import '../../models/dashboard_models.dart';

class DashboardState {
  final GlucoseReading? latestGlucose;
  final List<GlucoseReading> history;
  final DashboardStats? stats;
  final List<RecentMeal> recentMeals; // Add this field

  DashboardState({
    this.latestGlucose,
    this.history = const [],
    this.stats,
    this.recentMeals = const [], // Default empty
  });
}

final dashboardControllerProvider = StateNotifierProvider<DashboardController, AsyncValue<DashboardState>>((ref) {
  return DashboardController(ref.watch(dashboardRepositoryProvider));
});

class DashboardController extends StateNotifier<AsyncValue<DashboardState>> {
  final DashboardRepository _repository;

  DashboardController(this._repository) : super(const AsyncValue.loading()) {
    refreshData();
  }

  Future<void> refreshData({int historyHours = 24}) async {
    if (state.hasValue) state = const AsyncValue.loading();

    try {
      // Fetch everything in parallel
      final results = await Future.wait([
        _repository.getLatestGlucose(),       // Index 0
        _repository.getGlucoseHistory(24),    // Index 1
        _repository.getStats(),               // Index 2
        _repository.getRecentMeals(),         // Index 3 (New)
      ]);

      state = AsyncValue.data(DashboardState(
        latestGlucose: results[0] as GlucoseReading?,
        history: results[1] as List<GlucoseReading>,
        stats: results[2] as DashboardStats?,
        recentMeals: results[3] as List<RecentMeal>,
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}