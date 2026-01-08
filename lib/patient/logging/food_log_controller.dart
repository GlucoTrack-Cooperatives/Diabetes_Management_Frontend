import 'package:diabetes_management_system/patient/dashboard/patient_dashboard_controller.dart';
import 'package:diabetes_management_system/services/spoonacular_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diabetes_management_system/models/food_log_request.dart';
import 'package:diabetes_management_system/repositories/log_repository.dart';
import 'package:diabetes_management_system/services/secure_storage_service.dart';
import 'package:diabetes_management_system/models/log_entry_dto.dart';
import 'package:diabetes_management_system/models/insulin_log_request.dart';
import 'package:diabetes_management_system/models/medications_request.dart';
import 'package:image_picker/image_picker.dart';


abstract class FoodLogState {}
class FoodLogInitial extends FoodLogState {}
class FoodLogLoading extends FoodLogState {}
class FoodAnalysisLoading extends FoodLogState {}
class FoodLogSuccess extends FoodLogState {
  final String message;
  FoodLogSuccess(this.message);
}

class FoodAnalysisSuccess extends FoodLogState {
  final String description;
  final String carbs;
  final String calories;
  FoodAnalysisSuccess({required this.description, required this.carbs, required this.calories});
}

class FoodLogError extends FoodLogState {
  final String message;
  FoodLogError(this.message);
}

class FoodLogController extends StateNotifier<FoodLogState> {
  final Ref ref;
  final LogRepository _repository;
  final SecureStorageService _storage;
  final FoodAnalysisRepository _analysisRepository;


  FoodLogController(this.ref, this._repository, this._storage, this._analysisRepository) : super(FoodLogInitial());

  // --- NEW: ANALYZE IMAGE METHOD ---
  Future<void> analyzeImage(XFile image) async {
    state = FoodAnalysisLoading();

    try {
      final patientId = await _storage.getUserId();
      if (patientId == null) {
        state = FoodLogError("Session expired.");
        return;
      }

      final result = await _analysisRepository.analyzeFoodImage(patientId, image);

      if (result != null) {
        state = FoodAnalysisSuccess(
          description: result['description'],
          carbs: result['carbs'],
          calories: result['calories'],
        );
      } else {
        state = FoodLogError("Could not identify food.");
      }
    } catch (e) {
      state = FoodLogError("Analysis failed: $e");
    }
  }

  // --- NEW INSULIN METHOD ---
  Future<void> submitInsulin({
    required String medicationId,
    required String medicationName,
    required String unitsStr,
  }) async {

    if (unitsStr.isEmpty) {
      state = FoodLogError("Please enter the number of units.");
      return;
    }

    state = FoodLogLoading();

    try {
      final patientId = await _storage.getUserId();
      if (patientId == null) {
        state = FoodLogError("Session expired.");
        return;
      }

      final double units = double.tryParse(unitsStr) ?? 0.0;
      if (units <= 0) {
        state = FoodLogError("Units must be greater than 0.");
        return;
      }

      // B. Create Request
      final request = InsulinLogRequest(
        medicationId: medicationId,
        units: units,
      );

      await _repository.createInsulinLog(patientId, request);

      // D. Success
      state = FoodLogSuccess("$units U - $medicationName");

      ref.invalidate(recentLogsProvider);
      ref.read(dashboardControllerProvider.notifier).refreshData();

    } catch (e) {
      state = FoodLogError("Failed to log insulin: $e");
    }
  }
  // --- END NEW INSULIN METHOD ---

  // --- NEW FOOD LOG METHOD ---
  Future<void> submitLog({
    required String description,
    required String carbsStr,
    required String caloriesStr,
  }) async {
    // A. Validation Logic
    if (description.isEmpty || carbsStr.isEmpty) {
      state = FoodLogError("Please enter at least description and carbs.");
      return;
    }

    state = FoodLogLoading();

    try {
      // B. Get User ID
      final patientId = await _storage.getUserId();

      if (patientId == null) {
        state = FoodLogError("Session expired. Please login again.");
        return;
      }

      // C. Prepare Request
      final int carbs = int.tryParse(carbsStr) ?? 0;
      final int calories = int.tryParse(caloriesStr) ?? 0;

      final request = FoodLogRequest(
        description: description,
        carbs: carbs,
        mealType: "",
        calories: calories,
        imageUrl: "",
      );

      // D. Call API
      await _repository.createFoodLog(patientId, request);

      // E. Success
      state = FoodLogSuccess("${carbs}g Carbs - $description");

      ref.invalidate(recentLogsProvider);
      ref.read(dashboardControllerProvider.notifier).refreshData();

    } catch (e) {
      state = FoodLogError("Failed to submit log: $e");
    }
  }

  // Method to reset state back to initial (useful after showing a snackbar)
  void resetState() {
    state = FoodLogInitial();
  }
}

// --- NEW PROVIDER FOR FETCHING LOGS ---
// This automatically handles loading, error, and data states for the list.
final recentLogsProvider = FutureProvider.autoDispose<List<LogEntryDTO>>((ref) async {
  final repository = ref.watch(logRepositoryProvider);
  final storage = ref.watch(storageServiceProvider);

  final userId = await storage.getUserId();
  if (userId == null) throw Exception("User not logged in");

  return repository.getRecentLogs(userId);
});


// 3. Create the Provider
final foodLogControllerProvider = StateNotifierProvider<FoodLogController, FoodLogState>((ref) {
  return FoodLogController(
    ref,
    ref.watch(logRepositoryProvider),
    ref.watch(storageServiceProvider),
    ref.watch(foodAnalysisRepositoryProvider),
  );
});
