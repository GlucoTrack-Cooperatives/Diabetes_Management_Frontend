import 'package:diabetes_management_system/models/patient_alert_settings.dart'; // Import this

class Patient {
  final String id;
  final String firstName;
  final String surName;
  final String phoneNumbers;
  final String dob;
  final String diagnosisDate;
  final String emergencyContactPhone;
  final String createdAt;
  final String? physicianName;
  final bool? isPhysicianConfirmed;

  final PatientAlertSettings? alertSettings;

  Patient({
    required this.id,
    required this.firstName,
    required this.surName,
    required this.phoneNumbers,
    required this.dob,
    required this.diagnosisDate,
    required this.emergencyContactPhone,
    required this.createdAt,
    this.physicianName,
    this.isPhysicianConfirmed,
    this.alertSettings,
  });

  // Factory constructor to map JSON from Spring Boot
  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? 'Patient',
      surName: json['surName'] ?? '',
      phoneNumbers: json['phoneNumbers'] ?? '',
      dob: json['dob'] ?? '',
      diagnosisDate: json['diagnosisDate'] ?? '',
      emergencyContactPhone: json['emergencyContactPhone'] ?? '',
      createdAt: json['createdAt'] ?? '',
      physicianName: json['physicianName'],
      isPhysicianConfirmed: json['isPhysicianConfirmed'],
      alertSettings: json['alert_settings'] != null
          ? PatientAlertSettings.fromJson(json['alert_settings'])
          : null,
    );
  }
}