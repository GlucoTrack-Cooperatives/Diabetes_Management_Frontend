import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/theme/app_text_styles.dart';
import 'package:flutter/material.dart';

class PatientAnalysisScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('John Doe', style: AppTextStyles.headline2),
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
        Expanded(child: _SummaryTile(title: 'TIR', value: '72%', subtitle: '70-180', color: Colors.green)),
        SizedBox(width: 8),
        Expanded(child: _SummaryTile(title: 'TBR', value: '5%', subtitle: '<70', color: AppColors.error)),
        SizedBox(width: 8),
        Expanded(child: _SummaryTile(title: 'CV', value: '38%', subtitle: 'Var', color: Colors.orange)),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _SummaryTile({Key? key, required this.title, required this.value, required this.subtitle, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(title, style: AppTextStyles.bodyText2.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(value, style: AppTextStyles.headline1.copyWith(color: color, fontSize: 24)),
          SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.bodyText2),
        ],
      ),
    );
  }
}

class _GlucoseTrendsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('24-Hour Overview', style: AppTextStyles.headline2),
        SizedBox(height: 12),
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Stack(
            children: [
              // Mock Target Range Zone
              Positioned(
                top: 100,
                left: 0,
                right: 0,
                height: 100,
                child: Container(color: Colors.green.withOpacity(0.1)),
              ),
              Center(child: Text('Interactive Line Chart Placeholder', style: AppTextStyles.bodyText2)),
              // Mock Event Markers
              Positioned(
                top: 80,
                left: 100,
                child: Icon(Icons.water_drop, color: Colors.blue, size: 20), // Insulin
              ),
              Positioned(
                top: 220,
                left: 250,
                child: Icon(Icons.restaurant, color: Colors.orange, size: 20), // Meal
              ),
            ],
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
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'Logbook'),
            Tab(text: 'Medication'),
          ],
        ),
        SizedBox(height: 12),
        SizedBox(
          height: 300,
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
    final logs = [
      {'time': '2:30 AM', 'title': 'Glucose', 'value': '55 mg/dL', 'color': AppColors.error},
      {'time': '8:00 AM', 'title': 'Carbs', 'value': 'Oatmeal (45g)', 'color': Colors.orange},
      {'time': '8:15 AM', 'title': 'Insulin', 'value': '6u Rapid', 'color': Colors.blue},
    ];

    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return ListTile(
          leading: Text(log['time'] as String, style: AppTextStyles.bodyText2),
          title: Text(log['title'] as String, style: AppTextStyles.bodyText1.copyWith(fontWeight: FontWeight.bold)),
          trailing: Text(log['value'] as String, style: AppTextStyles.bodyText1.copyWith(color: log['color'] as Color)),
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
          _MedicationItem(title: 'Basal Insulin', value: 'Lantus (20u at 9 PM)'),
          Divider(),
          _MedicationItem(title: 'Insulin-to-Carb Ratio (ICR)', value: '1:10'),
          Divider(),
          _MedicationItem(title: 'Insulin Sensitivity Factor (ISF)', value: '1:30'),
        ],
      ),
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
