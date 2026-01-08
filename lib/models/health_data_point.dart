/// Model representing a health data point
class HealthDataPoint {
  final String type;
  final double value;
  final String unit;
  final DateTime timestamp;
  final String? source;

  HealthDataPoint({
    required this.type,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.source,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'value': value,
        'unit': unit,
        'timestamp': timestamp.toIso8601String(),
        if (source != null) 'source': source,
      };

  factory HealthDataPoint.fromJson(Map<String, dynamic> json) => HealthDataPoint(
        type: json['type'] as String,
        value: (json['value'] as num).toDouble(),
        unit: json['unit'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        source: json['source'] as String?,
      );

  @override
  String toString() => 'HealthDataPoint(type: $type, value: $value $unit, timestamp: $timestamp)';
}
