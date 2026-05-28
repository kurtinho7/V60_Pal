import 'package:v60pal/models/Recipe.dart';
import 'package:v60pal/models/Beans.dart';
import 'package:v60pal/models/BrewGuardrails.dart';
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
  final int? bloomTimeSeconds;
  final double? bloomWaterGrams;
  final int? pourCount;
  final String? pourPattern;
  final bool? agitationSwirled;
  final bool? agitationStirred;
  final String? agitationNotes;
  final String? filterType;
  final String? brewerSize;
  final String? brewerMaterial;
  final String? grinderModel;
  final String? grinderBurrs;
  final String? grinderGrindScale;
  final String? waterSource;
  final String? waterProfile;
  final int? drawdownTimeSeconds;
  final String? notes;
  final Map<String, dynamic>? tastingFeedback;
  final Map<String, dynamic>? aiFeedback;
  final DateTime? aiFeedbackGeneratedAt;
  final String? aiFeedbackModel;
  final Map<String, dynamic>? guidedAdjustment;
  final Map<String, dynamic>? plannedAdjustment;
  final String? comparisonSourceEntryId;
  final Map<String, dynamic>? comparisonResult;

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
    this.bloomTimeSeconds,
    this.bloomWaterGrams,
    this.pourCount,
    this.pourPattern,
    this.agitationSwirled,
    this.agitationStirred,
    this.agitationNotes,
    this.filterType,
    this.brewerSize,
    this.brewerMaterial,
    this.grinderModel,
    this.grinderBurrs,
    this.grinderGrindScale,
    this.waterSource,
    this.waterProfile,
    this.drawdownTimeSeconds,
    this.notes,
    this.tastingFeedback,
    this.aiFeedback,
    this.aiFeedbackGeneratedAt,
    this.aiFeedbackModel,
    this.guidedAdjustment,
    this.plannedAdjustment,
    this.comparisonSourceEntryId,
    this.comparisonResult,
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

    bool? parseBool(dynamic v) {
      if (v is bool) return v;
      if (v is String) return v.toLowerCase() == 'true';
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
    final agitation = parseMap(j['agitation']);
    final brewer = parseMap(j['brewer']);
    final grinder = parseMap(j['grinder']);
    final waterProfileMap = parseMap(j['water']);

    return JournalEntry(
      id: id,
      rating: parseRating(j['rating']),
      waterTemp: (j['waterTemp'] as num?)?.toInt(),
      timeTaken: (j['timeTaken'] as num?)?.toInt(),
      coffeeDose: j['coffeeDose'] as String?,
      waterWeightGrams: parseDouble(j['waterWeightGrams']),
      grindSetting: j['grindSetting'] as String?,
      bloomTimeSeconds: (j['bloomTimeSeconds'] as num?)?.toInt(),
      bloomWaterGrams: parseDouble(j['bloomWaterGrams']),
      pourCount: (j['pourCount'] as num?)?.toInt(),
      pourPattern: j['pourPattern'] as String?,
      agitationSwirled: parseBool(agitation?['swirled']),
      agitationStirred: parseBool(agitation?['stirred']),
      agitationNotes: agitation?['notes'] as String?,
      filterType: j['filterType'] as String?,
      brewerSize: brewer?['size'] as String?,
      brewerMaterial: brewer?['material'] as String?,
      grinderModel: grinder?['model'] as String?,
      grinderBurrs: grinder?['burrs'] as String?,
      grinderGrindScale: grinder?['grindScale'] as String?,
      waterSource: waterProfileMap?['source'] as String?,
      waterProfile: waterProfileMap?['profile'] as String?,
      drawdownTimeSeconds: (j['drawdownTimeSeconds'] as num?)?.toInt(),
      notes: j['notes'] as String?,
      tastingFeedback: parseMap(j['tastingFeedback']),
      aiFeedback: parseMap(j['aiFeedback']),
      aiFeedbackGeneratedAt: feedbackDateStr != null
          ? DateTime.tryParse(feedbackDateStr)
          : null,
      aiFeedbackModel: j['aiFeedbackModel'] as String?,
      guidedAdjustment: parseMap(j['guidedAdjustment']),
      plannedAdjustment: parseMap(j['plannedAdjustment']),
      comparisonSourceEntryId:
          (j['comparisonSourceEntryId'] ?? j['comparisonSourceEntry'])
              as String?,
      comparisonResult: parseMap(j['comparisonResult']),
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
    if (BrewGuardrails.isPlausibleWaterTemp(waterTemp)) 'waterTemp': waterTemp,
    if (BrewGuardrails.positiveSeconds(timeTaken) != null)
      'timeTaken': timeTaken,
    if (coffeeDose != null) 'coffeeDose': coffeeDose,
    if (waterWeightGrams != null) 'waterWeightGrams': waterWeightGrams,
    if (grindSetting != null) 'grindSetting': grindSetting,
    if (bloomTimeSeconds != null) 'bloomTimeSeconds': bloomTimeSeconds,
    if (bloomWaterGrams != null) 'bloomWaterGrams': bloomWaterGrams,
    if (pourCount != null) 'pourCount': pourCount,
    if (pourPattern != null) 'pourPattern': pourPattern,
    if (agitationSwirled != null ||
        agitationStirred != null ||
        agitationNotes != null)
      'agitation': {
        if (agitationSwirled != null) 'swirled': agitationSwirled,
        if (agitationStirred != null) 'stirred': agitationStirred,
        if (agitationNotes != null) 'notes': agitationNotes,
      },
    if (filterType != null) 'filterType': filterType,
    if (brewerSize != null || brewerMaterial != null)
      'brewer': {
        if (brewerSize != null) 'size': brewerSize,
        if (brewerMaterial != null) 'material': brewerMaterial,
      },
    if (grinderModel != null ||
        grinderBurrs != null ||
        grinderGrindScale != null)
      'grinder': {
        if (grinderModel != null) 'model': grinderModel,
        if (grinderBurrs != null) 'burrs': grinderBurrs,
        if (grinderGrindScale != null) 'grindScale': grinderGrindScale,
      },
    if (waterSource != null || waterProfile != null)
      'water': {
        if (waterSource != null) 'source': waterSource,
        if (waterProfile != null) 'profile': waterProfile,
      },
    if (drawdownTimeSeconds != null) 'drawdownTimeSeconds': drawdownTimeSeconds,
    if (notes != null) 'notes': notes,
    if (tastingFeedback != null) 'tastingFeedback': tastingFeedback,
    if (guidedAdjustment != null) 'guidedAdjustment': guidedAdjustment,
    if (plannedAdjustment != null) 'plannedAdjustment': plannedAdjustment,
    if (comparisonSourceEntryId != null)
      'comparisonSourceEntryId': comparisonSourceEntryId,
    if (comparisonResult != null) 'comparisonResult': comparisonResult,
    if (beansId != null) 'beans': beansId, // send only the id
    if (recipeId != null) 'recipe': recipeId, // send only the id
    'date': date.toIso8601String(),
  };

  /// Body for UPDATE requests to your API
  Map<String, dynamic> toUpdateBody() => {
    'rating': rating,
    if (BrewGuardrails.isPlausibleWaterTemp(waterTemp)) 'waterTemp': waterTemp,
    if (BrewGuardrails.positiveSeconds(timeTaken) != null)
      'timeTaken': timeTaken,
    'coffeeDose': coffeeDose,
    'waterWeightGrams': waterWeightGrams,
    'grindSetting': grindSetting,
    'bloomTimeSeconds': bloomTimeSeconds,
    'bloomWaterGrams': bloomWaterGrams,
    'pourCount': pourCount,
    'pourPattern': pourPattern,
    'agitation': {
      'swirled': agitationSwirled,
      'stirred': agitationStirred,
      'notes': agitationNotes,
    }..removeWhere((_, v) => v == null),
    'filterType': filterType,
    'brewer': {'size': brewerSize, 'material': brewerMaterial}
      ..removeWhere((_, v) => v == null),
    'grinder': {
      'model': grinderModel,
      'burrs': grinderBurrs,
      'grindScale': grinderGrindScale,
    }..removeWhere((_, v) => v == null),
    'water': {'source': waterSource, 'profile': waterProfile}
      ..removeWhere((_, v) => v == null),
    'drawdownTimeSeconds': drawdownTimeSeconds,
    'notes': notes,
    'tastingFeedback': tastingFeedback,
    'aiFeedback': aiFeedback,
    'aiFeedbackGeneratedAt': aiFeedbackGeneratedAt?.toIso8601String(),
    'aiFeedbackModel': aiFeedbackModel,
    'guidedAdjustment': guidedAdjustment,
    'plannedAdjustment': plannedAdjustment,
    'comparisonSourceEntryId': comparisonSourceEntryId,
    'comparisonResult': comparisonResult,
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

    bool? parseBool(dynamic v) {
      if (v is bool) return v;
      if (v is String) return v.toLowerCase() == 'true';
      return null;
    }

    final agitation = parseMap(j['agitation']);
    final brewer = parseMap(j['brewer']);
    final grinder = parseMap(j['grinder']);
    final waterProfileMap = parseMap(j['water']);

    return JournalEntry(
      id: j['id'] as String? ?? '',
      rating: parseDouble(j['rating']),
      waterTemp: (j['waterTemp'] as num?)?.toInt(),
      timeTaken: (j['timeTaken'] as num?)?.toInt(),
      coffeeDose: j['coffeeDose'] as String?,
      waterWeightGrams: parseDouble(j['waterWeightGrams']),
      grindSetting: j['grindSetting'] as String?,
      bloomTimeSeconds: (j['bloomTimeSeconds'] as num?)?.toInt(),
      bloomWaterGrams: parseDouble(j['bloomWaterGrams']),
      pourCount: (j['pourCount'] as num?)?.toInt(),
      pourPattern: j['pourPattern'] as String?,
      agitationSwirled: parseBool(agitation?['swirled']),
      agitationStirred: parseBool(agitation?['stirred']),
      agitationNotes: agitation?['notes'] as String?,
      filterType: j['filterType'] as String?,
      brewerSize: brewer?['size'] as String?,
      brewerMaterial: brewer?['material'] as String?,
      grinderModel: grinder?['model'] as String?,
      grinderBurrs: grinder?['burrs'] as String?,
      grinderGrindScale: grinder?['grindScale'] as String?,
      waterSource: waterProfileMap?['source'] as String?,
      waterProfile: waterProfileMap?['profile'] as String?,
      drawdownTimeSeconds: (j['drawdownTimeSeconds'] as num?)?.toInt(),
      notes: j['notes'] as String?,
      tastingFeedback: parseMap(j['tastingFeedback']),
      aiFeedback: parseMap(j['aiFeedback']),
      aiFeedbackGeneratedAt: j['aiFeedbackGeneratedAt'] is String
          ? DateTime.tryParse(j['aiFeedbackGeneratedAt'] as String)
          : null,
      aiFeedbackModel: j['aiFeedbackModel'] as String?,
      guidedAdjustment: parseMap(j['guidedAdjustment']),
      plannedAdjustment: parseMap(j['plannedAdjustment']),
      comparisonSourceEntryId: j['comparisonSourceEntryId'] as String?,
      comparisonResult: parseMap(j['comparisonResult']),
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
    if (BrewGuardrails.isPlausibleWaterTemp(waterTemp)) 'waterTemp': waterTemp,
    if (BrewGuardrails.positiveSeconds(timeTaken) != null)
      'timeTaken': timeTaken,
    'coffeeDose': coffeeDose,
    'waterWeightGrams': waterWeightGrams,
    'grindSetting': grindSetting,
    'bloomTimeSeconds': bloomTimeSeconds,
    'bloomWaterGrams': bloomWaterGrams,
    'pourCount': pourCount,
    'pourPattern': pourPattern,
    'agitation': {
      'swirled': agitationSwirled,
      'stirred': agitationStirred,
      'notes': agitationNotes,
    }..removeWhere((_, v) => v == null),
    'filterType': filterType,
    'brewer': {'size': brewerSize, 'material': brewerMaterial}
      ..removeWhere((_, v) => v == null),
    'grinder': {
      'model': grinderModel,
      'burrs': grinderBurrs,
      'grindScale': grinderGrindScale,
    }..removeWhere((_, v) => v == null),
    'water': {'source': waterSource, 'profile': waterProfile}
      ..removeWhere((_, v) => v == null),
    'drawdownTimeSeconds': drawdownTimeSeconds,
    'notes': notes,
    'tastingFeedback': tastingFeedback,
    'aiFeedback': aiFeedback,
    'aiFeedbackGeneratedAt': aiFeedbackGeneratedAt?.toIso8601String(),
    'aiFeedbackModel': aiFeedbackModel,
    'guidedAdjustment': guidedAdjustment,
    'plannedAdjustment': plannedAdjustment,
    'comparisonSourceEntryId': comparisonSourceEntryId,
    'comparisonResult': comparisonResult,
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
    int? bloomTimeSeconds,
    double? bloomWaterGrams,
    int? pourCount,
    String? pourPattern,
    bool? agitationSwirled,
    bool? agitationStirred,
    String? agitationNotes,
    String? filterType,
    String? brewerSize,
    String? brewerMaterial,
    String? grinderModel,
    String? grinderBurrs,
    String? grinderGrindScale,
    String? waterSource,
    String? waterProfile,
    int? drawdownTimeSeconds,
    String? notes,
    Map<String, dynamic>? tastingFeedback,
    Map<String, dynamic>? aiFeedback,
    DateTime? aiFeedbackGeneratedAt,
    String? aiFeedbackModel,
    Map<String, dynamic>? guidedAdjustment,
    Map<String, dynamic>? plannedAdjustment,
    String? comparisonSourceEntryId,
    Map<String, dynamic>? comparisonResult,
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
      bloomTimeSeconds: bloomTimeSeconds ?? this.bloomTimeSeconds,
      bloomWaterGrams: bloomWaterGrams ?? this.bloomWaterGrams,
      pourCount: pourCount ?? this.pourCount,
      pourPattern: pourPattern ?? this.pourPattern,
      agitationSwirled: agitationSwirled ?? this.agitationSwirled,
      agitationStirred: agitationStirred ?? this.agitationStirred,
      agitationNotes: agitationNotes ?? this.agitationNotes,
      filterType: filterType ?? this.filterType,
      brewerSize: brewerSize ?? this.brewerSize,
      brewerMaterial: brewerMaterial ?? this.brewerMaterial,
      grinderModel: grinderModel ?? this.grinderModel,
      grinderBurrs: grinderBurrs ?? this.grinderBurrs,
      grinderGrindScale: grinderGrindScale ?? this.grinderGrindScale,
      waterSource: waterSource ?? this.waterSource,
      waterProfile: waterProfile ?? this.waterProfile,
      drawdownTimeSeconds: drawdownTimeSeconds ?? this.drawdownTimeSeconds,
      notes: notes ?? this.notes,
      tastingFeedback: tastingFeedback ?? this.tastingFeedback,
      aiFeedback: aiFeedback ?? this.aiFeedback,
      aiFeedbackGeneratedAt:
          aiFeedbackGeneratedAt ?? this.aiFeedbackGeneratedAt,
      aiFeedbackModel: aiFeedbackModel ?? this.aiFeedbackModel,
      guidedAdjustment: guidedAdjustment ?? this.guidedAdjustment,
      plannedAdjustment: plannedAdjustment ?? this.plannedAdjustment,
      comparisonSourceEntryId:
          comparisonSourceEntryId ?? this.comparisonSourceEntryId,
      comparisonResult: comparisonResult ?? this.comparisonResult,
      beans: beans ?? this.beans,
      recipe: recipe ?? this.recipe,
      beansId: beansId ?? this.beansId,
      recipeId: recipeId ?? this.recipeId,
      date: date ?? this.date,
    );
  }
}
