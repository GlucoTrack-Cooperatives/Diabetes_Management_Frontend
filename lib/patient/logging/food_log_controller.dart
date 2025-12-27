import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diabetes_management_system/models/food_log_request.dart';
import 'package:diabetes_management_system/repositories/log_repository.dart';
import 'package:diabetes_management_system/services/secure_storage_service.dart';
import 'package:diabetes_management_system/models/log_entry_dto.dart';

// --- FOOD LOG'

// 1. Define the State
// This helps the UI know what to show (Loading spinner? Success snackbar? Error message?)
abstract class FoodLogState {}
class FoodLogInitial extends FoodLogState {}
class FoodLogLoading extends FoodLogState {}
class FoodLogSuccess extends FoodLogState {
  final String message;
  FoodLogSuccess(this.message);
}
class FoodLogError extends FoodLogState {
  final String message;
  FoodLogError(this.message);
}

// 2. Define the Controller Class
class FoodLogController extends StateNotifier<FoodLogState> {
  final Ref ref;
  final LogRepository _repository;
  final SecureStorageService _storage;

  FoodLogController(this.ref, this._repository, this._storage) : super(FoodLogInitial());

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
  );
});
