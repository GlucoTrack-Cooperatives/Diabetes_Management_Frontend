

class PatientRegistrationRequest {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String dob;
  final String diagnosisDate;
  final String emergencyContact;

  PatientRegistrationRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.dob,
    required this.diagnosisDate,
    required this.emergencyContact,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      'dob': dob,
      'diagnosisDate': diagnosisDate,
      'emergencyContact': emergencyContact,
    };
  }

}