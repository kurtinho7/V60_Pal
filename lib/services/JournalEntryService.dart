import 'dart:convert';
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
    String? notes,
    String? beansId, // Mongo _id for a Beans doc you own
    String? recipeId, // Mongo _id for a Recipe doc
    DateTime? date,
  }) async {
    final body = {
      'rating': rating,
      if (waterTemp != null) 'waterTemp': waterTemp,
      if (timeTaken != null) 'timeTaken': timeTaken,
      if (coffeeDose != null) 'coffeeDose': coffeeDose,
      if (waterWeightGrams != null) 'waterWeightGrams': waterWeightGrams,
      if (grindSetting != null) 'grindSetting': grindSetting,
      if (notes != null) 'notes': notes,
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
