import 'package:hive/hive.dart';
import 'package:v60pal/models/Recipe.dart';
import 'package:v60pal/models/Beans.dart';
import 'dart:convert';

class JournalEntry{
  String id;
  String rating;

  int waterTemp;

  int timeTaken;

  String grindSetting;

  String notes;

  Beans beans;

  Recipe recipe;

  DateTime date;

  JournalEntry({
    required this.id,
    required this.rating,
    required this.waterTemp,
    required this.timeTaken,
    required this.grindSetting,
    required this.notes,
    required this.beans,
    required this.recipe,
    required this.date,
  });

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
    'beans':       beans.toJson(),   // send only the ID if your API expects ref
    'recipe':      recipe.toJson(),  // same here
    'date': date.toIso8601String(),
  };

  String toJsonString() => jsonEncode(toJson());


}

