class LogEntryDTO {
  final String type; // "Food" or "Insulin"
  final DateTime timestamp;
  final String description;
  final String? carbs;
  final String? calories;

  LogEntryDTO({
    required this.type,
    required this.timestamp,
    required this.description,
    this.carbs,
    this.calories,
  });

  factory LogEntryDTO.fromJson(Map<String, dynamic> json) {
    return LogEntryDTO(
      type: json['type'] ?? 'Unknown',
      timestamp: DateTime.parse(json['timestamp']),
      description: json['description'] ?? '',
      carbs: json['carbs']?.toString(),
      calories: json['calories']?.toString(),
    );
  }
}
