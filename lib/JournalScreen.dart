import 'package:flutter/material.dart';
import 'package:v60pal/AddJournalEntryScreen.dart';
import 'package:v60pal/JournalEntryViewScreen.dart';
import 'package:v60pal/Theme.dart';
import 'package:v60pal/models/Beans.dart';
import 'package:v60pal/models/BeansList.dart';
import 'package:v60pal/models/JournalEntry.dart';
import 'package:v60pal/models/Recipe.dart';
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
  Beans selectedBeans = Beans(
    id: '1234',
    name: "Johan",
    origin: "Venezuela",
    roastLevel: "medium",
  );
  Recipe selectedRecipe = Recipe(
    id: '4567',
    name: "4:6",
    waterWeightGrams: 225,
    waterTemp: 45,
    pourSteps: [45, 45, 45, 45, 45],
    coffeeDose: "15g",
    grindSize: "fine",
    brewTime: "1:50",
    pourAmounts: [45, 45, 45, 45, 45],
  );
  @override
  void initState() {
    super.initState();
    ApiService().fetchJournalEntries().then((list) {
      setState(() => journalEntries = list);
    });
  }

  void saveEntry() async {
    final newEntry = JournalEntry(
      id: '', // server will assign
      rating: '5',
      waterTemp: 93,
      timeTaken: 180,
      grindSetting: 'Medium-Fine',
      notes: 'Tasted bright and sweet.',
      beans: selectedBeans,
      recipe: selectedRecipe,
      date: DateTime.now(),
    );
    final saved = await ApiService().createJournalEntry(newEntry);
    setState(() => journalEntries.add(saved));
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
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(
                  '${MONTHS[entry.date.month]} ${entry.date.day}',
                  style: TextStyle(color: Colors.white70),
                ),
                subtitle: Text(entry.recipe.name),
                shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(8), ),
                horizontalTitleGap: 20,
                tileColor: BUTTON_COLOR,
                minTileHeight: 80,
                onTap: () {
                  Navigator.push(context, ModalBottomSheetRoute(builder: (context) => JournalEntryViewScreen(journalEntry: entry,), isScrollControlled: true,));
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
