import 'package:hive/hive.dart';
import 'package:v60pal/models/Recipe.dart';
import 'package:v60pal/models/Beans.dart';

class JournalEntry{
  String id;
  String rating;

  int waterTemp;

  int timeTaken;

  String grindSetting;

  String notes;

  Beans beans;

  Recipe recipe;

  JournalEntry({
    required this.id,
    required this.rating,
    required this.waterTemp,
    required this.timeTaken,
    required this.grindSetting,
    required this.notes,
    required this.beans,
    required this.recipe,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> j) => JournalEntry(
    id: j['_id']['\$oid'],
    rating: j['rating'],
    waterTemp: (j['waterTemp'] as num).toInt(),
    timeTaken: (j['timeTaken'] as num).toInt(),
    grindSetting: j['grindSetting'],
    notes: j['notes'],
    beans: Beans.fromJson(j['beans']),
    recipe: Recipe.fromJson(j['recipe']),
  );

  Map<String, dynamic> toJson() => {
    'rating':      rating,
    'waterTemp':   waterTemp,
    'timeTaken':   timeTaken,
    'grindSetting': grindSetting,
    'notes':       notes,
    'beans':       beans.id,   // send only the ID if your API expects ref
    'recipe':      recipe.id,  // same here
  };
}

