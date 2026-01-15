class UpdateAlertSettingsRequest {
  final double lowThreshold;
  final double highThreshold;
  final double criticalLowThreshold;final double criticalHighThreshold;
  final double targetRangeLow;
  final double targetRangeHigh;
  final double insulinCarbRatio;
  final double correctionFactor;

  UpdateAlertSettingsRequest({
    required this.lowThreshold,
    required this.highThreshold,
    required this.criticalLowThreshold,
    required this.criticalHighThreshold,
    required this.targetRangeLow,
    required this.targetRangeHigh,
    required this.insulinCarbRatio,
    required this.correctionFactor,
  });

  Map<String, dynamic> toJson() {
    return {
      'lowThreshold': lowThreshold.toInt(),
      'highThreshold': highThreshold.toInt(),
      'criticalLowThreshold': criticalLowThreshold.toInt(),
      'criticalHighThreshold': criticalHighThreshold.toInt(),
      'targetRangeLow': targetRangeLow.toInt(),
      'targetRangeHigh': targetRangeHigh.toInt(),
      'insulinCarbRatio': insulinCarbRatio, // Backend Float
      'correctionFactor': correctionFactor, // Backend Float
    };
  }
}