import 'package:diabetes_management_system/theme/app_text_styles.dart';
import 'package:diabetes_management_system/utils/responsive_layout.dart';
import 'package:diabetes_management_system/widgets/custom_elevated_button.dart';
import 'package:diabetes_management_system/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';

class FoodInsulinLogScreen extends StatelessWidget {
  const FoodInsulinLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The Scaffold is provided by PatientMainScreen, so we just build the content.
    return ResponsiveLayout(
      mobileBody: _MobileLogBody(),
      desktopBody: _DesktopLogBody(),
    );
  }
}

// --- RESPONSIVE LAYOUTS ---

class _MobileLogBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _LogInputSection(),
            SizedBox(height: 24),
            _RecentLogsList(),
          ],
        ),
      ),
    );
  }
}

class _DesktopLogBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _LogInputSection(),
          ),
          SizedBox(width: 24),
          Expanded(
            flex: 1,
            child: _RecentLogsList(),
          ),
        ],
      ),
    );
  }
}

// --- MAIN UI SECTIONS ---

class _LogInputSection extends StatefulWidget {
  @override
  __LogInputSectionState createState() => __LogInputSectionState();
}

class __LogInputSectionState extends State<_LogInputSection> with SingleTickerProviderStateMixin {
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
        TabBar(
          controller: _tabController,
          tabs: [Tab(text: 'Meal Log'), Tab(text: 'Insulin Log')],
        ),
        SizedBox(height: 16),
        SizedBox(
          // Give the TabBarView a defined height, or use an Expanded in a Column
          height: 400, 
          child: TabBarView(
            controller: _tabController,
            children: [
              _MealLogView(),
              _InsulinLogView(),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentLogsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Mock data for the recent logs
    final List<Map<String, String>> mockLogs = [
      {'title': '6 Units Rapid', 'time': '12:45 PM'},
      {'title': '50g Carbs - Oatmeal', 'time': '12:30 PM'},
      {'title': '22 Units Basal', 'time': 'Yesterday, 9:00 PM'},
      {'title': '15g Carbs - Apple', 'time': 'Yesterday, 3:15 PM'},
      {'title': '5 Units Rapid', 'time': 'Yesterday, 1:00 PM'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Logs', style: AppTextStyles.headline2),
        SizedBox(height: 12),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: mockLogs.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(mockLogs[index]['title']!, style: AppTextStyles.bodyText1),
                trailing: Text(mockLogs[index]['time']!, style: AppTextStyles.bodyText2),
              );
            },
            separatorBuilder: (context, index) => Divider(height: 1),
          ),
        ),
      ],
    );
  }
}

// --- TAB VIEWS ---

class _MealLogView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextFormField(labelText: 'Describe your meal...', controller: TextEditingController()),
          SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: Icon(Icons.qr_code_scanner), label: Text('Barcode'))),
            SizedBox(width: 16),
            Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: Icon(Icons.camera_alt_outlined), label: Text('Photo'))),
          ]),
          SizedBox(height: 24),
          CustomTextFormField(labelText: 'Carbohydrate Grams', controller: TextEditingController(), keyboardType: TextInputType.number),
          SizedBox(height: 16),
          CustomTextFormField(labelText: 'Calories (Optional)', controller: TextEditingController(), keyboardType: TextInputType.number),
          SizedBox(height: 24),
          CustomElevatedButton(onPressed: () {}, text: 'Log Meal'),
        ],
      ),
    );
  }
}

class _InsulinLogView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            items: ['Rapid-acting', 'Basal'].map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: (_) {},
            decoration: InputDecoration(labelText: 'Insulin Type', border: OutlineInputBorder()),
          ),
          SizedBox(height: 16),
          CustomTextFormField(labelText: 'Dose (Units)', controller: TextEditingController(), keyboardType: TextInputType.number),
          SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: Icon(Icons.calculate_outlined), 
              label: Text('Use Correction Calculator'),
              onPressed: () {},
            ),
          ),
          SizedBox(height: 24),
          CustomElevatedButton(onPressed: () {}, text: 'Log Dose'),
        ],
      ),
    );
  }
}
