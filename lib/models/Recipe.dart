class Recipe {
  String id;
  String name;

  double waterWeightGrams;

  int waterTemp;

  List<int>
  pourSteps; // e.g., [30, 60, 90] means first pour takes 30s but starts at 0, next one goes to 60s, etc..

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

  Recipe copyWith({
    String? id,
    String? name,
    double? waterWeightGrams,
    int? waterTemp,
    List<int>? pourSteps,
    String? coffeeDose,
    String? grindSize,
    String? brewTime,
    List<int>? pourAmounts,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      waterWeightGrams: waterWeightGrams ?? this.waterWeightGrams,
      waterTemp: waterTemp ?? this.waterTemp,
      pourSteps: List<int>.from(pourSteps ?? this.pourSteps),
      coffeeDose: coffeeDose ?? this.coffeeDose,
      grindSize: grindSize ?? this.grindSize,
      brewTime: brewTime ?? this.brewTime,
      pourAmounts: List<int>.from(pourAmounts ?? this.pourAmounts),
    );
  }

  Recipe cloneAsVariant({String? id, String? name}) {
    return copyWith(
      id: id ?? '${this.id}-custom',
      name: name ?? '${this.name} Custom',
    );
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      name: json['name'] as String,
      waterWeightGrams: (json['waterWeightGrams'] as num).toDouble(),
      waterTemp: (json['waterTemp'] as num).toInt(),
      coffeeDose: json['coffeeDose'] as String,
      grindSize: json['grindSize'] as String,
      brewTime: json['brewTime'] as String,
      pourSteps: List<int>.from(json['pourSteps'] as List),
      pourAmounts: List<int>.from(json['pourAmounts'] as List),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'waterWeightGrams': waterWeightGrams,
    'waterTemp': waterTemp,
    'coffeeDose': coffeeDose,
    'grindSize': grindSize,
    'brewTime': brewTime,
    'pourSteps': pourSteps,
    'pourAmounts': pourAmounts,
  };
}
