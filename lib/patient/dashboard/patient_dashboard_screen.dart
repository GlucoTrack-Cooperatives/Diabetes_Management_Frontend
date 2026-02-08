import 'package:diabetes_management_system/models/dashboard_models.dart';
import 'package:diabetes_management_system/models/iod_model.dart';
import 'package:diabetes_management_system/models/patient_alert_settings.dart';
import 'package:diabetes_management_system/models/patient_profile.dart';
import 'package:diabetes_management_system/patient/dashboard/patient_dashboard_controller.dart';
import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/theme/app_text_styles.dart';
import 'package:diabetes_management_system/utils/glucose_utils.dart';
import 'package:diabetes_management_system/utils/responsive_layout.dart';
import 'package:diabetes_management_system/widgets/custom_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/glucose_alert_settings.dart';
import 'package:diabetes_management_system/models/log_entry_dto.dart';
import '../settings/alert_settings_controller.dart';

class PatientDashboardScreen extends ConsumerWidget {
  const PatientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardControllerProvider);

    return Scaffold(
      body: dashboardState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _buildErrorState(ref, err.toString()),
        data: (data) => ResponsiveLayout(
          mobileBody: _DashboardMobileBody(data: data),
          desktopBody: _DashboardDesktopBody(data: data),
        ),
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 64),
            const SizedBox(height: 16),
            const Text('Something went wrong', style: AppTextStyles.headline2),
            const SizedBox(height: 24),
            CustomElevatedButton(
              onPressed: () => ref.read(dashboardControllerProvider.notifier).refreshData(),
              text: 'Retry',
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardMobileBody extends ConsumerWidget {  // Change to ConsumerWidget
  final DashboardState data;
  const _DashboardMobileBody({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {  // Add WidgetRef
    final unit = ref.watch(alertSettingsProvider).displayUnit;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(data.patient),
            const SizedBox(height: 24),
            _buildIOBCard(data.insulinLogs),
            const SizedBox(height: 24),
            _buildGlucoseCard(data.latestGlucose, unit),  // Pass unit
            const SizedBox(height: 24),
            _GlucoseMonitoringSection(
              //key: ValueKey(data.history),
              readings: data.history,
              thresholds: data.thresholds,
              unit: unit,
            ),
            if (data.stats != null) ...[
              const SizedBox(height: 24),

              _buildStatsCard(data.stats!, unit),  // Pass unit
            ],
            const SizedBox(height: 24),
            _buildNutritionSection(data.recentMeals),
          ],
        ),
      ),
    );
  }
}

class _DashboardDesktopBody extends ConsumerWidget {  // Change to ConsumerWidget
  final DashboardState data;
  const _DashboardDesktopBody({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(alertSettingsProvider).displayUnit;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(data.patient),
            const SizedBox(height: 24),
            _buildIOBCard(data.insulinLogs),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _GlucoseMonitoringSection(
                        readings: data.history,
                        thresholds: data.thresholds,
                        unit: unit,
                      ),
                      if (data.stats != null) ...[
                        const SizedBox(height: 24),
                        _buildStatsCard(data.stats!, unit),  // Pass unit
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildGlucoseCard(data.latestGlucose, unit),  // Pass unit
                      const SizedBox(height: 16),
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

Widget _buildHeader(Patient? patient) {
  final name = patient?.firstName ?? 'Patient';
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Hello, $name!', style: AppTextStyles.headline1),
      const SizedBox(height: 4),
      const Text('Your daily summary', style: AppTextStyles.bodyText2),
    ],
  );
}

Widget _buildGlucoseCard(GlucoseReading? glucose, GlucoseUnit unit) {
  if (glucose == null) return const _CozyCard(child: Center(child: Text("No Data")));return _CozyCard(
    color: AppColors.skyBlue,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('LATEST GLUCOSE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              unit.formatValue(glucose.value),
              style: AppTextStyles.headline1.copyWith(fontSize: 40),
            ),
            Text(unit.displayName, style: AppTextStyles.bodyText2),
          ],
        ),
        // Pass the trend value (which is a number as a string from your API)
        _TrendIndicator(trend: glucose.trend?.toString() ?? '0'),
      ],
    ),
  );
}

Widget _buildStatsCard(DashboardStats stats, GlucoseUnit unit) {
  return _CozyCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DAILY PROGRESS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem('${stats.timeInRange.toInt()}%', 'In Range', Colors.green),
            _statItem(unit.formatValue(stats.averageGlucose), 'Avg ${unit.displayName}', AppColors.primary),
            _statItem('${stats.timeBelowRange.toInt()}%', 'Low', Colors.orange),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: stats.timeInRange / 100,
            backgroundColor: AppColors.background,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            minHeight: 8,
          ),
        )
      ],
    ),
  );
}

