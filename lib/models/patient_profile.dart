import 'package:diabetes_management_system/models/patient_alert_settings.dart';

class Patient {
  final String id;
  final String firstName;
  final String surName;
  final String phoneNumbers;
  final String dob;
  final String diagnosisDate;
  final String emergencyContactPhone;
  final String createdAt;
  final String? dexcomEmail; // Made nullable for easier "Connected" check
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
    this.dexcomEmail,
    this.physicianName,
    this.isPhysicianConfirmed,
    this.alertSettings,
  });

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
      dexcomEmail: json['dexcomEmail'], // Backend returns null if not connected
      physicianName: json['physicianName'],
      isPhysicianConfirmed: json['isPhysicianConfirmed'],
      alertSettings: json['alert_settings'] != null
          ? PatientAlertSettings.fromJson(json['alert_settings'])
          : null,
    );
  }
}
