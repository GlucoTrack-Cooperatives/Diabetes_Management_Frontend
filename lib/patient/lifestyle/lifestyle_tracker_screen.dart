import 'package:diabetes_management_system/theme/app_colors.dart';
import 'package:diabetes_management_system/theme/app_text_styles.dart';
import 'package:diabetes_management_system/utils/responsive_layout.dart';
import 'package:diabetes_management_system/widgets/custom_elevated_button.dart';
import 'package:diabetes_management_system/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'lifestyle_controller.dart';
import 'package:diabetes_management_system/models/health_event_request.dart';

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
              ),
              const SizedBox(height: 32),
              _EventHistorySection(data: data),
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
              ),
            ),
            const SizedBox(height: 40),
            _EventHistorySection(data: data),
          ],
        ),
      ),
    );
  }
}

class _EventHistorySection extends ConsumerWidget {
  final LifestyleData data;
  const _EventHistorySection({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekEnd = data.selectedWeekStart.add(const Duration(days: 6));
    final controller = ref.read(lifestyleControllerProvider.notifier);
    final DateFormat formatter = DateFormat('dd MMM');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Header Section with Cute Date Pill ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Event History', style: AppTextStyles.headline2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface, // Uses your theme white
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.border), // Soft border
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 20, color: AppColors.textPrimary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => controller.changeWeek(-1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      '${formatter.format(data.selectedWeekStart)} - ${formatter.format(weekEnd)}',
                      style: AppTextStyles.bodyText2.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.textPrimary
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textPrimary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => controller.changeWeek(1),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // --- Content Section ---
        if (data.isEventsLoading)
          const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(color: AppColors.primary),
          ))
        else if (data.healthEvents.isEmpty)
          _buildEmptyState()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.healthEvents.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12), // Gap between bubbles
            itemBuilder: (context, index) {
              return _EventBubble(event: data.healthEvents[index]);
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.spa_rounded, size: 40, color: AppColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 8),
          const Text(
            'No events logged yet',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _EventBubble extends StatelessWidget {
  final HealthEventDTO event;

  const _EventBubble({required this.event});

  // Helper to get fitting icon and color for the icon background
  ({Color iconBg, IconData icon}) _getStyle(String type) {
    switch (type.toLowerCase()) {
      case 'stress':
        return (iconBg: const Color(0xFFFFCC80), icon: Icons.psychology_alt_rounded);
      case 'fever':
        return (iconBg: const Color(0xFFEF9A9A), icon: Icons.thermostat_rounded);
      case 'illness':
        return (iconBg: const Color(0xFF90CAF9), icon: Icons.sick_rounded);
      case 'period':
        return (iconBg: const Color(0xFFF48FB1), icon: Icons.water_drop_rounded);
      case 'travel':
        return (iconBg: const Color(0xFFA5D6A7), icon: Icons.flight_rounded);
      case 'party':
        return (iconBg: const Color(0xFFCE93D8), icon: Icons.celebration_rounded);
      default:
        return (iconBg: AppColors.border, icon: Icons.edit_note_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _getStyle(event.eventType);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA), // A slightly darker than white color (Grey 50)
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.border, // Use theme border color
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          // Icon Circle - Keeps the specific color
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: style.iconBg.withOpacity(0.3), // Lighter version of icon bg
              shape: BoxShape.circle,
            ),
            child: Icon(style.icon, color: AppColors.textPrimary.withOpacity(0.7), size: 24),
          ),
          const SizedBox(width: 16),

          // Text Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.eventType,
                  style: AppTextStyles.bodyText1.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (event.notes != null && event.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      event.notes!,
                      style: AppTextStyles.bodyText2.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.6),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),

          // Time
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.white, // Pure white to stand out slightly on the grey
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withOpacity(0.5))
            ),
            child: Text(
              DateFormat('E, HH:mm').format(event.timestamp.toLocal()),
              style: AppTextStyles.bodyText2.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
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

class _EventLogDialog extends ConsumerStatefulWidget {
  const _EventLogDialog();

  @override
  ConsumerState<_EventLogDialog> createState() => _EventLogDialogState();
}

class _EventLogDialogState extends ConsumerState<_EventLogDialog> {
  late TextEditingController _eventController;
  late TextEditingController _notesController;
  final List<String> _quickEvents = ['Stress', 'Fever', 'Illness', 'Period', 'Travel', 'Party'];
  String? _selectedQuickEvent;

  @override
  void initState() {
    super.initState();
    _eventController = TextEditingController();
    _notesController = TextEditingController();
    _eventController.addListener(_handleTextChanged);
  }

  void _handleTextChanged() {
    if (_selectedQuickEvent != _eventController.text) {
      setState(() { _selectedQuickEvent = null; });
    }
  }

  @override
  void dispose() {
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
            const Text('Events can affect blood sugar.', style: AppTextStyles.bodyText2),
            const SizedBox(height: 16),
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
            CustomTextFormField(controller: _eventController, labelText: 'Event Type'),
            const SizedBox(height: 12),
            CustomTextFormField(controller: _notesController, labelText: 'Notes'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (_eventController.text.isNotEmpty) {
              await ref.read(lifestyleControllerProvider.notifier).logEvent(_eventController.text, _notesController.text);
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: const Text('Log'),
        ),
      ],
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
    return Card(
      elevation: 0,
      color: AppColors.lavender,
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.nightlight_round, size: 24),
              const SizedBox(width: 8),
              Text('Sleep', style: AppTextStyles.headline2),
            ]),
            const Spacer(),
            Text('${hours}h ${minutes}m', style: AppTextStyles.headline1.copyWith(fontSize: 28)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: (totalHours / 8).clamp(0.0, 1.0)),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final int steps;
  final double calories;
  const _ActivityCard({required this.steps, required this.calories});

  @override
  Widget build(BuildContext context) {
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
            Text('$steps steps', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('${calories.toInt()} kcal', style: AppTextStyles.bodyText2),
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
            Text(weight != null ? '${weight!.toStringAsFixed(1)} kg' : '-- kg', style: AppTextStyles.headline1.copyWith(fontSize: 28)),
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
        child: Container(
          height: 160,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Water', style: AppTextStyles.headline2),
              const Spacer(),
              Text('$glasses / 8 Glasses'),
              LinearProgressIndicator(value: (glasses / 8).clamp(0.0, 1.0)),
            ],
          ),
        ),
      ),
    );
  }
}