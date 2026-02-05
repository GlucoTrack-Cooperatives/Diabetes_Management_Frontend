class HealthEventRequest {
  final String eventType;
  final String? notes;

  HealthEventRequest({required this.eventType, this.notes});

  Map<String, dynamic> toJson() => {
    'eventType': eventType,
    'notes': notes,
  };
}

class HealthEventDTO {
  final String id;
  final String eventType;
  final String? notes;
  final DateTime timestamp;

  HealthEventDTO({
    required this.id,
    required this.eventType,
    this.notes,
    required this.timestamp,
  });

  factory HealthEventDTO.fromJson(Map<String, dynamic> json) {
    return HealthEventDTO(
      id: json['id'],
      eventType: json['eventType'],
      notes: json['notes'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}