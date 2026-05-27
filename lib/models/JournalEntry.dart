import 'package:v60pal/models/Recipe.dart';
import 'package:v60pal/models/Beans.dart';
import 'dart:convert';

class JournalEntry {
  /// Mongo _id
  final String id;

  /// Store rating as int (Mongo typically uses Number)
  final double? rating;

  /// Optional fields (server may omit them)
  final int? waterTemp;
  final int? timeTaken;
  final String? coffeeDose;
  final double? waterWeightGrams;
  final String? grindSetting;
  final String? notes;
  final Map<String, dynamic>? aiFeedback;
  final DateTime? aiFeedbackGeneratedAt;
  final String? aiFeedbackModel;

  /// If the API populates refs, these may be full objects.
  final Beans? beans;
  final Recipe? recipe;

  /// Always keep the IDs we’ll send back to API for refs.
  final String? beansId;
  final String? recipeId;

  final DateTime date;

  JournalEntry({
    required this.id,
    required this.rating,
    this.waterTemp,
    this.timeTaken,
    this.coffeeDose,
    this.waterWeightGrams,
    this.grindSetting,
    this.notes,
    this.aiFeedback,
    this.aiFeedbackGeneratedAt,
    this.aiFeedbackModel,
    this.beans,
    this.recipe,
    this.beansId,
    this.recipeId,
    required this.date,
  });

  /// Accepts data from your API (supports populated or plain ids)
  factory JournalEntry.fromApi(Map<String, dynamic> j) {
    // id can be '_id' (Mongo) or 'id' (legacy)
    final id = (j['_id'] ?? j['id']) as String;

    // rating might be int/double/string — normalize to double
    double parseRating(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    Map<String, dynamic>? parseMap(dynamic v) {
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v);
      return null;
    }

    // beans: could be ObjectId string or populated object
    String? beansId;
    Beans? beansObj;
    final beansField = j['beans'];
    if (beansField is String) {
      beansId = beansField;
    } else if (beansField is Map<String, dynamic>) {
      beansObj = Beans.fromApi(beansField);
      beansId = (beansField['_id'] ?? beansField['id']) as String?;
    }

    // recipe: same idea
    String? recipeId;
    Recipe? recipeObj;
    final recipeField = j['recipe'];
    if (recipeField is String) {
      recipeId = recipeField;
    } else if (recipeField is Map<String, dynamic>) {
      recipeObj = Recipe.fromJson(recipeField);
      recipeId = (recipeField['_id'] ?? recipeField['id']) as String?;
    }

    // date usually ISO string
    final dateStr = j['date'] as String?;
    final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
    final feedbackDateStr = j['aiFeedbackGeneratedAt'] as String?;

    return JournalEntry(
      id: id,
      rating: parseRating(j['rating']),
      waterTemp: (j['waterTemp'] as num?)?.toInt(),
      timeTaken: (j['timeTaken'] as num?)?.toInt(),
      coffeeDose: j['coffeeDose'] as String?,
      waterWeightGrams: parseDouble(j['waterWeightGrams']),
      grindSetting: j['grindSetting'] as String?,
      notes: j['notes'] as String?,
      aiFeedback: parseMap(j['aiFeedback']),
      aiFeedbackGeneratedAt: feedbackDateStr != null
          ? DateTime.tryParse(feedbackDateStr)
          : null,
      aiFeedbackModel: j['aiFeedbackModel'] as String?,
      beans: beansObj,
      recipe: recipeObj,
      beansId: beansId,
      recipeId: recipeId,
      date: date,
    );
  }

  /// Body for CREATE requests to your API
  Map<String, dynamic> toCreateBody() => {
    'rating': rating,
    if (waterTemp != null) 'waterTemp': waterTemp,
    if (timeTaken != null) 'timeTaken': timeTaken,
    if (coffeeDose != null) 'coffeeDose': coffeeDose,
    if (waterWeightGrams != null) 'waterWeightGrams': waterWeightGrams,
    if (grindSetting != null) 'grindSetting': grindSetting,
    if (notes != null) 'notes': notes,
    if (beansId != null) 'beans': beansId, // send only the id
    if (recipeId != null) 'recipe': recipeId, // send only the id
    'date': date.toIso8601String(),
  };

