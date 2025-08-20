// models/Beans.dart
class Beans {
  final String id;
  final String name;
  final String origin;
  final String roastLevel;
  final DateTime roastDate;
  final int weight;
  final String notes;

  Beans({
    required this.id,
    required this.name,
    required this.origin,
    required this.roastLevel,
    required this.roastDate,
    required this.weight,
    required this.notes,

  });

  factory Beans.fromJson(Map<String, dynamic> json) {
    return Beans(
      id:         json['id'] as String,
      name:       json['name'] as String,
      origin:     json['origin'] as String,
      roastLevel: json['roastLevel'] as String,
      roastDate: DateTime.parse(json['roastDate'] as String),
      weight: (json['weight'] as num).toInt(),
      notes: json['notes'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id':         id,
        'name':       name,
        'origin':     origin,
        'roastLevel': roastLevel,
        'roastDate' : roastDate.toIso8601String(),
        'weight' : weight,
        'notes' : notes,
      };
}
