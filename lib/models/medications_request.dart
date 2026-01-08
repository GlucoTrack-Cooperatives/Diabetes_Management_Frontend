class Medication {
  final String id;
  final String name;
  final String type;

  Medication({required this.id, required this.name, required this.type});

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'],
      name: json['name'],
      type: json['type'],
    );
  }
}