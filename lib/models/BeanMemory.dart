import 'package:v60pal/models/Beans.dart';

class BeanBrewSummary {
  final String? id;
  final double? rating;
  final String? recipeName;
  final String? notes;
  final int? waterTempC;
  final int? brewTimeSeconds;
  final String? grindSetting;
  final String? coffeeDose;
  final double? waterWeightGrams;
  final String? ratio;
  final int? pourCount;
  final String? pourPattern;
  final Map<String, dynamic>? tastingFeedback;
  final DateTime? date;

  BeanBrewSummary({
    this.id,
    this.rating,
    this.recipeName,
    this.notes,
    this.waterTempC,
    this.brewTimeSeconds,
    this.grindSetting,
    this.coffeeDose,
    this.waterWeightGrams,
    this.ratio,
    this.pourCount,
    this.pourPattern,
    this.tastingFeedback,
    this.date,
  });

  factory BeanBrewSummary.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    int? parseInt(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    DateTime? parseDate(dynamic value) {
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    Map<String, dynamic>? parseMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    }

    return BeanBrewSummary(
      id: json['id'] as String?,
      rating: parseDouble(json['rating']),
      recipeName: json['recipeName'] as String?,
      notes: json['notes'] as String?,
      waterTempC: parseInt(json['waterTempC']),
      brewTimeSeconds: parseInt(json['brewTimeSeconds']),
      grindSetting: json['grindSetting'] as String?,
      coffeeDose: json['coffeeDose'] as String?,
      waterWeightGrams: parseDouble(json['waterWeightGrams']),
      ratio: json['ratio'] as String?,
      pourCount: parseInt(json['pourCount']),
      pourPattern: json['pourPattern'] as String?,
      tastingFeedback: parseMap(json['tastingFeedback']),
      date: parseDate(json['date']) ?? parseDate(json['createdAt']),
    );
  }
}

class BeanRecommendedBrew {
  final String source;
  final Map<String, dynamic>? recipe;
  final Map<String, dynamic>? primaryAdjustment;
  final String? reason;
  final String? confidence;
  final String? sourceEntryId;

  BeanRecommendedBrew({
    required this.source,
    this.recipe,
    this.primaryAdjustment,
    this.reason,
    this.confidence,
    this.sourceEntryId,
  });

  factory BeanRecommendedBrew.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? parseMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    }

    return BeanRecommendedBrew(
      source: json['source'] as String? ?? 'unknown',
      recipe: parseMap(json['recipe']),
      primaryAdjustment: parseMap(json['primaryAdjustment']),
      reason: json['reason'] as String?,
      confidence: json['confidence'] as String?,
      sourceEntryId: json['sourceEntryId'] as String?,
    );
  }
}

class BeanTriedSummary {
  final int brewCount;
  final int ratedBrewCount;
  final double? averageRating;
  final double? bestRating;
  final List<String> recipes;
  final List<int> temperaturesC;
  final List<String> grindSettings;
  final List<int> brewTimesSeconds;
  final List<String> coffeeDoses;
  final List<int> waterAmountsGrams;
  final List<int> pourCounts;
  final List<String> pourPatterns;
  final List<String> filterTypes;

  BeanTriedSummary({
    required this.brewCount,
    required this.ratedBrewCount,
    this.averageRating,
    this.bestRating,
    required this.recipes,
    required this.temperaturesC,
    required this.grindSettings,
    required this.brewTimesSeconds,
    required this.coffeeDoses,
    required this.waterAmountsGrams,
    required this.pourCounts,
    required this.pourPatterns,
    required this.filterTypes,
  });

  factory BeanTriedSummary.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic value) {
      if (value is! List) return const [];
      return value.map((item) => item.toString()).toList();
    }

    List<int> parseIntList(dynamic value) {
      if (value is! List) return const [];
      return value
          .map((item) {
            if (item is num) return item.toInt();
            return int.tryParse(item.toString());
          })
          .whereType<int>()
          .toList();
    }

    double? parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return BeanTriedSummary(
      brewCount: (json['brewCount'] as num?)?.toInt() ?? 0,
      ratedBrewCount: (json['ratedBrewCount'] as num?)?.toInt() ?? 0,
      averageRating: parseDouble(json['averageRating']),
      bestRating: parseDouble(json['bestRating']),
      recipes: parseStringList(json['recipes']),
      temperaturesC: parseIntList(json['temperaturesC']),
      grindSettings: parseStringList(json['grindSettings']),
      brewTimesSeconds: parseIntList(json['brewTimesSeconds']),
      coffeeDoses: parseStringList(json['coffeeDoses']),
      waterAmountsGrams: parseIntList(json['waterAmountsGrams']),
      pourCounts: parseIntList(json['pourCounts']),
      pourPatterns: parseStringList(json['pourPatterns']),
      filterTypes: parseStringList(json['filterTypes']),
    );
  }
}

class BeanMemory {
  final Beans bean;
  final int brewCount;
  final BeanBrewSummary? lastBrew;
  final List<BeanBrewSummary> lastBrews;
  final BeanBrewSummary? bestRatedBrew;
  final BeanRecommendedBrew? recommendedNextBrew;
  final BeanTriedSummary tried;

  BeanMemory({
    required this.bean,
    required this.brewCount,
    this.lastBrew,
    required this.lastBrews,
    this.bestRatedBrew,
    this.recommendedNextBrew,
    required this.tried,
  });

  factory BeanMemory.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? parseMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    }

    final lastBrew = parseMap(json['lastBrew']);
    final lastBrewsJson = json['lastBrews'] is List
        ? json['lastBrews'] as List
        : const [];
    final bestRatedBrew = parseMap(json['bestRatedBrew']);
    final recommendedNextBrew = parseMap(json['recommendedNextBrew']);
    final tried = parseMap(json['tried']);

    return BeanMemory(
      bean: Beans.fromApi(parseMap(json['bean']) ?? const {}),
      brewCount: (json['brewCount'] as num?)?.toInt() ?? 0,
      lastBrew: lastBrew != null ? BeanBrewSummary.fromJson(lastBrew) : null,
      lastBrews: lastBrewsJson
          .whereType<Map>()
          .map(
            (item) => BeanBrewSummary.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      bestRatedBrew: bestRatedBrew != null
          ? BeanBrewSummary.fromJson(bestRatedBrew)
          : null,
      recommendedNextBrew: recommendedNextBrew != null
          ? BeanRecommendedBrew.fromJson(recommendedNextBrew)
          : null,
      tried: BeanTriedSummary.fromJson(tried ?? const {}),
    );
  }
}
