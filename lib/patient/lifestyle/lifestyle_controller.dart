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
      print("📱 Has permissions: $hasPermissions");
      if (!hasPermissions) {
        print("📱 Requesting permissions...");
        final granted = await _healthService.requestPermissions();
        print("📱 Permissions granted: $granted");
        if (!granted) {
          print("📱 ❌ Permissions denied by user");
          state = state.copyWith(isLoading: false);
          return;
        }
      }

      // 2. Define Time Ranges (using local time)
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      // For sleep: check from 6 PM yesterday to now (captures last night's sleep)
      final sleepStart = startOfDay.subtract(const Duration(hours: 3));

      // For calories: get last 2 days to be safe
      final caloriesStart = now.subtract(const Duration(days: 2));

      print("⏰ Current local time: $now");
      print("⏰ Timezone: ${now.timeZoneName} (UTC${now.timeZoneOffset.inHours >= 0 ? '+' : ''}${now.timeZoneOffset.inHours})");
      print("⏰ Start of day: $startOfDay");
      print("⏰ Sleep query range: $sleepStart to $now");
      print("⏰ Calories query range: $caloriesStart to $now");

      // 3. Fetch Data
      // Steps
      print("👟 Fetching steps...");
      final steps = await _healthService.getTotalStepsForDay(now);
      print("👟 Steps result: ${steps ?? 0}");

      // Calories - try fetching more days
      print("🔥 Fetching calories...");
      final caloriePoints = await _healthService.getTotalEnergyData(caloriesStart, now);
      print("🔥 Received ${caloriePoints.length} calorie data points");

      // Filter to only today's data
      final todayCalories = caloriePoints.where((point) {
        final pointDate = point.timestamp.toLocal();
        final isSameDay = pointDate.year == now.year &&
            pointDate.month == now.month &&
            pointDate.day == now.day;
        if (isSameDay) {
          print("  ✅ Including calorie: ${point.value} ${point.unit} at ${point.timestamp.toLocal()} from ${point.source}");
        }
        return isSameDay;
      }).toList();

      final totalCalories = todayCalories.fold(0.0, (sum, point) => sum + point.value);
      print("🔥 Total calories for today: $totalCalories");

      // Sleep - query wider range
      print("😴 Fetching sleep data...");
      final totalSleepMinutes = await _healthService.getTotalSleepMinutes(sleepStart, now);
      print("😴 Total sleep: $totalSleepMinutes minutes (${(totalSleepMinutes / 60).toStringAsFixed(1)} hours)");

      // Weight (Latest entry in last 30 days)
      print("⚖️ Fetching weight data...");
      final weightPoints = await _healthService.getWeightData(
        now.subtract(const Duration(days: 30)),
        now,
      );
      print("⚖️ Received ${weightPoints.length} weight data points");

      double? latestWeight;
      if (weightPoints.isNotEmpty) {
        weightPoints.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        latestWeight = weightPoints.first.value;
        print("⚖️ Latest weight: $latestWeight kg at ${weightPoints.first.timestamp.toLocal()}");
      } else {
        print("⚖️ No weight data found");
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
      print("   Calories: $totalCalories kcal");
      print("   Sleep: ${totalSleepMinutes.toInt()} min (${(totalSleepMinutes / 60).toStringAsFixed(1)} hours)");
      print("   Weight: ${latestWeight ?? 'N/A'} kg");
    } catch (e, stackTrace) {
      print("❌ Error syncing health data: $e");
      print("Stack trace: $stackTrace");
      state = state.copyWith(isLoading: false);
    }
  }
}