Widget _statItem(String value, String label, Color color) {
  return Column(
    children: [
      Text(value, style: AppTextStyles.headline2.copyWith(color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
    ],
  );
}

class _TrendIndicator extends StatelessWidget {
  final String trend; // This is the numeric string from the API (e.g., "4")

  const _TrendIndicator({required this.trend});  @override
  Widget build(BuildContext context) {
    // 1. Convert the numeric string to our Enum using your utility
    final trendEnum = GlucoseTrend.fromInt(trend);

    // 2. Determine color based on the trend
    Color iconColor;
    if (trendEnum.value >= 1 && trendEnum.value <= 3) {
      iconColor = AppColors.primary; // Rising
    } else if (trendEnum.value >= 5 && trendEnum.value <= 7) {
      iconColor = AppColors.secondary; // Falling
    } else {
      iconColor = AppColors.textSecondary; // Stable or N/A
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
            trendEnum.icon,
            size: 48,
            color: iconColor
        ),
        Text(
          trendEnum.label,
          style: TextStyle(
            fontSize: 10,
            color: iconColor.withOpacity(0.8),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

Widget _buildNutritionSection(List<RecentMeal> meals) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Recent Meals', style: AppTextStyles.headline2),
      const SizedBox(height: 12),
      _CozyCard(
        child: meals.isEmpty
            ? const Padding(padding: EdgeInsets.all(16.0), child: Text("No meals logged"))
            : Column(
                children: meals.map((meal) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(meal.description, style: AppTextStyles.bodyText1),
                  subtitle: Text('${meal.carbs} Carbs', style: AppTextStyles.bodyText2),
                  trailing: const Icon(Icons.restaurant_rounded, color: AppColors.primary),
                )).toList(),
              ),
      )
    ],
  );
}

Widget _buildIOBCard(List<LogEntryDTO> logs) {
  final iob = IOBCalculator.calculate(logs);

  if (iob.totalUnits <= 0) return const SizedBox.shrink();

  return _CozyCard(
    color: Colors.orange.shade50,
    child: Row(
      children: [
        const Icon(Icons.timer_outlined, color: Colors.orange, size: 32),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("ACTIVE INSULIN (IOB)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.orange)),
              Text("${iob.totalUnits} Units",
                  style: AppTextStyles.headline2.copyWith(color: Colors.orange.shade900)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text("CLEAR IN", style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text("${iob.remainingTime.inHours}h ${iob.remainingTime.inMinutes.remainder(60)}m",
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        )
      ],
    ),
  );
}

class _CozyCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  const _CozyCard({required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _GlucoseMonitoringSection extends StatefulWidget {
  final List<GlucoseReading> readings;
  final Map<String, dynamic>? thresholds;
  final GlucoseUnit unit;
  const _GlucoseMonitoringSection({required this.readings, required this.unit, this.thresholds});

  @override
  State<_GlucoseMonitoringSection> createState() => _GlucoseMonitoringSectionState();
}

class _GlucoseMonitoringSectionState extends State<_GlucoseMonitoringSection> {
  String _selectedRange = '24H';

  (double minX, double maxX, double interval) _getAxisDetails() {
    final now = DateTime.now();
    DateTime snappedMax;
    Duration rangeDuration;
    double intervalMs;

    const int hourInMs = 3600000;
    const int minuteInMs = 60000;

    switch (_selectedRange) {
      case '4H':
        final remainder = 30 - (now.minute % 30);
        snappedMax = now.add(Duration(minutes: remainder)).subtract(Duration(seconds: now.second, milliseconds: now.millisecond));
        rangeDuration = const Duration(hours: 4);
        intervalMs = 30 * minuteInMs.toDouble();
        break;
      case '8H':
        final remainder = 60 - now.minute;
        snappedMax = now.add(Duration(minutes: remainder)).subtract(Duration(seconds: now.second, milliseconds: now.millisecond));
        rangeDuration = const Duration(hours: 8);
        intervalMs = hourInMs.toDouble();
        break;
      case '24H':
      default:
        final remainder = 60 - now.minute;
        snappedMax = now.add(Duration(minutes: remainder)).subtract(Duration(seconds: now.second, milliseconds: now.millisecond));
        rangeDuration = const Duration(hours: 24);
        intervalMs = 4 * hourInMs.toDouble();
        break;
    }

    final maxX = snappedMax.millisecondsSinceEpoch.toDouble();
    final minX = snappedMax.subtract(rangeDuration).millisecondsSinceEpoch.toDouble();

    return (minX, maxX, intervalMs);
  }

  @override
  Widget build(BuildContext context) {
    final (minX, maxX, interval) = _getAxisDetails();

    // Add buffer for filtering (1 hour = 3600000 ms)
    final filterMaxX = maxX + (60 * 60 * 1000);

    print('📊 Total readings: ${widget.readings.length}');
    print('📊 Selected range: $_selectedRange');
    print('📊 Window: ${DateTime.fromMillisecondsSinceEpoch(minX.toInt())} to ${DateTime.fromMillisecondsSinceEpoch(maxX.toInt())}');

    if (widget.readings.isNotEmpty) {
      print('📊 READINGS RANGE: ${widget.readings.first.timestamp.toLocal()} to ${widget.readings.last.timestamp.toLocal()}');
      print('📊 LAST READING: ${widget.readings.last.timestamp.toLocal()} = ${widget.readings.last.value} mg/dL');
    }

    final spots = widget.readings
        .where((r) {
      final localMs = r.timestamp.toLocal().millisecondsSinceEpoch;
      return localMs >= minX && localMs <= maxX;
    })
        .map((r) => FlSpot(
        r.timestamp.toLocal().millisecondsSinceEpoch.toDouble(),
        widget.unit.convertFromMgdL(r.value)
    ))
        .toList();

    spots.sort((a, b) => a.x.compareTo(b.x));

    print('📊 SPOTS AFTER FILTER: ${spots.length}');
    if (spots.isNotEmpty) {
      print('📊 SPOTS RANGE: ${DateTime.fromMillisecondsSinceEpoch(spots.first.x.toInt())} to ${DateTime.fromMillisecondsSinceEpoch(spots.last.x.toInt())}');
      print('📊 LAST SPOT: ${DateTime.fromMillisecondsSinceEpoch(spots.last.x.toInt())} = ${spots.last.y}');
    }
    print('📊 ========================================\n');

    final List<List<FlSpot>> segments = [];
    if (spots.isNotEmpty) {
      List<FlSpot> currentSegment = [spots[0]];
      for (int i = 1; i < spots.length; i++) {
        // Break line if gap is more than 2 hours (2 * 60 * 60 * 1000 ms)
        if (spots[i].x - spots[i - 1].x > 2 * 60 * 60 * 1000) {
          segments.add(currentSegment);
          currentSegment = [spots[i]];
        } else {
          currentSegment.add(spots[i]);
        }
      }
      segments.add(currentSegment);
    }

    if (spots.isNotEmpty) {
      print('🔍 First spot: x=${DateTime.fromMillisecondsSinceEpoch(spots.first.x.toInt())}, y=${spots.first.y}');
      print('🔍 Last spot: x=${DateTime.fromMillisecondsSinceEpoch(spots.last.x.toInt())}, y=${spots.last.y}');
    }


    final maxY = widget.unit == GlucoseUnit.mgdL ? 300.0 : 22.0;

    final thresholds = widget.thresholds;

    double? getVal(String key) {
      if (thresholds == null || thresholds[key] == null) return null;
      // Convert from mg/dL (stored in DB) to current display unit
      final rawValue = double.tryParse(thresholds[key].toString()) ?? 0.0;
      return widget.unit.convertFromMgdL(rawValue);
    }

    final low = getVal('lowThreshold');
    final high = getVal('highThreshold');
    final critLow = getVal('criticalLowThreshold');
    final critHigh = getVal('criticalHighThreshold');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Glucose Monitoring', style: AppTextStyles.headline2),
        const SizedBox(height: 12),
        Row(
          children: ['4H', '8H', '24H'].map((label) {
            final isSelected = _selectedRange == label;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: InkWell(
                onTap: () => setState(() => _selectedRange = label),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        _CozyCard(
          child: SizedBox(
            height: 260,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((spot) {
                        final dateTime = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                        final formattedTime = DateFormat('HH:mm').format(dateTime);
                        final formattedValue = widget.unit.formatValue(widget.unit == GlucoseUnit.mgdL ? spot.y : spot.y * 18.0);
                        return LineTooltipItem(
                          '$formattedValue ${widget.unit.displayName}\n$formattedTime',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40, // 1. Allocates 40px width for the Y-axis column
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value > maxY) return const SizedBox.shrink(); // Hide 0 and outliers

                        return SideTitleWidget(
                          meta: meta,
                          space: 12, // 2. Pushes the text 12px away from the chart line (to the left)
                          child: Text(
                            value.toInt().toString(), // Format this if you need decimals for mmol/L
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: interval,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        if (value < minX || value > maxX) return const SizedBox.shrink();
                        final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                        return SideTitleWidget(
                          meta: meta,
                          space: 20,
                          child: Text(
                              DateFormat('HH:mm').format(date),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: minX,
                maxX: maxX,
                minY: 0,
                maxY: maxY,
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    if (critLow != null && critHigh != null) ...[
                      HorizontalLine(
                        y: critLow,
                        color: Colors.red.withOpacity(0.5),
                        strokeWidth: 2,
                        dashArray: [5, 5],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.bottomRight,
                          labelResolver: (line) => 'Crit Low',
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                      HorizontalLine(
                        y: critHigh,
                        color: Colors.yellow.withOpacity(0.8),
                        strokeWidth: 2,
                        dashArray: [5, 5],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          labelResolver: (line) => 'Crit High',
                          style: const TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                      ),
                    ],
                  ],
                ),
                lineBarsData: segments.map((segment) => LineChartBarData(
                  spots: segment,
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: 3,
                      color: AppColors.primary,
                      strokeWidth: 0.5,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withOpacity(0.1),
                  ),
                )).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
