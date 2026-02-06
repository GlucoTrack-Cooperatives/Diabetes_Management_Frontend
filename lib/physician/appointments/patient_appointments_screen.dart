import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/patient_appointment.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'patient_appointments_controller.dart';

class PatientAppointmentsScreen extends ConsumerWidget {
  final String patientId;
  final String patientName;

  const PatientAppointmentsScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(patientAppointmentsProvider(patientId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Appointments: $patientName'),
      ),
      body: appointmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (appointments) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNextDueSection(appointments),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Appointment History', style: AppTextStyles.headline2),
                    ElevatedButton.icon(
                      onPressed: () => _showAddAppointmentDialog(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Record'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildHistoryList(appointments),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNextDueSection(List<PatientAppointment> appointments) {
    final latestByType = <AppointmentType, PatientAppointment>{};
    for (var appt in appointments) {
      if (!latestByType.containsKey(appt.type) ||
          appt.appointmentDate.isAfter(latestByType[appt.type]!.appointmentDate)) {
        latestByType[appt.type] = appt;
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upcoming & Maintenance', style: AppTextStyles.headline2),
            const SizedBox(height: 16),
            ...AppointmentType.values.map((type) {
              final lastAppt = latestByType[type];
              final nextDue = lastAppt?.nextDueDate;
              final isOverdue = nextDue != null && nextDue.isBefore(DateTime.now());

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Icon(
                      isOverdue ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                      color: isOverdue ? Colors.red : Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(type.label, style: AppTextStyles.bodyText1.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                            lastAppt == null
                                ? 'No record found'
                                : 'Last: ${DateFormat('MMM dd, yyyy').format(lastAppt.appointmentDate)}',
                            style: AppTextStyles.bodyText2.copyWith(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Next Due', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        Text(
                          nextDue == null ? 'Pending' : DateFormat('MMM dd, yyyy').format(nextDue),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isOverdue ? Colors.red : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<PatientAppointment> appointments) {
    if (appointments.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Text('No appointments recorded yet.'),
      ));
    }

    final sorted = List<PatientAppointment>.from(appointments)
      ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final appt = sorted[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(appt.type.label),
            subtitle: Text(DateFormat('EEEE, MMM dd, yyyy').format(appt.appointmentDate)),
            trailing: appt.notes != null && appt.notes!.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(appt.type.label),
                          content: Text(appt.notes!),
                          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
                        ),
                      );
                    },
                  )
                : null,
          ),
        );
      },
    );
  }

  void _showAddAppointmentDialog(BuildContext context, WidgetRef ref) {
    AppointmentType selectedType = AppointmentType.checkUp;
    DateTime selectedDate = DateTime.now();
    final notesController = TextEditingController();
    bool notifyPatient = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Record Appointment', style: AppTextStyles.headline2),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<AppointmentType>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Appointment Type', border: OutlineInputBorder()),
                    items: AppointmentType.values.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type.label));
                    }).toList(),
                    onChanged: (val) => setState(() => selectedType = val!),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Appointment Date'),
                    subtitle: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) setState(() => selectedDate = date);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(labelText: 'Notes (Optional)', border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Send confirmation message to patient'),
                    subtitle: const Text('Automated summary will be sent to chat'),
                    value: notifyPatient,
                    onChanged: (val) => setState(() => notifyPatient = val),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await ref.read(patientAppointmentsControllerProvider(patientId).notifier).recordAppointment(
                          type: selectedType,
                          date: selectedDate,
                          notes: notesController.text,
                          notifyPatient: notifyPatient,
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save Record'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
