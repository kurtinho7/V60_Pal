import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:v60pal/AddBeansScreen.dart';
import 'package:v60pal/AddJournalEntryScreen.dart';
import 'package:v60pal/BeansScreen.dart';
import 'package:v60pal/BrewScreen.dart';
import 'package:v60pal/JournalScreen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:v60pal/models/BeansList.dart';
import 'package:v60pal/models/Journal.dart';
import 'package:v60pal/Theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final journal = Journal();
  final beansList = BeansList();
  await journal.init();
  await beansList.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<Journal>.value(value: journal),
        ChangeNotifierProvider<BeansList>.value(value: beansList),
      ],
      child: MyApp(),
    ),
  );
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

  final List<String> screenNames = ["Brew", "Journal", "Beans"];

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        colorScheme: COLOR_SCHEME,
        elevatedButtonTheme: ELEVATED_BUTTON_THEME,
      ),
      home: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                screenNames[selectedIndex],
                style: TextStyle(color: Colors.black87, fontSize: 32),
              ),
              backgroundColor: Colors.blueAccent,
              centerTitle: false,
              actions: [
                // if (selectedIndex == 0)
                //   IconButton(
                //     icon: Icon(Icons.menu),
                //     onPressed: () {
                //       Scaffold.of(context).openDrawer();
                //     },
                //   ),
                if (selectedIndex == 1)
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddJournalEntryScreen(),
                        ),
                      );
                    },
                  ),
                if (selectedIndex == 2)
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddBeansScreen(),
                        ),
                      );
                    },
                  ),
              ],
            ),
            endDrawer: Drawer(
              child: ListView(
                children: [
                  DrawerHeader(
                    child: Text(
                      'Settings',
                      style: TextStyle(color: TEXT_COLOR),
                    ),
                  ),
                ],
              ),
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
                BottomNavigationBarItem(
                  icon: Icon(Icons.book),
                  label: "Journal",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.free_breakfast_rounded),
                  label: "Beans",
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
