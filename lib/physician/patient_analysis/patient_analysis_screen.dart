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
    return Row(
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
        const SizedBox(width: 8),
        Expanded(
            child: _SummaryTile(
                title: 'CV',
                value: state.cv,
                subtitle: 'Stability (Var)',
                color: Colors.indigoAccent)),
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

class _GlucoseTrendsSection extends StatelessWidget {
  final PatientAnalysisState state;
  const _GlucoseTrendsSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final mealLines = state.foodLogs.map((log) {
      final hour = log.timestamp.toLocal().hour +
          (log.timestamp.toLocal().minute / 60.0);

      return VerticalLine(
        x: hour,
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
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('24-Hour Glucose Profile', style: AppTextStyles.headline2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4)),
              child: Text("Avg: ${state.averageGlucose.toInt()} mg/dL",
                  style: AppTextStyles.bodyText2.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.bold)),
            )
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
          child: state.glucoseSpots.isEmpty
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
                verticalInterval: 4,
                getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade100, strokeWidth: 1),
                getDrawingVerticalLine: (value) =>
                    FlLine(color: Colors.grey.shade100, strokeWidth: 1),
              ),
              titlesData: const FlTitlesData(
                rightTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 4,
                    getTitlesWidget: _bottomTitles,
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
              minX: 0,
              maxX: 24,
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
                  if (state.alertSettings != null) ...[
                    HorizontalLine(
                      y: state.alertSettings!.criticalLowThreshold * 18.0,
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
                      y: state.alertSettings!.criticalHighThreshold * 18.0,
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
                verticalLines: mealLines,
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: state.glucoseSpots,
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
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
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _bottomTitles(double value, TitleMeta meta) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text('${value.toInt()}:00',
          style: AppTextStyles.bodyText2.copyWith(
              color: Colors.grey, fontSize: 10)),
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
