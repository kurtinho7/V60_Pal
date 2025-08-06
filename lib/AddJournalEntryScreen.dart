import 'package:flutter/material.dart';
import 'package:v60pal/Theme.dart';
class AddJournalEntryScreen extends StatefulWidget {
  @override
  State<AddJournalEntryScreen> createState() => _AddJournalEntryScreenState();
}

class _AddJournalEntryScreenState extends State<AddJournalEntryScreen> {
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Text('Journal', style: TextStyle(color: TEXT_COLOR),),
    );
  }
}