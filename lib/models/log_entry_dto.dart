class LogEntryDTO {
  final String type; // "Food" or "Insulin"
  final DateTime timestamp;
  final String description;

  LogEntryDTO({
    required this.type,
    required this.timestamp,
    required this.description,
  });factory LogEntryDTO.fromJson(Map<String, dynamic> json) {
    return LogEntryDTO(
      type: json['type'] ?? 'Unknown',
      timestamp: DateTime.parse(json['timestamp']),
      description: json['description'] ?? '',
    );
  }
}
