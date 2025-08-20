import 'package:flutter/material.dart';
import 'package:v60pal/JournalEntryViewScreen.dart';
import 'package:v60pal/Theme.dart';
import 'package:v60pal/models/JournalEntry.dart';
import 'package:v60pal/models/Journal.dart';
import 'ApiService.dart';
import 'package:provider/provider.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  List<JournalEntry> journalEntries = [];
  @override
  void initState() {
    super.initState();
    ApiService().fetchJournalEntries().then((list) {
      setState(() => journalEntries = list);
    });
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
            final entry = journal.entries[i];
            return Dismissible(
              dismissThresholds: {DismissDirection.endToStart: 0.45},
              direction: DismissDirection.endToStart,
              key: Key(entry.date.toIso8601String()),
              onDismissed: (direction) async {
                await journal.removeEntry(i);
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
                    subtitle: Text(entry.recipe.name),
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
