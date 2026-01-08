class PhysicianPatientSummary {
  final String id;
  final String fullName;
  final int age;
  final String email;
  final String phoneNumber;
  final bool isPhysicianConfirmed;

  // Latest Stats (Nullable as new patients might not have data)
  final int? latestGlucoseValue;
  final String? latestGlucoseTrend;
  final DateTime? latestGlucoseTimestamp;

  PhysicianPatientSummary({
    required this.id,
    required this.fullName,
    required this.age,
    required this.email,
    required this.phoneNumber,
    required this.isPhysicianConfirmed,
    this.latestGlucoseValue,
    this.latestGlucoseTrend,
    this.latestGlucoseTimestamp,
  });

  factory PhysicianPatientSummary.fromJson(Map<String, dynamic> json) {
    return PhysicianPatientSummary(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      age: json['age'] ?? 0,
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      isPhysicianConfirmed: json['isPhysicianConfirmed'] ?? false,
      latestGlucoseValue: json['latestGlucoseValue'],
      latestGlucoseTrend: json['latestGlucoseTrend'],
      latestGlucoseTimestamp: json['latestGlucoseTimestamp'] != null
          ? DateTime.tryParse(json['latestGlucoseTimestamp'])
          : null,
    );
  }
}