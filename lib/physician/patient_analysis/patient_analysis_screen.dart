import 'package:diabetes_management_system/physician/appointments/patient_appointments_screen.dart';
import 'package:diabetes_management_system/physician/patient_analysis/patient_analysis_controller.dart';
import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/theme/app_text_styles.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PatientAnalysisScreen extends ConsumerWidget {
  final String patientId;
  final String patientName;

  const PatientAnalysisScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(patientAnalysisControllerProvider(patientId));

    return Scaffold(
      appBar: AppBar(
        title: Text(patientName, style: AppTextStyles.headline2),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_month, color: AppColors.primary),
            tooltip: 'Appointments & Tests',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PatientAppointmentsScreen(
                    patientId: patientId,
                    patientName: patientName,
                  ),
                ),
              );
            },
          ),
          IconButton(
              icon: Icon(Icons.refresh, color: AppColors.primary),
              onPressed: () {
                ref
                    .read(patientAnalysisControllerProvider(patientId).notifier)
                    .loadData();
              }),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ClinicalSummarySection(state: state),
              const SizedBox(height: 24),
              _GlucoseTrendsSection(state: state),
              const SizedBox(height: 24),
              _DetailedLogsSection(state: state),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClinicalSummarySection extends StatelessWidget {
  final PatientAnalysisState state;
  const _ClinicalSummarySection({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _SummaryTile(
                    title: 'TIR',
                    value: state.tir,
                    subtitle: 'Target (70-180)',
                    color: Colors.green)),
            const SizedBox(width: 8),
            Expanded(
                child: _SummaryTile(
                    title: 'TBR',
                    value: state.tbr,
                    subtitle: 'Low (<70)',
                    color: AppColors.error)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: _SummaryTile(
                    title: 'CV',
                    value: state.cv,
                    subtitle: 'Stability (Var)',
                    color: Colors.indigoAccent)),
            const SizedBox(width: 8),
            Expanded(
                child: _SummaryTile(
                    title: 'GMI',
                    value: state.gmi,
                    subtitle: 'Est. A1c',
                    color: Colors.purple)),
          ],
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _SummaryTile(
      {required this.title,
        required this.value,
        required this.subtitle,
        required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(title,
              style: AppTextStyles.bodyText2.copyWith(
                  fontWeight: FontWeight.bold, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(value,
              style: AppTextStyles.headline1.copyWith(color: color, fontSize: 28)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: AppTextStyles.bodyText2.copyWith(fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 1),
        ],
      ),
    );
  }
}

class _GlucoseTrendsSection extends StatefulWidget {
  final PatientAnalysisState state;
  const _GlucoseTrendsSection({required this.state});

  @override
  State<_GlucoseTrendsSection> createState() => _GlucoseTrendsSectionState();
}

class _GlucoseTrendsSectionState extends State<_GlucoseTrendsSection> {
  String _selectedRange = '24H';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startTime = now.subtract(const Duration(hours: 24));

    double calculateRelativeX(DateTime timestamp) {
      final difference = timestamp.difference(startTime);
      return difference.inMinutes / 60.0;
    }

    double minX = 0;
    double maxX = 24;
    double xInterval = 4; // Grid lines every 4 hours

    if (_selectedRange == '4H') {
      minX = 20; // Show from hour 20 to 24 (the last 4 hours)
      maxX = 24;
      xInterval = 1; // Grid lines every 1 hour for better detail
    }

    final mealLines = widget.state.foodLogs.map((log) {
      final x = calculateRelativeX(log.timestamp.toLocal());
      if (x < minX || x > maxX) return null;

      return VerticalLine(
        x: x,
        color: Colors.orange.withOpacity(0.4),
        strokeWidth: 2,
        dashArray: [4, 4],
        label: VerticalLineLabel(
          show: true,
          alignment: Alignment.topRight,
          padding: const EdgeInsets.only(top: 10),
          labelResolver: (line) => '🍴',
        ),
      );
    }).whereType<VerticalLine>().toList();

    final insulinLines = widget.state.insulinLogs.map((log) {
      final x = calculateRelativeX(log.timestamp.toLocal());
      if (x < minX || x > maxX) return null;

      return VerticalLine(
        x: x,
        color: Colors.blue.withOpacity(0.4),
        strokeWidth: 2,
        dashArray: [4, 4],
        label: VerticalLineLabel(
          show: true,
          alignment: Alignment.topRight,
          padding: const EdgeInsets.only(top: 35), // Offset slightly below meal icon
          labelResolver: (line) => '💉',
        ),
      );
    }).whereType<VerticalLine>().toList();

    final List<List<FlSpot>> segments = [];
    if (widget.state.glucoseSpots.isNotEmpty) {
      final sortedSpots = List<FlSpot>.from(widget.state.glucoseSpots)
        ..sort((a, b) => a.x.compareTo(b.x));
      List<FlSpot> currentSegment = [sortedSpots[0]];
      for (int i = 1; i < sortedSpots.length; i++) {
        // Break line if gap is more than 2 hours (x is in hours here)
        if (sortedSpots[i].x - sortedSpots[i - 1].x > 2.0) {
          segments.add(currentSegment);
          currentSegment = [sortedSpots[i]];
        } else {
          currentSegment.add(sortedSpots[i]);
        }
      }
      segments.add(currentSegment);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Header Row with Toggle ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Glucose Profile', style: AppTextStyles.headline2),
            // Toggle Buttons
            Row(
              children: ['4H', '24H'].map((label) {
                final isSelected = _selectedRange == label;
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: InkWell(
                    onTap: () => setState(() => _selectedRange = label),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 450,
          padding: const EdgeInsets.only(right: 16, top: 16, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
            ],
          ),
          child: widget.state.glucoseSpots.isEmpty
              ? Center(
              child: Text("No glucose data for the last 24h",
                  style: AppTextStyles.bodyText2))
              : LineChart(
            LineChartData(
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: 50,
                verticalInterval: xInterval,
                getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade100, strokeWidth: 1),
                getDrawingVerticalLine: (value) =>
                    FlLine(color: Colors.grey.shade100, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                rightTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 4,
                    getTitlesWidget: (value, meta) {
                      if (value < minX || value > maxX) return const SizedBox.shrink();
                      return _bottomTitles(value, meta, startTime);
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 50,
                    reservedSize: 30,
                    getTitlesWidget: _leftTitles,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: minX,
              maxX: maxX,
              minY: 0,
              maxY: 350,
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                      y: 70,
                      color: Colors.green.withOpacity(0.3),
                      strokeWidth: 1,
                      dashArray: [5, 5]),
                  HorizontalLine(
                      y: 180,
                      color: Colors.green.withOpacity(0.3),
                      strokeWidth: 1,
                      dashArray: [5, 5]),
                  if (widget.state.alertSettings != null) ...[
                    HorizontalLine(
                      y: widget.state.alertSettings!.criticalLowThreshold * 18.0,
                      color: Colors.red.withOpacity(0.6),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.bottomRight,
                        labelResolver: (line) => 'Crit Low',
                        style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                    HorizontalLine(
                      y: widget.state.alertSettings!.criticalHighThreshold * 18.0,
                      color: Colors.yellow.shade700,
                      strokeWidth: 2,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        labelResolver: (line) => 'Crit High',
                        style: TextStyle(fontSize: 10, color: Colors.yellow.shade900, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
                verticalLines: [...mealLines, ...insulinLines],
              ),
              lineBarsData: segments.map((segment) => LineChartBarData(
                spots: segment,
                isCurved: true,
                color: AppColors.primary,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                    radius: 3,
                    color: AppColors.primary,
                    strokeWidth: 1.5,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withOpacity(0.1),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.2),
                        AppColors.primary.withOpacity(0.0)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )),
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _bottomTitles(double value, TitleMeta meta, DateTime startTime) {
    final timeForLabel = startTime.add(Duration(minutes: (value * 60).toInt()));
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        DateFormat('HH:mm').format(timeForLabel),
        style: AppTextStyles.bodyText2.copyWith(color: Colors.grey, fontSize: 10),
      ),
    );
  }

  static Widget _leftTitles(double value, TitleMeta meta) {
    if (value == 0) return Container();
    return Text('${value.toInt()}',
        style: AppTextStyles.bodyText2
            .copyWith(color: Colors.grey, fontSize: 10));
  }
}

class _DetailedLogsSection extends StatefulWidget {
  final PatientAnalysisState state;
  const _DetailedLogsSection({required this.state});

  @override
  __DetailedLogsSectionState createState() => __DetailedLogsSectionState();
}

class __DetailedLogsSectionState extends State<_DetailedLogsSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            tabs: const [
              Tab(text: 'Insulin Logs'),
              Tab(text: 'Meal Logs'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildInsulinList(),
              _buildMealList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsulinList() {
    if (widget.state.insulinLogs.isEmpty) {
      return const Center(child: Text("No insulin logs today"));
    }
    return ListView.builder(
      itemCount: widget.state.insulinLogs.length,
      itemBuilder: (context, index) {
        final log = widget.state.insulinLogs[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.vaccines, color: Colors.blue),
            title: Text(log.description),
            subtitle: Text(DateFormat('HH:mm').format(log.timestamp)),
          ),
        );
      },
    );
  }

  Widget _buildMealList() {
    if (widget.state.foodLogs.isEmpty) {
      return const Center(child: Text("No meal logs today"));
    }
    return ListView.builder(
      itemCount: widget.state.foodLogs.length,
      itemBuilder: (context, index) {
        final log = widget.state.foodLogs[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.restaurant, color: Colors.orange),
            title: Text('${log.carbs ?? '0'}g Carbs'),
            subtitle: Text(DateFormat('HH:mm').format(log.timestamp)),
          ),
        );
      },
    );
  }
}
