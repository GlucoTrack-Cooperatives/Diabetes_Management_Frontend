import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/theme/app_text_styles.dart';
import 'package:diabetes_management_system/utils/responsive_layout.dart';
import 'package:diabetes_management_system/widgets/custom_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'lifestyle_controller.dart'; // Import the new controller

class LifestyleTrackerScreen extends ConsumerWidget {
  const LifestyleTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the controller state
    final lifestyleState = ref.watch(lifestyleControllerProvider);

    // Remove Scaffold and AppBar. Return the body directly.
    return ResponsiveLayout(
      mobileBody: _MobileLifestyleBody(
          data: lifestyleState,
          onRefresh: () => ref.read(lifestyleControllerProvider.notifier).syncHealthData()
      ),
      desktopBody: _DesktopLifestyleBody(
          data: lifestyleState
      ),
    );
  }
}

class _MobileLifestyleBody extends StatelessWidget {
  final LifestyleData data;
  final Future<void> Function() onRefresh;

  const _MobileLifestyleBody({required this.data, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), // Ensures pull-to-refresh works even if content is short
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _SleepCard(duration: data.sleepDuration),
              const SizedBox(height: 16),
              Row(
                  children: [
                    Expanded(
                      child: _ActivityCard(steps: data.steps, calories: data.activeCalories),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _WeightCard(weight: data.weight),
                    )
                  ]
              ),
              const SizedBox(height: 16),
              _WaterCard(),
              const SizedBox(height: 24),
              CustomElevatedButton(onPressed: () {}, text: 'Log Event (Stress/Illness)'),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopLifestyleBody extends StatelessWidget {
  final LifestyleData data;

  const _DesktopLifestyleBody({required this.data});

  @override
  Widget build(BuildContext context) {
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
              childAspectRatio: 2,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _SleepCard(duration: data.sleepDuration),
                _ActivityCard(steps: data.steps, calories: data.activeCalories),
                _WeightCard(weight: data.weight),
                _WaterCard(),
              ],
            ),
            const SizedBox(height: 24),
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

class _SleepCard extends StatelessWidget {
  final Duration duration;
  const _SleepCard({required this.duration});

  @override
  Widget build(BuildContext context) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final totalHours = duration.inMinutes / 60;

    // Determine sleep quality based on duration
    final sleepQuality = _getSleepQuality(totalHours);
    final sleepColor = _getSleepColor(totalHours);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.nightlight_round, color: sleepColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Sleep',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),

            // Main sleep duration display
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${hours}h ${minutes}m',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: sleepColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  sleepQuality,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Sleep progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Last Night',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'Goal: 7-9h',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (totalHours / 9).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(sleepColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getSleepQuality(double hours) {
    if (hours == 0) return 'No data';
    if (hours < 5) return 'Poor';
    if (hours < 7) return 'Fair';
    if (hours <= 9) return 'Good';
    return 'Excessive';
  }

  Color _getSleepColor(double hours) {
    if (hours == 0) return Colors.grey;
    if (hours < 5) return Colors.red;
    if (hours < 7) return Colors.orange;
    if (hours <= 9) return Colors.green;
    return Colors.blue;
  }
}

class _ActivityCard extends StatelessWidget {
  final int steps;
  final double calories;
  const _ActivityCard({required this.steps, required this.calories});

  @override
  Widget build(BuildContext context) {
    double progress = (steps / 10000).clamp(0.0, 1.0);

    // Add indicator if no calorie data
    final hasCalorieData = calories > 0;

    return Card(
      child: SizedBox(
        height: _cardHeight,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Activity', style: AppTextStyles.headline2),
              if (!hasCalorieData)
                Icon(Icons.info_outline, size: 16, color: Colors.orange),

              Expanded(
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 8,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                            ),
                          ),
                          Text('${(steps / 1000).toStringAsFixed(1)}k', style: AppTextStyles.bodyText1),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$steps Steps', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text(
                            hasCalorieData
                                ? '${calories.toInt()} kcal'
                                : 'No data',
                            style: TextStyle(
                                fontSize: 12,
                                color: hasCalorieData ? Colors.grey : Colors.orange
                            ),
                          ),
                        ],
                      )
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
  final double? weight;
  const _WeightCard({this.weight});

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
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                          weight != null ? weight!.toStringAsFixed(1) : '--',
                          style: AppTextStyles.headline1.copyWith(fontSize: 28)
                      ),
                      const SizedBox(width: 4),
                      Text('kg', style: AppTextStyles.bodyText2),
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
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('6 / 8 Glasses', style: AppTextStyles.bodyText1),
                  SizedBox(
                      height: 36,
                      child: TextButton(onPressed: () {}, child: const Text('Add Water'))),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: 6 / 8,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}