import 'package:diabetes_management_system/repositories/lifestyle_repository.dart';
import 'package:diabetes_management_system/services/secure_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diabetes_management_system/services/health_api_service.dart';
import 'package:diabetes_management_system/models/health_event_request.dart';

DateTime _getStartOfWeek(DateTime date) {
  return date.subtract(Duration(days: date.weekday - 1));
}

// State class to hold the data
class LifestyleData {
  final int steps;
  final double activeCalories;
  final Duration sleepDuration;
  final double? weight;
  final int waterGlasses; // NEW
  final bool isLoading;
  final List<HealthEventDTO> healthEvents;
  final DateTime selectedWeekStart;
  final bool isEventsLoading;

  LifestyleData({
    this.steps = 0,
    this.activeCalories = 0.0,
    this.sleepDuration = Duration.zero,
    this.weight,
    this.waterGlasses = 0, // NEW
    this.isLoading = true,
    this.healthEvents = const [],
    DateTime? selectedWeekStart,
    this.isEventsLoading = false,
  }): selectedWeekStart = selectedWeekStart ?? _getStartOfWeek(DateTime.now());


  LifestyleData copyWith({
    int? steps,
    double? activeCalories,
    Duration? sleepDuration,
    double? weight,
    int? waterGlasses, // NEW
    bool? isLoading,
    List<HealthEventDTO>? healthEvents,
    DateTime? selectedWeekStart,
    bool? isEventsLoading,
  }) {
    return LifestyleData(
      steps: steps ?? this.steps,
      activeCalories: activeCalories ?? this.activeCalories,
      sleepDuration: sleepDuration ?? this.sleepDuration,
      weight: weight ?? this.weight,
      waterGlasses: waterGlasses ?? this.waterGlasses, // NEW
      isLoading: isLoading ?? this.isLoading,
      healthEvents: healthEvents ?? this.healthEvents,
      selectedWeekStart: selectedWeekStart ?? this.selectedWeekStart,
      isEventsLoading: isEventsLoading ?? this.isEventsLoading,
    );
  }
}

// Provider definition
final lifestyleControllerProvider = StateNotifierProvider<LifestyleController, LifestyleData>((ref) {
  return LifestyleController(
      ref.watch(healthApiServiceProvider),
      ref.watch(lifestyleRepositoryProvider),
      ref.watch(storageServiceProvider)
  );
});

// Controller logic
class LifestyleController extends StateNotifier<LifestyleData> {
  final HealthApiService _healthService;
  final LifestyleRepository _repository;
  final SecureStorageService _storageService;

  LifestyleController(this._healthService, this._repository, this._storageService) : super(LifestyleData()) {
    syncHealthData();
    fetchWeeklyEvents();
  }

  Future<String> _getPatientId() async {
    final id = await _storageService.getUserId();
    if (id == null) throw Exception("User not logged in");
    return id;
  }

  Future<void> logEvent(String type, String? notes) async {
    final patientId = await _getPatientId();
    await _repository.logHealthEvent(patientId, HealthEventRequest(eventType: type, notes: notes));
    fetchWeeklyEvents(); // Refresh after logging
  }

  void changeWeek(int weeksToAdd) {
    state = state.copyWith(
      selectedWeekStart: state.selectedWeekStart.add(Duration(days: 7 * weeksToAdd)),
    );
    fetchWeeklyEvents();
  }

  Future<void> fetchWeeklyEvents() async {
    state = state.copyWith(isEventsLoading: true);
    final endOfWeek = state.selectedWeekStart.add(const Duration(days: 7));
    try {
      final patientId = await _getPatientId();
      final events = await _repository.getHealthEvents(patientId, state.selectedWeekStart, endOfWeek);
      state = state.copyWith(healthEvents: events, isEventsLoading: false);
    } catch (e) {
      state = state.copyWith(isEventsLoading: false);
    }
  }

  void addWater() async {
    // 1. Write to Health API (assuming 1 glass = 0.25 Liters)
    final success = await _healthService.writeWater(0.25, DateTime.now());
    if (success) {
      // 2. Refresh data to show the update
      await syncHealthData();
    }
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

      final waterLiters = await _healthService.getTotalWaterLiters(startOfDay, now);
      // Convert Liters back to glasses for the UI (0.25L = 1 glass)
      final glasses = (waterLiters / 0.25).round();

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
        waterGlasses: glasses,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}
