import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PhysicianPatientSummary {
  final String id;
  final String firstName;
  final String surname;
  final int age; // or String dob
  // You might need to calculate Risk/Stats on backend or frontend.
  // For now, let's map what we can.

  PhysicianPatientSummary({
    required this.id,
    required this.firstName,
    required this.surname,
    required this.age,
  });

  factory PhysicianPatientSummary.fromJson(Map<String, dynamic> json) {
    return PhysicianPatientSummary(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      surname: json['surname'] ?? '',
      age: json['age'] ?? 0,
    );
  }

  // Helper for UI
  String get initials => "${firstName.isNotEmpty ? firstName[0] : ''}${surname.isNotEmpty ? surname[0] : ''}".toUpperCase();
  String get fullName => "$firstName $surname";
}
