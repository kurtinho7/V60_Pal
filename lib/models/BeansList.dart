import 'package:flutter/material.dart';
import 'package:v60pal/models/Beans.dart';
import 'package:v60pal/persistence/BeansStorage.dart';
import 'package:flutter/foundation.dart';

class BeansList extends ChangeNotifier{
  List<Beans> _entries = [];

  List<Beans> get entries => List.unmodifiable(_entries);

  Future<void> init() async {
    _entries = await loadEntries(); // or loadEntriesFromPrefs()
    notifyListeners();
  }

  Future<void> addEntry(Beans beans) async {
    _entries.add(beans);
    await saveEntries(_entries); // or saveEntriesToPrefs
    notifyListeners();
  }

}