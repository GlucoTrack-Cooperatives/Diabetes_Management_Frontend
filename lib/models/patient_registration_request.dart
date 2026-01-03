class PatientRegistrationRequest {
  final String firstName;
  final String surname;
  final String email;
  final String password;
  final String phoneNumber;
  final String dob;
  final String diagnosisDate;
  final String emergencyContactPhone;

  PatientRegistrationRequest({
    required this.firstName,
    required this.surname,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.dob,
    required this.diagnosisDate,
    required this.emergencyContactPhone,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'surname': surname,
      'email': email,
      'password': password,
      'phoneNumber': phoneNumber,
      'dob': dob,
      'diagnosisDate': diagnosisDate,
      'emergencyContactPhone': emergencyContactPhone,
    };
  }

}