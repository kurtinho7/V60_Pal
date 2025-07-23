import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class Beans extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String roastDate;

  @HiveField(2)
  String roasterName;

  // Example: list of additional “pour` at time T” offsets in seconds.
  @HiveField(3)
  String notes; // e.g., [30, 60, 90] means pour at 30s, 60s, 90s

  Beans({
    required this.name,
    required this.roastDate,
    required this.roasterName,
    required this.notes
  });
}

