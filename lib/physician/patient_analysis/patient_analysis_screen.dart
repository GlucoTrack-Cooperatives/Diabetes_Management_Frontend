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
              SizedBox(height: 24),
              _GlucoseTrendsSection(state: state),
              SizedBox(height: 24),
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
        SizedBox(width: 8),
        Expanded(
            child: _SummaryTile(
                title: 'TBR',
                value: state.tbr,
                subtitle: 'Low (<70)',
                color: AppColors.error)),
        SizedBox(width: 8),
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
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4)),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(title,
              style: AppTextStyles.bodyText2.copyWith(
                  fontWeight: FontWeight.bold, color: Colors.grey[600])),
          SizedBox(height: 8),
          Text(value,
              style: AppTextStyles.headline1.copyWith(color: color, fontSize: 28)),
          SizedBox(height: 4),
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
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4)),
              child: Text("Avg: ${state.averageGlucose.toInt()} mg/dL",
                  style: AppTextStyles.bodyText2.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        SizedBox(height: 16),
        Container(
          height: 450,
          padding: EdgeInsets.only(right: 16, top: 16, bottom: 8),
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
              // FIX 1: Enable clipping to stop drawing outside the box
              clipData: FlClipData.all(),

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
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text('${value.toInt()}:00',
                            style: AppTextStyles.bodyText2.copyWith(
                                color: Colors.grey, fontSize: 10)),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 50,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      // Hide the '0' label if it overlaps
                      if (value == 0) return Container();
                      return Text('${value.toInt()}',
                          style: AppTextStyles.bodyText2
                              .copyWith(color: Colors.grey, fontSize: 10));
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 24,
              // FIX 2: Lower the minimum Y to 0 so low values fit inside
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
                  dotData: FlDotData(show: false),
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
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            padding: EdgeInsets.all(4),
            tabs: [
              Tab(text: 'Food Logbook'),
              Tab(text: 'Medication Settings'),
            ],
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            children: [
              _LogbookTab(foodLogs: widget.state.foodLogs),
              _MedicationTab(settings: widget.state.derivedInsulinSettings),
            ],
          ),
        ),
      ],
    );
  }
}

class _LogbookTab extends StatelessWidget {
  final List<dynamic> foodLogs;
  const _LogbookTab({required this.foodLogs});

  @override
  Widget build(BuildContext context) {
    if (foodLogs.isEmpty) {
      return Center(
          child: Text("No food logs found for this period",
              style: AppTextStyles.bodyText2));
    }
    return ListView.separated(
      itemCount: foodLogs.length,
      separatorBuilder: (c, i) => Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        final log = foodLogs[index];
        final timeStr = DateFormat('HH:mm').format(log.timestamp.toLocal());

        final nutritionalInfo = [
          if (log.carbs != null) log.carbs,
          if (log.calories != null) log.calories
        ].join(' • ');

        return ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.restaurant_menu, color: Colors.orange, size: 24),
          ),
          title: Text(log.description,
              style:
              AppTextStyles.bodyText1.copyWith(fontWeight: FontWeight.bold)),
          subtitle: Text(nutritionalInfo,
              style: AppTextStyles.bodyText2.copyWith(color: Colors.grey[600])),
          trailing: Text(timeStr,
              style: AppTextStyles.bodyText2.copyWith(color: AppColors.primary)),
        );
      },
    );
  }
}

class _MedicationTab extends StatelessWidget {
  final Map<String, String> settings;
  const _MedicationTab({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader('Detected Insulin Profile'),
          _MedicationItem(
              title: 'Basal Insulin', value: settings['Basal'] ?? 'Unknown'),
          _MedicationItem(
              title: 'Bolus Insulin', value: settings['Bolus'] ?? 'Unknown'),
        ],
      ),
    );
  }
}

Widget _SectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
    child: Text(title.toUpperCase(),
        style: AppTextStyles.bodyText2.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.grey)),
  );
}

Widget _MedicationItem({required String title, required String value}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.bodyText1),
        Text(value,
            style: AppTextStyles.bodyText2.copyWith(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}