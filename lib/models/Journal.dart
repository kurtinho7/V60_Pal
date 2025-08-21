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
      _entries = await loadEntries();
    } else {
      final api = ApiClient('http://10.0.2.2:3000'); // replace in prod
      final journalSvc = JournalService(api);
      final list = await journalSvc.list(); // returns List<Map<String,dynamic>>
      final mapped = list.map((m) => JournalEntry.fromApi(m)).toList();
      _entries = mapped;
    } // or loadEntriesFromPrefs()
    notifyListeners();
  }

  Future<void> addEntry(JournalEntry entry) async {
    _entries.add(entry);
    await saveEntries(_entries); // or saveEntriesToPrefs
    notifyListeners();
  }

  Future<void> removeEntry(int i) async {
    _entries.removeAt(i);
    await saveEntries(_entries);
    notifyListeners();
  }


  // You can also add update/remove methods similarly...
}
