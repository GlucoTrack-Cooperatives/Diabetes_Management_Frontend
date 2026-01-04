import 'package:diabetes_management_system/patient/dashboard/patient_dashboard_controller.dart';
import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/theme/app_text_styles.dart';
import 'package:diabetes_management_system/utils/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/dashboard_models.dart';
import '../../models/patient_profile.dart';

class PatientDashboardScreen extends ConsumerWidget {
  const PatientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the Controller for Real Data
    final dashboardState = ref.watch(dashboardControllerProvider);

    return Scaffold(
      body: dashboardState.when(
        // Loading & Error States
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $err', style: const TextStyle(color: Colors.red)),
              TextButton(
                onPressed: () => ref.read(dashboardControllerProvider.notifier).refreshData(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        // Success State: Pass data to bodies
        data: (data) => ResponsiveLayout(
          mobileBody: _DashboardMobileBody(data: data),
          desktopBody: _DashboardDesktopBody(data: data),
        ),
      ),
    );
  }
}

// --- RESPONSIVE LAYOUTS ---

class _DashboardMobileBody extends StatelessWidget {
  final DashboardState data;
  const _DashboardMobileBody({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(data.patient),
            SizedBox(height: 24),
            _buildGlucoseCard(data.latestGlucose),
            SizedBox(height: 24),
            _buildNutritionSection(data.recentMeals),
            SizedBox(height: 24),
            _GlucoseMonitoringSection(readings: data.history),
          ],
        ),
      ),
    );
  }
}

class _DashboardDesktopBody extends StatelessWidget {
  final DashboardState data;
  const _DashboardDesktopBody({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(data.patient),
            SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _GlucoseMonitoringSection(readings: data.history),
                ),
                SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildGlucoseCard(data.latestGlucose),
                      SizedBox(height: 16),
                      _buildNutritionSection(data.recentMeals),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- SHARED WIDGETS ---

Widget _buildHeader(Patient? patient) {
  final name = patient?.firstName ?? 'Patient';
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Hello, $name', style: AppTextStyles.headline1),
      SizedBox(height: 4),
      Text('Latest Activity', style: AppTextStyles.bodyText2),
    ],
  );
}

Widget _buildGlucoseCard(GlucoseReading? glucose) {
  if (glucose == null) {
    return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text("No Data")));
  }

  final double mmolValue = glucose.value / 18.0;

  return Card(
    color: AppColors.primary.withOpacity(0.1),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Glucose', style: AppTextStyles.bodyText2),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                      mmolValue.toStringAsFixed(1),
                      style: AppTextStyles.headline1.copyWith(fontSize: 32)
                  ),
                  const SizedBox(width: 8),
                  Text('mmol/L', style: AppTextStyles.bodyText1),
                ],
              ),
            ],
          ),
          // Trend Arrow Logic
          if (glucose.trend != null)
            Row(
              children: [
                Icon(
                    _getTrendIcon(glucose.trend!),
                    color: _getTrendColor(glucose.trend!),
                    size: 24
                ),
                const SizedBox(width: 4),
                Text(glucose.trend!, style: AppTextStyles.bodyText1.copyWith(color: _getTrendColor(glucose.trend!))),
              ],
            )
        ],
      ),
    ),
  );
}

// Helper for Trend Icons
IconData _getTrendIcon(String trend) {
  switch (trend.toUpperCase()) {
    case 'RISING': return Icons.arrow_upward;
    case 'FALLING': return Icons.arrow_downward;
    case 'STABLE': return Icons.arrow_forward;
    default: return Icons.horizontal_rule;
  }
}

Color _getTrendColor(String trend) {
  return trend.toUpperCase() == 'RISING' ? Colors.red : Colors.green;
}

