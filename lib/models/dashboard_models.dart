class GlucoseReading {
  final double value; // We store as double to handle both mg/dL (int) and mmol/L
  final String? trend; // "RISING", "FALLING", "STABLE", etc.
  final DateTime timestamp;

  GlucoseReading({
    required this.value,
    this.trend,
    required this.timestamp,
  });

  factory GlucoseReading.fromJson(Map<String, dynamic> json) {
    // Backend sends 'value' as Integer (likely mg/dL).
    // If you need mmol/L, divide by 18.0.
    // Here we assume Backend sends raw mg/dL and we convert for UI.
    double rawValue = (json['value'] as num).toDouble();

    return GlucoseReading(
      value: rawValue,
      trend: json['trend'],
      timestamp: DateTime.parse(json['timestamp']), // Handles ISO-8601 Instant
    );
  }
}

class DashboardStats {
  final double timeInRange;
  final double timeBelowRange;
  final double averageGlucose;

  DashboardStats({
    required this.timeInRange,
    required this.timeBelowRange,
    required this.averageGlucose,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      timeInRange: (json['timeInRange'] as num?)?.toDouble() ?? 0.0,
      timeBelowRange: (json['timeBelowRange'] as num?)?.toDouble() ?? 0.0,
      averageGlucose: (json['averageGlucose'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// Add this class to your existing file
class RecentMeal {
  final String description;
  final String carbs;    // Backend sends "45g Carbs"
  final String calories; // Backend sends "350 Kcal"
  final String timestamp;

  RecentMeal({
    required this.description,
    required this.carbs,
    required this.calories,
    required this.timestamp,
  });

  factory RecentMeal.fromJson(Map<String, dynamic> json) {
    return RecentMeal(
      description: json['description'] ?? 'Unknown Meal',
      carbs: json['carbs'] ?? '0g',
      calories: json['calories'] ?? '0 Kcal',
      timestamp: json['timestamp'] ?? '',
    );
  }
}

