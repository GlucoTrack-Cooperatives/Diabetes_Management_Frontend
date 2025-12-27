class FoodLogRequest {
  final String description;
  final int carbs;
  final String mealType;
  final int calories;
  final String imageUrl;

  FoodLogRequest({
    required this.description,
    required this.carbs,
    required this.mealType,
    required this.calories,
    required this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'carbs': carbs,
      'calories': calories,
      'mealType': mealType,
      'imageUrl': imageUrl,
    };
  }
}