import 'package:v60pal/models/JournalEntry.dart';
import 'package:v60pal/persistence/JournalStorage.dart';
import 'package:flutter/foundation.dart';

class Journal extends ChangeNotifier {
  List<JournalEntry> _entries = [];

  List<JournalEntry> get entries => List.unmodifiable(_entries);

  Future<void> init() async {
    _entries = await loadEntries(); // or loadEntriesFromPrefs()
    notifyListeners();
  }

  Future<void> addEntry(JournalEntry entry) async {
    _entries.add(entry);
    await saveEntries(_entries); // or saveEntriesToPrefs
    notifyListeners();
  }

  // You can also add update/remove methods similarly...
}