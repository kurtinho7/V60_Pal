
class Recipe {
  String id;
  String name;

  double waterWeightGrams;

  int waterTemp;

  List<int> pourSteps; // e.g., [30, 60, 90] means first pour takes 30s but starts at 0, next one goes to 60s, etc..

  String coffeeDose;

  String grindSize;

  String brewTime;

  List<int> pourAmounts; 

  Recipe({
    required this.id,
    required this.name,
    required this.waterWeightGrams,
    required this.waterTemp,
    required this.pourSteps,
    required this.coffeeDose,
    required this.grindSize,
    required this.brewTime,
    required this.pourAmounts,
  });

    factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id:               json['id'] as String,
      name:             json['name'] as String,
      waterWeightGrams: (json['waterWeightGrams'] as num).toDouble(),
      waterTemp: (json['waterTemp'] as num).toInt(),
      coffeeDose:       json['coffeeDose'] as String,
      grindSize:        json['grindSize'] as String,
      brewTime:         json['brewTime'] as String,
      pourSteps:        List<int>.from(json['pourSteps'] as List),
      pourAmounts:      List<int>.from(json['pourAmounts'] as List),
    );
  }

  Map<String, dynamic> toJson() => {
        'id':               id,
        'name':             name,
        'waterWeightGrams': waterWeightGrams,
        'waterTemp':    waterTemp,
        'coffeeDose':       coffeeDose,
        'grindSize':        grindSize,
        'brewTime':         brewTime,
        'pourSteps':        pourSteps,
        'pourAmounts':      pourAmounts,
      };
}

