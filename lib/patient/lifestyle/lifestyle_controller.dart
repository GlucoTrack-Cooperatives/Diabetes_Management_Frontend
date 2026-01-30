import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/health_api_service.dart';

// State class to hold the data
class LifestyleData {
  final int steps;
  final double activeCalories;
  final Duration sleepDuration;
  final double? weight;
  final int waterGlasses; // NEW
  final bool isLoading;

  LifestyleData({
    this.steps = 0,
    this.activeCalories = 0.0,
    this.sleepDuration = Duration.zero,
    this.weight,
    this.waterGlasses = 0, // NEW
    this.isLoading = true,
  });

  LifestyleData copyWith({
    int? steps,
    double? activeCalories,
    Duration? sleepDuration,
    double? weight,
    int? waterGlasses, // NEW
    bool? isLoading,
  }) {
    return LifestyleData(
      steps: steps ?? this.steps,
      activeCalories: activeCalories ?? this.activeCalories,
      sleepDuration: sleepDuration ?? this.sleepDuration,
      weight: weight ?? this.weight,
      waterGlasses: waterGlasses ?? this.waterGlasses, // NEW
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Provider definition
final lifestyleControllerProvider = StateNotifierProvider<LifestyleController, LifestyleData>((ref) {
  return LifestyleController(ref.watch(healthApiServiceProvider));
});

// Controller logic
class LifestyleController extends StateNotifier<LifestyleData> {
  final HealthApiService _healthService;

  LifestyleController(this._healthService) : super(LifestyleData()) {
    syncHealthData();
  }

  void addWater() {
    state = state.copyWith(waterGlasses: state.waterGlasses + 1);
  }

  void resetWater() {
    state = state.copyWith(waterGlasses: 0);
  }

  Future<void> syncHealthData() async {
    state = state.copyWith(isLoading: true);

    try {
      final hasPermissions = await _healthService.hasPermissions();
      if (!hasPermissions) {
        final granted = await _healthService.requestPermissions();
        if (!granted) {
          state = state.copyWith(isLoading: false);
          return;
        }
      }

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final sleepStart = startOfDay.subtract(const Duration(hours: 3));
      final caloriesStart = now.subtract(const Duration(days: 2));

      final steps = await _healthService.getTotalStepsForDay(now);
      final caloriePoints = await _healthService.getTotalEnergyData(caloriesStart, now);
      
      final todayCalories = caloriePoints.where((point) {
        final pointDate = point.timestamp.toLocal();
        return pointDate.year == now.year && pointDate.month == now.month && pointDate.day == now.day;
      }).toList();

      final totalCalories = todayCalories.fold(0.0, (sum, point) => sum + point.value);
      final totalSleepMinutes = await _healthService.getTotalSleepMinutes(sleepStart, now);
      final weightPoints = await _healthService.getWeightData(now.subtract(const Duration(days: 30)), now);

      double? latestWeight;
      if (weightPoints.isNotEmpty) {
        weightPoints.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        latestWeight = weightPoints.first.value;
      }

      state = state.copyWith(
        steps: steps ?? 0,
        activeCalories: totalCalories,
        sleepDuration: Duration(minutes: totalSleepMinutes.toInt()),
        weight: latestWeight,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}