Widget _buildNutritionSection(List<RecentMeal> meals) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Today\'s Nutrition', style: AppTextStyles.headline2),
      const SizedBox(height: 12),
      Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: meals.isEmpty
            ? const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("No meals logged today"),
        )
            : Column(
          children: [
            for (int i = 0; i < meals.length; i++) ...[
              ListTile(
                title: Text(
                  meals[i].description, // "Oatmeal with Berries"
                  style: AppTextStyles.bodyText1,
                ),
                subtitle: Text(
                  meals[i].carbs, // "45g Carbs" (from Backend)
                  style: AppTextStyles.bodyText2,
                ),
                trailing: Text(
                  'GL: 0', // TODO(): Calc this hardcoded value by AI?
                  style: AppTextStyles.bodyText1,
                ),
              ),
              // Add divider only if it's not the last item
              if (i < meals.length - 1)
                const Divider(height: 1),
            ]
          ],
        ),
      )
    ],
  );
}
Widget _buildStatRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyText1),
        Text(value, style: AppTextStyles.headline2.copyWith(fontSize: 16)),
      ],
    ),
  );
}


class _GlucoseMonitoringSection extends StatefulWidget {
  final List<GlucoseReading> readings;

  const _GlucoseMonitoringSection({required this.readings});

  @override
  __GlucoseMonitoringSectionState createState() => __GlucoseMonitoringSectionState();
}

class __GlucoseMonitoringSectionState extends State<_GlucoseMonitoringSection> {
  String _selectedRange = '24H';

  // Constants for Time calculations (in milliseconds)
  static const int _hourInMs = 3600000;
  static const int _minuteInMs = 60000;

  // 1. Filter AND Downsample Data based on selected range
  List<FlSpot> _getVisibleSpots(double minX, double maxX) {
    if (widget.readings.isEmpty) return [];

    // Step A: Basic Range Filtering
    final rawFiltered = widget.readings.where((r) {
      final t = r.timestamp.millisecondsSinceEpoch.toDouble();
      return t >= minX && t <= maxX;
    }).toList();

    // Sort oldest to newest
    rawFiltered.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (rawFiltered.isEmpty) return [];

    // Step B: Downsampling Logic
    List<GlucoseReading> displayReadings = [];

    // Define the "Resolution" based on the selected range
    // 4H  -> Show everything (5 min resolution)
    // 8H  -> Show every 15 mins
    // 24H -> Show every 30 mins
    int skipMinutes;
    if (_selectedRange == '24H') {
      skipMinutes = 30;
    } else if (_selectedRange == '8H') {
      skipMinutes = 15;
    } else {
      skipMinutes = 5; // Show all
    }

    if (skipMinutes > 0) {
      DateTime? lastAddedTime;

      for (var reading in rawFiltered) {
        if (lastAddedTime == null) {
          displayReadings.add(reading);
          lastAddedTime = reading.timestamp;
        } else {
          final difference = reading.timestamp.difference(lastAddedTime).inMinutes;
          // Only add if enough time has passed since the last point
          if (difference >= skipMinutes) {
            displayReadings.add(reading);
            lastAddedTime = reading.timestamp;
          }
        }
      }
    } else {
      displayReadings = rawFiltered;
    }

    // Step C: Convert to Spots (Value / 18.0 for mmol/L)
    return displayReadings.map((r) {
      return FlSpot(
        r.timestamp.millisecondsSinceEpoch.toDouble(),
        r.value / 18.0,
      );
    }).toList();
  }

