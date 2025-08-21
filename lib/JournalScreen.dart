import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:v60pal/JournalEntryViewScreen.dart';
import 'package:v60pal/Theme.dart';
import 'package:v60pal/models/JournalEntry.dart';
import 'package:v60pal/models/Journal.dart';
import 'package:v60pal/services/BeansService.dart';
import 'package:v60pal/services/JournalEntryService.dart';

import 'ApiClient.dart';
import 'package:provider/provider.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  List<JournalEntry> journalEntries = [];

  late final ApiClient api;
  late final BeansService beansSvc;
  late final JournalService journalSvc;
  bool loading = true;

  String? error;
  @override
  void initState() {
    super.initState();
    api = ApiClient('http://10.0.2.2:3000'); // replace in prod
    beansSvc = BeansService(api);
    journalSvc = JournalService(api);
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final list = await journalSvc.list(); // returns List<Map<String,dynamic>>
      final mapped = list.map((m) => JournalEntry.fromApi(m)).toList();
      if (!mounted) return;
      setState(() { journalEntries = mapped; });
    } catch (e) {
      if (!mounted) return;
      setState(() { error = e.toString(); });
    } finally {
      if (!mounted) return;
      setState(() { loading = false; });
    }
  }

  Future<void> _deleteAt(int index) async {
    final id = journalEntries[index].id;
    // Optimistic UI (remove first), or do it after API success—your call.
    final removed = journalEntries[index];
    setState(() { journalEntries.removeAt(index); });
    try {
      await journalSvc.delete(id);
    } catch (e) {
      // rollback on failure
      setState(() {
        journalEntries.insert(index, removed);
        error = 'Delete failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final journal = Provider.of<Journal>(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: journal.entries.length,
          itemBuilder: (_, i) {
            final reversedIndex = journal.entries.length - 1 - i;
            final entry = journal.entries[reversedIndex];
            final recipeId = entry.recipeId ?? 'Custom recipe';
            return Dismissible(
              dismissThresholds: {DismissDirection.endToStart: 0.45},
              direction: DismissDirection.endToStart,
              key: Key(entry.date.toIso8601String()),
              onDismissed: (direction) async {
                await journal.removeEntry(reversedIndex);
                await _deleteAt(reversedIndex);
              },
              background: Container(),
              secondaryBackground: Container(
                padding: EdgeInsets.all(20),
                alignment: Alignment.centerRight,
                color: Colors.red,
                child: Text(
                  "Delete Entry",
                  style: TextStyle(color: TEXT_COLOR),
                ),
              ),
              child: Material(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(
                      '${MONTHS[entry.date.month]} ${entry.date.day}',
                      style: TextStyle(color: Colors.white70),
                    ),
                    subtitle: Text(recipeId),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusGeometry.circular(8),
                    ),
                    horizontalTitleGap: 20,
                    tileColor: BUTTON_COLOR,
                    minTileHeight: 80,
                    onTap: () {
                      Navigator.push(
                        context,
                        ModalBottomSheetRoute(
                          builder: (context) =>
                              JournalEntryViewScreen(journalEntry: entry),
                          isScrollControlled: true,
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
