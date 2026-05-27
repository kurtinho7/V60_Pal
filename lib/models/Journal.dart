import 'package:firebase_auth/firebase_auth.dart';
import 'package:v60pal/ApiClient.dart';
import 'package:v60pal/models/JournalEntry.dart';
import 'package:v60pal/persistence/JournalStorage.dart';
import 'package:flutter/foundation.dart';
import 'package:v60pal/services/JournalEntryService.dart';

class Journal extends ChangeNotifier {
  List<JournalEntry> _entries = [];

  List<JournalEntry> get entries => List.unmodifiable(_entries);

  Future<void> init() async {
    if (FirebaseAuth.instance.currentUser == null) {
      try {
        _entries = await loadEntries();
      } catch (e) {
        debugPrint('Journal local load failed: $e');
        _entries = [];
      }
    } else {
      final api = ApiClient(apiBaseUrl); // replace in prod
      final journalSvc = JournalService(api);
      final list = await journalSvc.list(); // returns List<Map<String,dynamic>>
      final mapped = list.map((m) => JournalEntry.fromApi(m)).toList();
      _entries = mapped;
    } // or loadEntriesFromPrefs()
    notifyListeners();
  }

  Future<void> addEntry(JournalEntry entry) async {
    _entries.add(entry);
    notifyListeners();
    try {
      await saveEntries(_entries); // or saveEntriesToPrefs
    } catch (e) {
      debugPrint('Journal local persistence failed: $e');
    }
  }

  Future<void> removeEntry(int i) async {
    _entries.removeAt(i);
    notifyListeners();
    try {
      await saveEntries(_entries);
    } catch (e) {
      debugPrint('Journal local persistence failed: $e');
    }
  }

  Future<void> updateEntry(JournalEntry entry) async {
    final index = _entries.indexWhere((existing) {
      if (entry.id.isNotEmpty && existing.id == entry.id) return true;
      return existing.date == entry.date;
    });

    if (index == -1) {
      _entries.add(entry);
    } else {
      _entries[index] = entry;
    }

    notifyListeners();
    try {
      await saveEntries(_entries);
    } catch (e) {
      debugPrint('Journal local persistence failed: $e');
    }
  }

  // You can also add update/remove methods similarly...
}
