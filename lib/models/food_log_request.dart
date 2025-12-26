class FoodLogRequest {
  final String description;
  final int carbs;
  final int calories;

  FoodLogRequest({
    required this.description,
    required this.carbs,
    required this.calories,
  });

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'carbs': carbs,
      'calories': calories,
    };
  }
}