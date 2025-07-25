import 'package:flutter/material.dart';
import 'package:v60pal/models/Beans.dart';
import 'package:v60pal/models/JournalEntry.dart';
import 'package:v60pal/models/Recipe.dart';
import 'ApiService.dart';

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

  void _saveEntry() async {
    final newEntry = JournalEntry(
      id: '', // server will assign
      rating: '5',
      waterTemp: 93,
      timeTaken: 180,
      grindSetting: 'Medium-Fine',
      notes: 'Tasted bright and sweet.',
      beans: selectedBeans,
      recipe: selectedRecipe,
    );
    final saved = await ApiService().createJournalEntry(newEntry);
    setState(() => journalEntries.add(saved));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton( onPressed: _saveEntry, child: Icon(Icons.abc),),
    );
  }
}
