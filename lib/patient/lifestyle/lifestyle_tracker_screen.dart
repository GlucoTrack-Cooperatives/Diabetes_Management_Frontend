import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/theme/app_text_styles.dart';
import 'package:diabetes_management_system/utils/responsive_layout.dart';
import 'package:diabetes_management_system/widgets/custom_elevated_button.dart';
import 'package:flutter/material.dart';

class LifestyleTrackerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: _MobileLifestyleBody(),
      desktopBody: _DesktopLifestyleBody(),
    );
  }
}

class _MobileLifestyleBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _SleepCard(),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ActivityCard(),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: _WeightCard(),
                )
            ]
            ),
            SizedBox(height: 16),
            _WaterCard(),
            SizedBox(height: 24),
            CustomElevatedButton(onPressed: () {}, text: 'Log Event (Stress/Illness)'),
          ],
        ),
      ),
    );
  }
}

class _DesktopLifestyleBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Using a GridView for the desktop layout
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2, // Adjust aspect ratio as needed
              physics: NeverScrollableScrollPhysics(),
              children: [
                _SleepCard(),
                _ActivityCard(),
                _WeightCard(),
                _WaterCard(),
              ],
            ),
            SizedBox(height: 24),
            SizedBox(
              width: 300,
              child: CustomElevatedButton(onPressed: () {}, text: 'Log Event (Stress/Illness)'),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable Card Widgets

const double _cardHeight = 160.0;
const double _cardWidth = 200.0;

class _SleepCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: _cardHeight,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sleep', style: AppTextStyles.headline2),
              Spacer(),
              Text('Last Night: 7h 45m', style: AppTextStyles.bodyText1),
              SizedBox(height: 8),
              Container(height: 30, color: Colors.grey.shade200, child: Center(child: Text('Graph', style: AppTextStyles.bodyText2))), // Graph placeholder
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: _cardHeight,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text('Activity', style: AppTextStyles.headline2),
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: 0.75,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                        ),
                      ),
                      Text('8,500\nSteps', style: AppTextStyles.bodyText1, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeightCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: _cardHeight,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Weight', style: AppTextStyles.headline2),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('185.5', style: AppTextStyles.headline1.copyWith(fontSize: 28)),
                      SizedBox(width: 4),
                      Text('lbs', style: AppTextStyles.bodyText2),
                      Icon(Icons.arrow_downward, color: Colors.green, size: 16),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaterCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: _cardHeight,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Water', style: AppTextStyles.headline2),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('6 / 8 Glasses', style: AppTextStyles.bodyText1),
                  SizedBox(
                      height: 36, // Making button smaller
                      child: TextButton(onPressed: () {}, child: Text('Add Water'))),
                ],
              ),
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: 6 / 8,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
