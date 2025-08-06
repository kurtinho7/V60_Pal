import 'package:flutter/material.dart';
import 'package:v60pal/Theme.dart';

class JournalEntryViewScreen extends StatefulWidget {
  @override
  State<JournalEntryViewScreen> createState() => _JournalEntryViewScreenState();
}

class _JournalEntryViewScreenState extends State<JournalEntryViewScreen> {
  @override
  Widget build(BuildContext context) {
    return Text('You are looking at journal entry', style: TextStyle(color: TEXT_COLOR, fontSize: 10),);
  }
}