class PatientProfileUpdateRequest {
  final String firstName;
  final String surName;
  final String phoneNumber;
  final String dob;
  final String diagnosisDate;
  final String emergencyContactPhone;

  PatientProfileUpdateRequest({
    required this.firstName,
    required this.surName,
    required this.phoneNumber,
    required this.dob,
    required this.diagnosisDate,
    required this.emergencyContactPhone,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'surName': surName,
      'phoneNumbers': phoneNumber,
      'dob': dob,
      'diagnosisDate': diagnosisDate,
      'emergencyContactPhone': emergencyContactPhone,
    };
  }
}
