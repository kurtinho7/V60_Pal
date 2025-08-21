import 'package:v60pal/models/Recipe.dart';
import 'package:v60pal/models/Beans.dart';
import 'dart:convert';

class JournalEntry{
  /// Mongo _id
  final String id;

  /// Store rating as int (Mongo typically uses Number)
  final double? rating;

  /// Optional fields (server may omit them)
  final int? waterTemp;
  final int? timeTaken;
  final String? grindSetting;
  final String? notes;

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
    this.grindSetting,
    this.notes,
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

    // rating might be int/double/string — normalize to int
    int parseRating(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    // beans: could be ObjectId string or populated object
    String? beansId;
    Beans? beansObj;
    final beansField = j['beans'];
    if (beansField is String) {
      beansId = beansField;
    } else if (beansField is Map<String, dynamic>) {
      beansObj = Beans.fromJson(beansField);
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

    return JournalEntry(
      id: id,
      rating: double.parse(j['rating'] as String),
      waterTemp: (j['waterTemp'] as num?)?.toInt(),
      timeTaken: (j['timeTaken'] as num?)?.toInt(),
      grindSetting: j['grindSetting'] as String?,
      notes: j['notes'] as String?,
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
        if (grindSetting != null) 'grindSetting': grindSetting,
        if (notes != null) 'notes': notes,
        if (beansId != null) 'beans': beansId,     // send only the id
        if (recipeId != null) 'recipe': recipeId,  // send only the id
        'date': date.toIso8601String(),
      };

  /// Body for UPDATE requests to your API
  Map<String, dynamic> toUpdateBody() => {
        'rating': rating,
        'waterTemp': waterTemp,
        'timeTaken': timeTaken,
        'grindSetting': grindSetting,
        'notes': notes,
        'beans': beansId,
        'recipe': recipeId,
        'date': date.toIso8601String(),
      }..removeWhere((_, v) => v == null);

  factory JournalEntry.fromJson(Map<String, dynamic> j) => JournalEntry(
    id: j['id'],
    rating: j['rating'],
    waterTemp: (j['waterTemp'] as num).toInt(),
    timeTaken: (j['timeTaken'] as num).toInt(),
    grindSetting: j['grindSetting'],
    notes: j['notes'],
    beans: Beans.fromJson(j['beans']as Map<String,dynamic>),
    recipe: Recipe.fromJson(j['recipe']as Map<String,dynamic>),
    date: DateTime.parse(j['date'] as String), 
  );

  Map<String, dynamic> toJson() => {
    'id':     id,
    'rating':      rating,
    'waterTemp':   waterTemp,
    'timeTaken':   timeTaken,
    'grindSetting': grindSetting,
    'notes':       notes,
    'beans':       beans,   // send only the ID if your API expects ref
    'recipe':      recipe,  // same here
    'date': date.toIso8601String(),
  };

  String toJsonString() => jsonEncode(toJson());


}

