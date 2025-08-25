// models/Beans.dart
class Beans {
  final String id;
  final String name;
  final String? origin;
  final String? roastLevel;
  final DateTime roastDate;
  final int? weight;
  final String? notes;

  Beans({
    required this.id,
    required this.name,
    this.origin,
    this.roastLevel,
    required this.roastDate,
    this.weight,
    this.notes,

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
        'roastDate' : roastDate!.toIso8601String(),
        'weight' : weight,
        'notes' : notes,
      };

  factory Beans.fromApi(Map<String, dynamic> j) {
    // id can be '_id' (Mongo) or 'id' (legacy)
    final id = (j['_id'] ?? j['id'] ?? '') as String;

    // rating might be int/double/string — normalize to int
    DateTime parseRoastDate(Object? v) {
      if (v is String && v.isNotEmpty) {
        // handles ISO 8601 (e.g., "2025-08-24T14:33:00.000Z")
        return DateTime.tryParse(v) ?? DateTime(1970, 1, 1);
      }
      if (v is int) {
        // if backend sends ms-since-epoch
        return DateTime.fromMillisecondsSinceEpoch(v);
      }
      if (v is double) {
        return DateTime.fromMillisecondsSinceEpoch(v.toInt());
      }
      return DateTime(1970, 1, 1);
    }

    // beans: could be ObjectId string or populated object

    // recipe: same idea

    // date usually ISO string
    final dateStr = j['date'] as String?; 
    final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();

    return Beans(
      id: id,
      name: (j['name'] as String),
      origin: (j['origin'] as String?),
      roastLevel: (j['roastLevel'] as String?),
      weight: (j['weight'] as num?)?.toInt(),
      notes: j['notes'] as String?,
      roastDate: parseRoastDate(j['roastDate']),
    );
  }
}
