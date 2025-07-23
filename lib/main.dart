import 'dart:async';

import 'package:flutter/material.dart';
import 'package:v60pal/BeansScreen.dart';
import 'package:v60pal/BrewScreen.dart';
import 'package:v60pal/BrewTimerPage.dart';
import 'package:v60pal/JournalScreen.dart';
import 'package:v60pal/TimerScreen.dart';
import 'package:v60pal/models/Recipe.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int selectedIndex = 0;

  // List of screens to display
  final List<Widget> screens = [BrewScreen(), JournalScreen(), BeansScreen()];

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(textTheme: GoogleFonts.poppinsTextTheme()),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Brew"),
          backgroundColor: Colors.amber,
          centerTitle: true,
        ),
        body: screens[selectedIndex], // Display selected screen
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.coffee_maker_outlined),
              label: "Brew",
            ),
            BottomNavigationBarItem(icon: Icon(Icons.book), label: "Journal"),
            BottomNavigationBarItem(
              icon: Icon(Icons.free_breakfast_rounded),
              label: "Beans",
            ),
          ],
        ),
      ),
    );
  }
}
