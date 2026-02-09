class GlucoseReading {
  final double value; 
  final String? trend; 
  final DateTime timestamp;

  GlucoseReading({
    required this.value,
    this.trend,
    required this.timestamp,
  });

  factory GlucoseReading.fromJson(Map<String, dynamic> json) {
    String ts = json['timestamp'];

    // 1. parse() shifts "17:17Z" to "18:17 Local".
    // 2. toUtc() shifts "18:17 Local" back to "17:17 UTC".
    // This ensures 'raw' always contains the digits exactly as they appear in the JSON.
    DateTime raw = DateTime.parse(ts).toUtc();

    return GlucoseReading(
      value: (json['value'] as num).toDouble(),
      trend: json['trend'],
      // 3. Now we create a local time using the original digits (17:17).
      timestamp: DateTime(
        raw.year,
        raw.month,
        raw.day,
        raw.hour,
        raw.minute,
        raw.second,
        raw.millisecond,
      ),
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

class RecentMeal {
  final String description;
  final String carbs;    
  final String calories; 
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
