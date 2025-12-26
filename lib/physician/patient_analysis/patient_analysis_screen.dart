import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/theme/app_text_styles.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PatientAnalysisScreen extends StatelessWidget {
  const PatientAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('John Doe', style: AppTextStyles.headline2),
        actions: [
          IconButton(icon: Icon(Icons.calendar_today, color: AppColors.primary), onPressed: (){}),
          IconButton(icon: Icon(Icons.download, color: AppColors.primary), onPressed: (){}),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ClinicalSummarySection(),
              SizedBox(height: 24),
              _GlucoseTrendsSection(),
              SizedBox(height: 24),
              _DetailedLogsSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClinicalSummarySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SummaryTile(title: 'TIR', value: '72%', subtitle: 'Target (70-180)', color: Colors.green)),
        SizedBox(width: 8),
        Expanded(child: _SummaryTile(title: 'TBR', value: '4%', subtitle: 'Low (<70)', color: AppColors.error)),
        SizedBox(width: 8),
        Expanded(child: _SummaryTile(title: 'CV', value: '33%', subtitle: 'Stability (Var)', color: Colors.indigoAccent)),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _SummaryTile({required this.title, required this.value, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4)),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(title, style: AppTextStyles.bodyText2.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[600])),
          SizedBox(height: 8),
          Text(value, style: AppTextStyles.headline1.copyWith(color: color, fontSize: 28)),
          SizedBox(height: 4),
          // Replaced caption with bodyText2 and reduced font size manually
          Text(subtitle, style: AppTextStyles.bodyText2.copyWith(fontSize: 10), textAlign: TextAlign.center, maxLines: 1),
        ],
      ),
    );
  }
}

class _GlucoseTrendsSection extends StatelessWidget {
  // Hardcoded dummy data to simulate a daily curve
  final List<FlSpot> dummySpots = [
    FlSpot(0, 120), FlSpot(2, 110), FlSpot(4, 90), FlSpot(6, 130), // Morning rise
    FlSpot(8, 160), FlSpot(9, 185), FlSpot(11, 140), // Breakfast spike
    FlSpot(13, 110), FlSpot(15, 95), FlSpot(17, 105), // Afternoon dip
    FlSpot(19, 210), FlSpot(21, 150), FlSpot(23, 130), // Dinner spike & settle
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('24-Hour Glucose Profile', style: AppTextStyles.headline2),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text("Avg: 142 mg/dL", style: AppTextStyles.bodyText2.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        SizedBox(height: 16),
        Container(
          height: 320,
          padding: EdgeInsets.only(right: 16, top: 16, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: 50,
                verticalInterval: 4,
                getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: 4,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        // Replaced caption
                        child: Text('${value.toInt()}:00', style: AppTextStyles.bodyText2.copyWith(color: Colors.grey, fontSize: 10)),
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
                      if (value == 0) return Container();
                      // Replaced caption
                      return Text('${value.toInt()}', style: AppTextStyles.bodyText2.copyWith(color: Colors.grey, fontSize: 10));
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0, maxX: 24, minY: 40, maxY: 300,

              // This is the green "Target Range" background
              extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(y: 70, color: Colors.green.withOpacity(0.3), strokeWidth: 1, dashArray: [5,5]),
                    HorizontalLine(y: 180, color: Colors.green.withOpacity(0.3), strokeWidth: 1, dashArray: [5,5]),
                  ]
              ),

              lineBarsData: [
                LineChartBarData(
                  spots: dummySpots,
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.1),
                      gradient: LinearGradient(
                        colors: [AppColors.primary.withOpacity(0.2), AppColors.primary.withOpacity(0.0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
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

class _DetailedLogsSection extends StatefulWidget {
  @override
  __DetailedLogsSectionState createState() => __DetailedLogsSectionState();
}

class __DetailedLogsSectionState extends State<_DetailedLogsSection> with SingleTickerProviderStateMixin {
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
              Tab(text: 'Logbook Events'),
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
              _LogbookTab(),
              _MedicationTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _LogbookTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Hardcoded Extended Data
    final logs = [
      {'time': '02:30', 'type': 'ALERT', 'title': 'Urgent Low', 'value': '55 mg/dL', 'color': AppColors.error, 'icon': Icons.warning_amber_rounded},
      {'time': '08:00', 'type': 'CARB', 'title': 'Breakfast', 'value': '45g Carbs', 'color': Colors.orange, 'icon': Icons.restaurant},
      {'time': '08:15', 'type': 'INSULIN', 'title': 'Bolus', 'value': '6.0 U', 'color': Colors.blue, 'icon': Icons.water_drop},
      {'time': '12:30', 'type': 'CARB', 'title': 'Lunch', 'value': '60g Carbs', 'color': Colors.orange, 'icon': Icons.lunch_dining},
      {'time': '12:45', 'type': 'INSULIN', 'title': 'Bolus', 'value': '8.5 U', 'color': Colors.blue, 'icon': Icons.water_drop},
      {'time': '19:00', 'type': 'CARB', 'title': 'Dinner', 'value': '85g Carbs', 'color': Colors.orange, 'icon': Icons.dinner_dining},
      {'time': '19:15', 'type': 'INSULIN', 'title': 'Bolus', 'value': '12.0 U', 'color': Colors.blue, 'icon': Icons.water_drop},
      {'time': '22:00', 'type': 'INSULIN', 'title': 'Basal (Lantus)', 'value': '24.0 U', 'color': Colors.purple, 'icon': Icons.nightlight_round},
    ];

    return ListView.separated(
      itemCount: logs.length,
      separatorBuilder: (c, i) => Divider(height: 1),
      itemBuilder: (context, index) {
        final log = logs[index];
        return ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (log['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(log['icon'] as IconData, color: log['color'] as Color, size: 20),
          ),
          title: Text(log['title'] as String, style: AppTextStyles.bodyText1.copyWith(fontWeight: FontWeight.bold)),
          // Replaced caption
          subtitle: Text(log['time'] as String, style: AppTextStyles.bodyText2),
          trailing: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(20)
            ),
            child: Text(log['value'] as String, style: AppTextStyles.bodyText2.copyWith(fontWeight: FontWeight.w600, color: Colors.black87)),
          ),
        );
      },
    );
  }
}

class _MedicationTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader('Basal Profile'),
          _MedicationItem(title: 'Insulin Type', value: 'Lantus (Glargine)'),
          _MedicationItem(title: 'Daily Dose', value: '24.0 Units'),
          _MedicationItem(title: 'Schedule', value: 'Once Daily @ 22:00'),
          Divider(height: 32),
          _SectionHeader('Bolus Calculator'),
          _MedicationItem(title: 'Insulin Type', value: 'Novolog (Aspart)'),
          _MedicationItem(title: 'Insulin-to-Carb (ICR)', value: '1:10 g'),
          _MedicationItem(title: 'Sensitivity (ISF)', value: '1:30 mg/dL'),
          _MedicationItem(title: 'Target Glucose', value: '100 mg/dL'),
        ],
      ),
    );
  }

  Widget _SectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      // Replaced caption with bodyText2
      child: Text(title.toUpperCase(), style: AppTextStyles.bodyText2.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
    );
  }

  Widget _MedicationItem({required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.bodyText1),
          Text(value, style: AppTextStyles.bodyText2.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}