import 'package:intl/intl.dart';

enum AppointmentType {
  eyeExam('Eye Exam', Duration(days: 365)),
  checkUp('Check Up', Duration(days: 180)), // 6 months
  a1cTest('A1C Test', Duration(days: 90)),   // 3 months
  kidneyFunction('Kidney Function', Duration(days: 365)),
  liverFunction('Liver Function', Duration(days: 365)),
  lipidProfile('Lipid Profile', Duration(days: 365));

  final String label;
  final Duration frequency;

  const AppointmentType(this.label, this.frequency);

  static AppointmentType fromString(String value) {
    return AppointmentType.values.firstWhere(
      (e) => e.label == value,
      orElse: () => AppointmentType.checkUp,
    );
  }
}

class PatientAppointment {
  final String? id;
  final String patientId;
  final AppointmentType type;
  final DateTime appointmentDate;
  final DateTime nextDueDate;
  final String? notes;

  PatientAppointment({
    this.id,
    required this.patientId,
    required this.type,
    required this.appointmentDate,
    required this.nextDueDate,
    this.notes,
  });

  factory PatientAppointment.fromJson(Map<String, dynamic> json) {
    return PatientAppointment(
      id: json['id'],
      patientId: json['patientId'],
      type: AppointmentType.fromString(json['type']),
      appointmentDate: DateTime.parse(json['appointmentDate']),
      nextDueDate: DateTime.parse(json['nextDueDate']),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'type': type.label,
      'appointmentDate': appointmentDate.toIso8601String(),
      'nextDueDate': nextDueDate.toIso8601String(),
      'notes': notes,
    };
  }
}

class CreateAppointmentRequest {
  final String type;
  final DateTime appointmentDate;
  final String? notes;

  CreateAppointmentRequest({
    required this.type,
    required this.appointmentDate,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'appointmentDate': appointmentDate.toIso8601String(),
    'notes': notes,
  };
}