  /// Body for UPDATE requests to your API
  Map<String, dynamic> toUpdateBody() => {
    'rating': rating,
    'waterTemp': waterTemp,
    'timeTaken': timeTaken,
    'coffeeDose': coffeeDose,
    'waterWeightGrams': waterWeightGrams,
    'grindSetting': grindSetting,
    'notes': notes,
    'aiFeedback': aiFeedback,
    'aiFeedbackGeneratedAt': aiFeedbackGeneratedAt?.toIso8601String(),
    'aiFeedbackModel': aiFeedbackModel,
    'beans': beansId,
    'recipe': recipeId,
    'date': date.toIso8601String(),
  }..removeWhere((_, v) => v == null);

  factory JournalEntry.fromJson(Map<String, dynamic> j) {
    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    Map<String, dynamic>? parseMap(dynamic v) {
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v);
      return null;
    }

    return JournalEntry(
      id: j['id'] as String? ?? '',
      rating: parseDouble(j['rating']),
      waterTemp: (j['waterTemp'] as num?)?.toInt(),
      timeTaken: (j['timeTaken'] as num?)?.toInt(),
      coffeeDose: j['coffeeDose'] as String?,
      waterWeightGrams: parseDouble(j['waterWeightGrams']),
      grindSetting: j['grindSetting'] as String?,
      notes: j['notes'] as String?,
      aiFeedback: parseMap(j['aiFeedback']),
      aiFeedbackGeneratedAt: j['aiFeedbackGeneratedAt'] is String
          ? DateTime.tryParse(j['aiFeedbackGeneratedAt'] as String)
          : null,
      aiFeedbackModel: j['aiFeedbackModel'] as String?,
      beans: j['beans'] is Map<String, dynamic>
          ? Beans.fromJson(j['beans'] as Map<String, dynamic>)
          : null,
      recipe: j['recipe'] is Map<String, dynamic>
          ? Recipe.fromJson(j['recipe'] as Map<String, dynamic>)
          : null,
      date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'rating': rating,
    'waterTemp': waterTemp,
    'timeTaken': timeTaken,
    'coffeeDose': coffeeDose,
    'waterWeightGrams': waterWeightGrams,
    'grindSetting': grindSetting,
    'notes': notes,
    'aiFeedback': aiFeedback,
    'aiFeedbackGeneratedAt': aiFeedbackGeneratedAt?.toIso8601String(),
    'aiFeedbackModel': aiFeedbackModel,
    'beans': beans?.toJson(),
    'recipe': recipe?.toJson(),
    'date': date.toIso8601String(),
  };

  String toJsonString() => jsonEncode(toJson());

  JournalEntry copyWith({
    String? id,
    double? rating,
    int? waterTemp,
    int? timeTaken,
    String? coffeeDose,
    double? waterWeightGrams,
    String? grindSetting,
    String? notes,
    Map<String, dynamic>? aiFeedback,
    DateTime? aiFeedbackGeneratedAt,
    String? aiFeedbackModel,
    Beans? beans,
    Recipe? recipe,
    String? beansId,
    String? recipeId,
    DateTime? date,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      rating: rating ?? this.rating,
      waterTemp: waterTemp ?? this.waterTemp,
      timeTaken: timeTaken ?? this.timeTaken,
      coffeeDose: coffeeDose ?? this.coffeeDose,
      waterWeightGrams: waterWeightGrams ?? this.waterWeightGrams,
      grindSetting: grindSetting ?? this.grindSetting,
      notes: notes ?? this.notes,
      aiFeedback: aiFeedback ?? this.aiFeedback,
      aiFeedbackGeneratedAt:
          aiFeedbackGeneratedAt ?? this.aiFeedbackGeneratedAt,
      aiFeedbackModel: aiFeedbackModel ?? this.aiFeedbackModel,
      beans: beans ?? this.beans,
      recipe: recipe ?? this.recipe,
      beansId: beansId ?? this.beansId,
      recipeId: recipeId ?? this.recipeId,
      date: date ?? this.date,
    );
  }
}
