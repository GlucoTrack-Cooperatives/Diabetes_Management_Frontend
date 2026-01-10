import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/health_api_service.dart';

// State class to hold the data
class LifestyleData {
  final int steps;
  final double activeCalories;
  final Duration sleepDuration;
  final double? weight;
  final bool isLoading;

  LifestyleData({
    this.steps = 0,
    this.activeCalories = 0.0,
    this.sleepDuration = Duration.zero,
    this.weight,
    this.isLoading = true,
  });

  LifestyleData copyWith({
    int? steps,
    double? activeCalories,
    Duration? sleepDuration,
    double? weight,
    bool? isLoading,
  }) {
    return LifestyleData(
      steps: steps ?? this.steps,
      activeCalories: activeCalories ?? this.activeCalories,
      sleepDuration: sleepDuration ?? this.sleepDuration,
      weight: weight ?? this.weight,
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
    // Automatically try to fetch data (and ask permissions) when controller is created
    syncHealthData();
  }

  /// This method triggers the permission request and fetches data
  Future<void> syncHealthData() async {
    state = state.copyWith(isLoading: true);

    try {
      // 1. Check & Request Permissions
      final hasPermissions = await _healthService.hasPermissions();
      print(" Has permissions: $hasPermissions");
      if (!hasPermissions) {
        final granted = await _healthService.requestPermissions();
        print(" Permissions granted: $granted");
        if (!granted) {
          // If denied, we stop loading but keep empty data
          state = state.copyWith(isLoading: false);
          return;
        }
      }

      // 2. Define Time Ranges
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfNow = now;
      final yesterday = now.subtract(const Duration(hours: 24));

      print("⏰ Local time now: $now");
      print("⏰ Start of day: $startOfDay");
      print("⏰ Time range for daily data: $startOfDay to $endOfNow");
      print("⏰ Time range for sleep: $yesterday to $endOfNow");

      // 3. Fetch Data
      // Steps
      print("👟 Fetching steps...");
      final steps = await _healthService.getTotalStepsForDay(now);
      print("👟 Steps: ${steps ?? 0}");


      print("🔥 Fetching total calories...");
      final caloriePoints = await _healthService.getTotalEnergyData(yesterday, now);
      print("🔥 Received ${caloriePoints.length} calorie data points");

      // Filter to only today's data after fetching
      final todayCalories = caloriePoints.where((point) {
        final pointDate = point.timestamp;
        final isSameDay = pointDate.year == now.year &&
            pointDate.month == now.month &&
            pointDate.day == now.day;
        if (isSameDay) {
          print("  ✅ Including: ${point.value} ${point.unit} at ${point.timestamp}");
        } else {
          print("  ❌ Excluding (wrong day): ${point.value} ${point.unit} at ${point.timestamp}");
        }
        return isSameDay;
      }).toList();

      final totalCalories = todayCalories.fold(0.0, (sum, point) {
        return sum + point.value;
      });
      print("🔥 Total calories for today: $totalCalories");


      // Sleep (Sum duration from last 24h)
      print("😴 Fetching sleep data...");
      final sleepPoints = await _healthService.getSleepData(yesterday, now);
      print("😴 Received ${sleepPoints.length} sleep data points");

      final totalSleepMinutes = sleepPoints.fold(
          0.0, (sum, point) => sum + point.value);
      print("😴 Total sleep minutes: $totalSleepMinutes");

      // Weight (Latest entry in last 30 days)
      print("⚖️ Fetching weight data...");
      final weightPoints = await _healthService.getWeightData(
          yesterday.subtract(const Duration(days: 30)),
          now
      );
      print("⚖️ Received ${weightPoints.length} weight data points");

      double? latestWeight;
      if (weightPoints.isNotEmpty) {
        weightPoints.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        latestWeight = weightPoints.first.value;
        print("⚖️ Latest weight: $latestWeight kg");
      }

      // 4. Update State
      state = state.copyWith(
        steps: steps ?? 0,
        activeCalories: totalCalories,
        sleepDuration: Duration(minutes: totalSleepMinutes.toInt()),
        weight: latestWeight,
        isLoading: false,
      );

      print("✅ Health data sync complete!");
      print("   Steps: ${steps ?? 0}");
      print("   Calories: $totalCalories");
      print("   Sleep: ${totalSleepMinutes.toInt()} min");
      print("   Weight: ${latestWeight ?? 'N/A'} kg");
    } catch (e) {
      print("❌ Error syncing health data: $e");
      print("Stack trace: ${StackTrace.current}");
      state = state.copyWith(isLoading: false);
    }
  }
}