import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:v60pal/models/JournalEntry.dart';
import 'dart:convert';




// 2A.1: Locate your journal file
Future<File> get _journalFile async {
  final dir = await getApplicationDocumentsDirectory();
  final path = '${dir.path}/v60_journal.json';
  print('📂 Journal file path: $path');
  return File(path);
}

// 2A.2: Read and decode (returns an empty list if file not found or broken)
Future<List<JournalEntry>> loadEntries() async {
  try {
    final file = await _journalFile;
    if (!await file.exists()) {
      print('⚠️ No journal file found, returning empty list');
      return [];
    }
    final contents = await file.readAsString();
    print('Loaded json $contents');
    final List<dynamic> jsonList = jsonDecode(contents);
    return jsonList
        .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e) {
    print("Missing file");
    return [];
  }
}

// 2A.3: Write the full list back to disk
Future<void> saveEntries(List<JournalEntry> entries) async {
  final file = await _journalFile;
  final jsonList = entries.map((e) => e.toJson()).toList();
  await file.writeAsString(jsonEncode(jsonList));
}

Future<void> clearJournalFile() async {
  final file = await _journalFile;
  // Overwrite with empty JSON array
  await file.writeAsString(jsonEncode(<dynamic>[]));
}
