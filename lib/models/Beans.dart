// models/Beans.dart
class Beans {
  final String id;
  final String name;
  final String origin;
  final String roastLevel;

  Beans({
    required this.id,
    required this.name,
    required this.origin,
    required this.roastLevel,
  });

  factory Beans.fromJson(Map<String, dynamic> json) {
    return Beans(
      id:         json['id'] as String,
      name:       json['name'] as String,
      origin:     json['origin'] as String,
      roastLevel: json['roastLevel'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id':         id,
        'name':       name,
        'origin':     origin,
        'roastLevel': roastLevel,
      };
}
