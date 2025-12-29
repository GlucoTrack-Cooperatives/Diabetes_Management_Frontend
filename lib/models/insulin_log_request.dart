class InsulinLogRequest {
  final String medicationId;
  final double units;

  InsulinLogRequest({
    required this.medicationId,
    required this.units,
  });

  Map<String, dynamic> toJson() {
    return {
      'medicationId': medicationId,
      'units': units,
    };
  }
}
