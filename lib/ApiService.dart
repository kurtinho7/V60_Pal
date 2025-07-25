import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:v60pal/models/JournalEntry.dart';
import 'models/Recipe.dart';

class ApiService {
  final baseUrl = 'http://10.0.2.2:3000';

  Future<List<JournalEntry>> fetchJournalEntries() async {
    final res = await http.get(Uri.parse('$baseUrl/journalEntries'));
    if (res.statusCode != 200) throw Exception('Failed to load');
    final List data = jsonDecode(res.body);
    return data.map((json) => JournalEntry.fromJson(json)).toList();
  }

  Future<JournalEntry> fetchJournalEntry(String id) async {
    final res = await http.get(Uri.parse('$baseUrl/journalEntries/$id'));
    if (res.statusCode != 200) throw Exception('Not found');
    return JournalEntry.fromJson(jsonDecode(res.body));
  }

  Future<JournalEntry> createJournalEntry(JournalEntry entry) async {
  final uri = Uri.parse('$baseUrl/journalEntries');
  try {
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(entry.toJson()),
    );

    print('POST $uri → ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 201) {
      throw Exception(
        'Failed to create JournalEntry (status ${response.statusCode}): '
        '${response.body}',
      );
    }
    return JournalEntry.fromJson(jsonDecode(response.body));
  } catch (e, st) {
    print('Error in createJournalEntry: $e\n$st');
    rethrow;  // so you still see it in your UI/logcat
  }
}
}
