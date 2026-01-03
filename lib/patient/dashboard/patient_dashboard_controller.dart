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
  return DashboardController(ref.watch(dashboardRepositoryProvider));
});

class DashboardController extends StateNotifier<AsyncValue<DashboardState>> {
  final DashboardRepository _repository;

  DashboardController(this._repository) : super(const AsyncValue.loading()) {
    refreshData();
  }

  Future<void> refreshData({int historyHours = 24}) async {
    // A "hard" refresh that shows a loading spinner is only needed on the initial load.
    if (!state.hasValue) {
      state = const AsyncValue.loading();
    }

    try {
      // Fetch everything in parallel
      final results = await Future.wait([
        _repository.getLatestGlucose(),       // Index 0
        _repository.getGlucoseHistory(24),    // Index 1
        _repository.getStats(),               // Index 2
        _repository.getRecentMeals(),         // Index 3
        _repository.getPatientProfile(),
      ]);

      state = AsyncValue.data(DashboardState(
        latestGlucose: results[0] as GlucoseReading?,
        history: results[1] as List<GlucoseReading>,
        stats: results[2] as DashboardStats?,
        recentMeals: results[3] as List<RecentMeal>,
        patient: results[4] as Patient?, // Assign Patient
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
