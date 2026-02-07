import 'package:flutter/material.dart';

enum GlucoseTrend {  none(0, 'None', Icons.horizontal_rule),
  doubleUp(1, 'Rising Fast', Icons.keyboard_double_arrow_up),
  singleUp(2, 'Rising', Icons.arrow_upward),
  fortyFiveUp(3, 'Rising Slightly', Icons.north_east),
  flat(4, 'Stable', Icons.trending_flat),
  fortyFiveDown(5, 'Falling Slightly', Icons.south_east),
  singleDown(6, 'Falling', Icons.arrow_downward),
  doubleDown(7, 'Falling Fast', Icons.keyboard_double_arrow_down),
  notComputable(8, 'N/A', Icons.help_outline),
  rateOutOfRange(9, 'Out of Range', Icons.warning_amber);

  final int value;
  final String label;
  final IconData icon;

  const GlucoseTrend(this.value, this.label, this.icon);

  static GlucoseTrend fromInt(dynamic val) {
    // Handle String or Int from API
    final intValue = val is String ? int.tryParse(val) ?? 0 : (val as int? ?? 0);
    return GlucoseTrend.values.firstWhere(
          (e) => e.value == intValue,
      orElse: () => GlucoseTrend.none,
    );
  }
}