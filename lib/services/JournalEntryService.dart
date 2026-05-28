import 'dart:convert';
import 'package:v60pal/models/BrewGuardrails.dart';
import '../ApiClient.dart';

class JournalService {
  JournalService(this.api);
  final ApiClient api;

  Future<List<Map<String, dynamic>>> list() async {
    final res = await api.get('/journalEntries');
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    }
    throw Exception('Journal list failed: ${res.statusCode} ${res.body}');
  }

  Future<Map<String, dynamic>> create({
    required double rating,
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
    Map<String, dynamic>? guidedAdjustment,
    Map<String, dynamic>? plannedAdjustment,
    String? comparisonSourceEntryId,
    Map<String, dynamic>? comparisonResult,
    String? beansId, // Mongo _id for a Beans doc you own
    String? recipeId, // Mongo _id for a Recipe doc
    DateTime? date,
  }) async {
    final body = {
      'rating': rating,
      if (BrewGuardrails.isPlausibleWaterTemp(waterTemp))
        'waterTemp': waterTemp,
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
      if (drawdownTimeSeconds != null)
        'drawdownTimeSeconds': drawdownTimeSeconds,
      if (notes != null) 'notes': notes,
      if (tastingFeedback != null) 'tastingFeedback': tastingFeedback,
      if (guidedAdjustment != null) 'guidedAdjustment': guidedAdjustment,
      if (plannedAdjustment != null) 'plannedAdjustment': plannedAdjustment,
      if (comparisonSourceEntryId != null)
        'comparisonSourceEntryId': comparisonSourceEntryId,
      if (comparisonResult != null) 'comparisonResult': comparisonResult,
      if (beansId != null) 'beans': beansId,
      if (recipeId != null) 'recipe': recipeId,
      if (date != null) 'date': date.toIso8601String(),
    };

    final res = await api.post('/journalEntries', body);
    if (res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>; // populated
    }
    throw Exception('Create journal failed: ${res.statusCode} ${res.body}');
  }

  Future<Map<String, dynamic>> generateAiFeedback(
    String entryId, {
    Map<String, dynamic>? recipeContext,
  }) async {
    final res = await api.post('/journalEntries/$entryId/ai-feedback', {
      if (recipeContext != null) 'recipeContext': recipeContext,
    });
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('AI feedback failed: ${res.statusCode} ${res.body}');
  }

  Future<Map<String, dynamic>?> getAiProfile() async {
    final res = await api.get('/journalEntries/ai-profile');
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded == null) return null;
      return decoded as Map<String, dynamic>;
    }
    throw Exception('AI profile failed: ${res.statusCode} ${res.body}');
  }

  Future<void> delete(String id) async {
    final res = await api.delete('/journalEntries/$id');
    if (res.statusCode != 204) {
      throw Exception('Delete failed: ${res.statusCode} ${res.body}');
    }
  }
}
