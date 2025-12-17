import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/theme/app_text_styles.dart';
import 'package:diabetes_management_system/utils/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:fl_chart/fl_chart.dart';

class PatientDashboardScreen extends StatelessWidget {
  const PatientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Uses ResponsiveLayout for different screen sizes
    return ResponsiveLayout(
      mobileBody: _DashboardMobileBody(),
      desktopBody: _DashboardDesktopBody(),
    );
  }
}

// --- RESPONSIVE LAYOUTS ---

class _DashboardMobileBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 24),
            _buildGlucoseCard(),
            SizedBox(height: 24),
            _buildNutritionSection(),
            SizedBox(height: 24),
            _GlucoseMonitoringSection(),
          ],
        ),
      ),
    );
  }
}

class _DashboardDesktopBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _GlucoseMonitoringSection(),
                ),
                SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildGlucoseCard(),
                      SizedBox(height: 16),
                      _buildNutritionSection(),
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

Widget _buildHeader() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Hello, Jessica', style: AppTextStyles.headline1),
      SizedBox(height: 4),
      Text('Latest Activity', style: AppTextStyles.bodyText2),
    ],
  );
}

Widget _buildGlucoseCard() {
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
              SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('5.8', style: AppTextStyles.headline1.copyWith(fontSize: 32)),
                  SizedBox(width: 8),
                  Text('mmol/L', style: AppTextStyles.bodyText1),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.arrow_upward, color: Colors.red, size: 20),
              SizedBox(width: 4),
              Text('+0.2', style: AppTextStyles.bodyText1.copyWith(color: Colors.red)),
            ],
          )
        ],
      ),
    ),
  );
}

Widget _buildNutritionSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Today\'s Nutrition', style: AppTextStyles.headline2),
      SizedBox(height: 12),
      Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            ListTile(
              title: Text('Oatmeal with Berries', style: AppTextStyles.bodyText1),
              subtitle: Text('45g carbs', style: AppTextStyles.bodyText2),
              trailing: Text('GL: 25', style: AppTextStyles.bodyText1),
            ),
            Divider(height: 1),
            ListTile(
              title: Text('Grilled Chicken Salad', style: AppTextStyles.bodyText1),
              subtitle: Text('15g carbs', style: AppTextStyles.bodyText2),
              trailing: Text('GL: 5', style: AppTextStyles.bodyText1),
            ),
          ],
        ),
      )
    ],
  );
}

class _GlucoseMonitoringSection extends StatefulWidget {
  @override
  __GlucoseMonitoringSectionState createState() => __GlucoseMonitoringSectionState();
}

class __GlucoseMonitoringSectionState extends State<_GlucoseMonitoringSection> {
  List<FlSpot> _allData = [];
  List<FlSpot> _visibleData = [];
  String _selectedRange = '24H';

  @override
  void initState() {
    super.initState();
    _loadGlucoseData();
  }

  Future<void> _loadGlucoseData() async {
    final rawData = await rootBundle.loadString('assets/data/Dexcom_data.csv');
    List<List<dynamic>> csvTable = CsvToListConverter().convert(rawData);

    List<FlSpot> spots = [];
    final targetDay = DateTime(2025, 11, 22);

    for (var i = 1; i < csvTable.length; i++) {
      final row = csvTable[i];
      try {
        final timestamp = DateTime.parse(row[1]);
        if (timestamp.year == targetDay.year && timestamp.month == targetDay.month && timestamp.day == targetDay.day) {
          final hour = timestamp.hour + (timestamp.minute / 60.0);
          final glucoseMgDl = double.parse(row[7].toString());
          final glucoseMmolL = glucoseMgDl / 18.0;
          spots.add(FlSpot(hour, glucoseMmolL));
        }
      } catch (e) {
        // print('Error parsing row: $row. Error: $e');
      }
    }

    spots.sort((a, b) => a.x.compareTo(b.x));

    setState(() {
      _allData = spots;
      _updateVisibleData();
    });
  }

  void _updateVisibleData() {
    if (_allData.isEmpty) {
      _visibleData = [];
      return;
    }

    final now = _allData.map((spot) => spot.x).reduce((a, b) => a > b ? a : b);
    double minHour = 0;

    switch (_selectedRange) {
      case '4H':
        minHour = now - 4;
        break;
      case '8H':
        minHour = now - 8;
        break;
      case '24H':
      default:
        minHour = 0;
        break;
    }

    setState(() {
      _visibleData = _allData.where((spot) => spot.x >= minHour).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Glucose Monitoring', style: AppTextStyles.headline2),
        SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: ['4H', '8H', '24H'].map((label) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: _selectedRange == label,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedRange = label;
                          _updateVisibleData();
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: _allData.isEmpty
              ? Center(child: CircularProgressIndicator())
              : LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            // Show fewer labels on the Y-axis
                            if (value % 5 == 0) {
                              return Text('${value.toInt()}', style: AppTextStyles.bodyText2, textAlign: TextAlign.left);
                            }
                            return Text('');
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: 4, // Show a label every 4 hours
                          getTitlesWidget: (value, meta) => Text('${value.toInt()}:00', style: AppTextStyles.bodyText2),
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: true, border: Border.all(color: AppColors.primary.withOpacity(0.2))),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _visibleData,
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.1)),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
