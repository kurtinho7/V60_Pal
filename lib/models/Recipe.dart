import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class Recipe extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double waterWeightGrams;

  @HiveField(2)
  int bloomSeconds;

  // Example: list of additional “pour` at time T” offsets in seconds.
  @HiveField(3)
  List<int> pourSteps; // e.g., [30, 60, 90] means pour at 30s, 60s, 90s

  @HiveField(4)
  String coffeDose;

  @HiveField(5)
  String grindSize;

  @HiveField(6)
  String brewTime;

  @HiveField(7)
  List<int> pourAmounts; 

  Recipe({
    required this.name,
    required this.waterWeightGrams,
    required this.bloomSeconds,
    required this.pourSteps,
    required this.coffeDose,
    required this.grindSize,
    required this.brewTime,
    required this.pourAmounts,
  });
}