  // 2. Calculate Axis Boundaries (Snapping to round numbers)
  (double minX, double maxX, double interval) _getAxisDetails() {
    final now = DateTime.now();

    // We snap the 'Max' time to the next logical block so the graph looks "finished"
    // e.g., if it's 10:15, 4H graph extends to 10:30 or 11:00.
    DateTime snappedMax;
    Duration rangeDuration;
    double intervalMs;

    switch (_selectedRange) {
      case '4H':
      // Snap to next 30 minutes
        final remainder = 30 - (now.minute % 30);
        snappedMax = now.add(Duration(minutes: remainder)).subtract(Duration(seconds: now.second, milliseconds: now.millisecond));
        rangeDuration = const Duration(hours: 4);
        intervalMs = 30 * _minuteInMs.toDouble(); // 30 Minute interval
        break;
      case '8H':
      // Snap to next hour
        final remainder = 60 - now.minute;
        snappedMax = now.add(Duration(minutes: remainder)).subtract(Duration(seconds: now.second, milliseconds: now.millisecond));
        rangeDuration = const Duration(hours: 8);
        intervalMs = _hourInMs.toDouble(); // 1 Hour interval
        break;
      case '24H':
      default:
      // Snap to next hour
        final remainder = 60 - now.minute;
        snappedMax = now.add(Duration(minutes: remainder)).subtract(Duration(seconds: now.second, milliseconds: now.millisecond));
        rangeDuration = const Duration(hours: 24);
        intervalMs = 4 * _hourInMs.toDouble(); // 4 Hour interval (to fit screen)
        break;
    }

    final maxX = snappedMax.millisecondsSinceEpoch.toDouble();
    final minX = snappedMax.subtract(rangeDuration).millisecondsSinceEpoch.toDouble();

    return (minX, maxX, intervalMs);
  }

  @override
  Widget build(BuildContext context) {
    // Get calculated boundaries
    final (minX, maxX, interval) = _getAxisDetails();
    final spots = _getVisibleSpots(minX, maxX);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Glucose Monitoring', style: AppTextStyles.headline2),
        const SizedBox(height: 12),
        // Time Range Selector
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: ['4H', '8H', '24H'].map((label) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(label),
                selected: _selectedRange == label,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedRange = label);
                },
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // The Chart
        SizedBox(
          height: 250,
          child: LineChart(
            LineChartData(
              // 3. Tooltip Formatting (1 decimal place)
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((barSpot) {
                      return LineTooltipItem(
                        barSpot.y.toStringAsFixed(1), // Logic: 1 decimal place
                        const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold
                        ),
                      );
                    }).toList();
                  },
                ),
                handleBuiltInTouches: true,
              ),

              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                verticalInterval: interval, // Grid lines align with round hours
                horizontalInterval: 2,
                getDrawingVerticalLine: (value) {
                  return FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1);
                },
                getDrawingHorizontalLine: (value) {
                  return FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1);
                },
              ),

              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),

                // Left Y-Axis Titles
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 2, // Every 2 mmol/L
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      // Only show integer values for cleaner axis
                      if (value % 2 == 0) {
                        return Text(value.toInt().toString(), style: AppTextStyles.bodyText2);
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),

                // Bottom X-Axis Titles (Time)
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: interval, // Use the calculated interval (30m, 1h, or 4h)
                    getTitlesWidget: (value, meta) {
                      // Avoid showing label if it falls outside our snapped range
                      if (value < minX || value > maxX) return const SizedBox.shrink();

                      final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('HH:mm').format(date),
                          style: AppTextStyles.bodyText2.copyWith(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),

              borderData: FlBorderData(show: false),

              // 4. Set Fixed Boundaries
              minX: minX,
              maxX: maxX,
              minY: 0,
              maxY: 20, // Approx 360 mg/dL - reasonable cap for mmol/L

              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.2,
                  color: AppColors.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.15)
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


