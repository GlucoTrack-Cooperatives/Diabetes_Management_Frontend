import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/theme/app_text_styles.dart';
import 'package:diabetes_management_system/utils/responsive_layout.dart';
import 'package:diabetes_management_system/widgets/custom_elevated_button.dart';
import 'package:diabetes_management_system/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'lifestyle_controller.dart';

class LifestyleTrackerScreen extends ConsumerWidget {
  const LifestyleTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lifestyleState = ref.watch(lifestyleControllerProvider);

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
        physics: const AlwaysScrollableScrollPhysics(),
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
              _WaterCard(glasses: data.waterGlasses),
              const SizedBox(height: 24),
              CustomElevatedButton(
                onPressed: () => _showEventDialog(context),
                text: 'Log Special Event',
                color: AppColors.secondary,
              ),
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
                _WaterCard(glasses: data.waterGlasses),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 300,
              child: CustomElevatedButton(
                onPressed: () => _showEventDialog(context),
                text: 'Log Special Event',
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepCard extends StatelessWidget {
  final Duration duration;
  const _SleepCard({required this.duration});

  @override
  Widget build(BuildContext context) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final totalHours = duration.inMinutes / 60;
    final sleepQuality = _getSleepQuality(totalHours);

    return Card(
      elevation: 0,
      color: AppColors.lavender,
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.nightlight_round, color: AppColors.textPrimary, size: 24),
                const SizedBox(width: 8),
                Text('Sleep', style: AppTextStyles.headline2),
              ],
            ),
            const Spacer(),
            Text('${hours}h ${minutes}m', style: AppTextStyles.headline1.copyWith(fontSize: 28)),
            Text(sleepQuality, style: AppTextStyles.bodyText2),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (totalHours / 8).clamp(0.0, 1.0),
                backgroundColor: Colors.white.withOpacity(0.5),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSleepQuality(double hours) {
    if (hours == 0) return 'No data';
    if (hours < 6) return 'Poor';
    if (hours < 7.5) return 'Fair';
    return 'Good';
  }
}

class _ActivityCard extends StatelessWidget {
  final int steps;
  final double calories;
  const _ActivityCard({required this.steps, required this.calories});

  @override
  Widget build(BuildContext context) {
    double progress = (steps / 10000).clamp(0.0, 1.0);

    return Card(
      elevation: 0,
      color: AppColors.mint,
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Activity', style: AppTextStyles.headline2),
            const Spacer(),
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 4,
                      backgroundColor: Colors.white.withOpacity(0.5),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    const Icon(Icons.directions_walk, size: 16, color: AppColors.primary),
                  ],
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$steps steps', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${calories.toInt()} kcal', style: AppTextStyles.bodyText2),
                  ],
                )
              ],
            ),
          ],
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
      elevation: 0,
      color: AppColors.peach,
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weight', style: AppTextStyles.headline2),
            const Spacer(),
            Text(weight != null ? weight!.toStringAsFixed(1) : '--', style: AppTextStyles.headline1.copyWith(fontSize: 28)),
            const Text('kg', style: AppTextStyles.bodyText2),
          ],
        ),
      ),
    );
  }
}

class _WaterCard extends ConsumerWidget {
  final int glasses;
  const _WaterCard({required this.glasses});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      color: AppColors.skyBlue,
      child: InkWell(
        onTap: () => ref.read(lifestyleControllerProvider.notifier).addWater(),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 160,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Water', style: AppTextStyles.headline2),
                  const Icon(Icons.add_circle, color: AppColors.primary),
                ],
              ),
              const Spacer(),
              Text('$glasses / 8 Glasses', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (glasses / 8).clamp(0.0, 1.0),
                backgroundColor: Colors.white.withOpacity(0.5),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 4),
              const Text('Tap to add a glass', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

void _showEventDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const _EventLogDialog(),
  );
}

class _EventLogDialog extends StatefulWidget {
  const _EventLogDialog();

  @override
  State<_EventLogDialog> createState() => _EventLogDialogState();
}

class _EventLogDialogState extends State<_EventLogDialog> {
  late TextEditingController _eventController;
  late TextEditingController _notesController;

  final List<String> _quickEvents = ['Stress', 'Fever', 'Illness', 'Period', 'Travel', 'Party'];
  String? _selectedQuickEvent;

  @override
  void initState() {
    super.initState();
    _eventController = TextEditingController();
    _notesController = TextEditingController();

    // Listen to text changes to manage bubble selection state
    _eventController.addListener(_handleTextChanged);
  }

  void _handleTextChanged() {
    // If the text in the field doesn't match the selected bubble, deselect the bubble
    if (_selectedQuickEvent != _eventController.text) {
      setState(() {
        _selectedQuickEvent = null;
      });
    }
  }

  @override
  void dispose() {
    // Remove listener and dispose
    _eventController.removeListener(_handleTextChanged);
    _eventController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log Special Event'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Events like stress or illness can affect your blood sugar levels.',
              style: AppTextStyles.bodyText2,
            ),
            const SizedBox(height: 16),

            // Quick Selection Bubbles
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _quickEvents.map((event) {
                final isSelected = _selectedQuickEvent == event;
                return ChoiceChip(
                  label: Text(event),
                  selected: isSelected,
                  selectedColor: AppColors.secondary.withOpacity(0.3),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedQuickEvent = event;
                        _eventController.text = event;
                      } else {
                        _selectedQuickEvent = null;
                        _eventController.clear();
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            CustomTextFormField(
              controller: _eventController,
              labelText: 'Event Type (e.g., Stress, Fever)',
              // onChanged removed to fix the error
            ),
            const SizedBox(height: 12),
            CustomTextFormField(
              controller: _notesController,
              labelText: 'Notes',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')
        ),
        ElevatedButton(
          onPressed: () {
            final eventType = _eventController.text;
            if (eventType.isNotEmpty) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Logged: $eventType')),
              );
            }
          },
          child: const Text('Log'),
        ),
      ],
    );
  }
}
