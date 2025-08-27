import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:v60pal/ApiClient.dart';
import 'package:v60pal/models/Beans.dart';
import 'package:v60pal/persistence/BeansStorage.dart';
import 'package:flutter/foundation.dart';
import 'package:v60pal/services/BeansService.dart';

class BeansList extends ChangeNotifier{
  List<Beans> _entries = [];

  List<Beans> get entries => List.unmodifiable(_entries);

  Future<void> init() async {
    if (FirebaseAuth.instance.currentUser == null) {
      _entries = await loadEntries();
    } else {
      final api = ApiClient('http://10.0.2.2:3000'); // replace in prod
      final journalSvc = BeansService(api);
      final list = await journalSvc.list(); // returns List<Map<String,dynamic>>
      final mapped = list.map((m) => Beans.fromApi(m)).toList();
      _entries = mapped;
    } // or loadEntriesFromPrefs()
    notifyListeners();
  }

  Future<void> addEntry(Beans beans) async {
    _entries.add(beans);
    await saveEntries(_entries); // or saveEntriesToPrefs
    notifyListeners();
  }

  Future<void> removeEntry(String id) async {
    _entries.removeWhere((element) => element.id == id);
    await saveEntries(_entries);
    notifyListeners();
  }

  Future<void> editEntry(String id, int newWeight) async {
    final entry = _entries.firstWhere((element) => element.id == id);
    Beans editedBeans = entry.copyWith(newWeight);
    removeEntry(id);
    addEntry(editedBeans);
    notifyListeners();
  }

}