// class __GlucoseMonitoringSectionState extends State<_GlucoseMonitoringSection> {
//   List<FlSpot> _allData = [];
//   List<FlSpot> _visibleData = [];
//   String _selectedRange = '24H';
//
//   @override
//   void initState() {
//     super.initState();
//     _loadGlucoseData();
//   }
//
//   Future<void> _loadGlucoseData() async {
//     final rawData = await rootBundle.loadString('assets/data/Dexcom_data.csv');
//     List<List<dynamic>> csvTable = CsvToListConverter().convert(rawData);
//
//     List<FlSpot> spots = [];
//     final targetDay = DateTime(2025, 11, 22);
//
//     for (var i = 1; i < csvTable.length; i++) {
//       final row = csvTable[i];
//       try {
//         final timestamp = DateTime.parse(row[1]);
//         if (timestamp.year == targetDay.year && timestamp.month == targetDay.month && timestamp.day == targetDay.day) {
//           final hour = timestamp.hour + (timestamp.minute / 60.0);
//           final glucoseMgDl = double.parse(row[7].toString());
//           final glucoseMmolL = glucoseMgDl / 18.0;
//           spots.add(FlSpot(hour, glucoseMmolL));
//         }
//       } catch (e) {
//         // print('Error parsing row: $row. Error: $e');
//       }
//     }
//
//     spots.sort((a, b) => a.x.compareTo(b.x));
//
//     setState(() {
//       _allData = spots;
//       _updateVisibleData();
//     });
//   }
//
//   void _updateVisibleData() {
//     if (_allData.isEmpty) {
//       _visibleData = [];
//       return;
//     }
//
//     final now = _allData.map((spot) => spot.x).reduce((a, b) => a > b ? a : b);
//     double minHour = 0;
//
//     switch (_selectedRange) {
//       case '4H':
//         minHour = now - 4;
//         break;
//       case '8H':
//         minHour = now - 8;
//         break;
//       case '24H':
//       default:
//         minHour = 0;
//         break;
//     }
//
//     setState(() {
//       _visibleData = _allData.where((spot) => spot.x >= minHour).toList();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text('Glucose Monitoring', style: AppTextStyles.headline2),
//         SizedBox(height: 12),
//         Material(
//           color: Colors.transparent,
//           child: SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: ['4H', '8H', '24H'].map((label) {
//                 return Padding(
//                   padding: const EdgeInsets.only(right: 8.0),
//                   child: ChoiceChip(
//                     label: Text(label),
//                     selected: _selectedRange == label,
//                     onSelected: (selected) {
//                       if (selected) {
//                         setState(() {
//                           _selectedRange = label;
//                           _updateVisibleData();
//                         });
//                       }
//                     },
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),
//         ),
//         SizedBox(height: 16),
//         SizedBox(
//           height: 200,
//           child: _allData.isEmpty
//               ? Center(child: CircularProgressIndicator())
//               : LineChart(
//                   LineChartData(
//                     gridData: FlGridData(show: false),
//                     titlesData: FlTitlesData(
//                       leftTitles: AxisTitles(
//                         sideTitles: SideTitles(
//                           showTitles: true,
//                           reservedSize: 40,
//                           getTitlesWidget: (value, meta) {
//                             // Show fewer labels on the Y-axis
//                             if (value % 5 == 0) {
//                               return Text('${value.toInt()}', style: AppTextStyles.bodyText2, textAlign: TextAlign.left);
//                             }
//                             return Text('');
//                           },
//                         ),
//                       ),
//                       rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                       topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                       bottomTitles: AxisTitles(
//                         sideTitles: SideTitles(
//                           showTitles: true,
//                           reservedSize: 22,
//                           interval: 4, // Show a label every 4 hours
//                           getTitlesWidget: (value, meta) => Text('${value.toInt()}:00', style: AppTextStyles.bodyText2),
//                         ),
//                       ),
//                     ),
//                     borderData: FlBorderData(show: true, border: Border.all(color: AppColors.primary.withOpacity(0.2))),
//                     lineBarsData: [
//                       LineChartBarData(
//                         spots: _visibleData,
//                         isCurved: true,
//                         color: AppColors.primary,
//                         barWidth: 3,
//                         isStrokeCapRound: true,
//                         dotData: FlDotData(show: false),
//                         belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.1)),
//                       ),
//                     ],
//                   ),
//                 ),
//         ),
//       ],
//     );
//   }
// }
