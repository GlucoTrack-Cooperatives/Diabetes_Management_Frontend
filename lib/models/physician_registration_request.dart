class PhysicianRegistrationRequest {
  final String firstName;
  final String surname;
  final String email;
  final String password;
  final String specialty;
  final String licenseNumber;
  final String clinicName;

  PhysicianRegistrationRequest({
    required this.firstName,
    required this.surname,
    required this.email,
    required this.password,
    required this.specialty,
    required this.licenseNumber,
    required this.clinicName,
  });

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'surname': surname,
    'email': email,
    'password': password,
    'specialty': specialty,
    'licenseNumber': licenseNumber,
    'clinicName': clinicName,
  };
}
