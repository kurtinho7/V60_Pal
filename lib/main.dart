import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:v60pal/AddBeansScreen.dart';
import 'package:v60pal/AddJournalEntryScreen.dart';
import 'package:v60pal/AuthGate.dart';
import 'package:v60pal/BeansScreen.dart';
import 'package:v60pal/BrewScreen.dart';
import 'package:v60pal/JournalScreen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:v60pal/models/BeansList.dart';
import 'package:v60pal/models/Journal.dart';
import 'package:v60pal/Theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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

  final List<Widget> screens = const [
    BrewScreen(),
    JournalScreen(),
    BeansScreen(),
  ];

  final List<String> screenNames = ["Brew", "Journal", "Beans"];

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: BACKGROUND_COLOR,
        textTheme: GoogleFonts.overpassTextTheme().copyWith(
          headlineMedium: GoogleFonts.overpass(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: TEXT_COLOR,
          ),
          titleLarge: GoogleFonts.overpass(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: TEXT_COLOR,
          ),
          titleMedium: GoogleFonts.overpass(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: TEXT_COLOR,
          ),
          bodyMedium: GoogleFonts.overpass(color: TEXT_COLOR),
        ),
        colorScheme: COLOR_SCHEME,
        elevatedButtonTheme: ELEVATED_BUTTON_THEME,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: PRIMARY_COLOR,
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(APP_RADIUS),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: PRIMARY_COLOR,
            side: BorderSide(color: OUTLINE_COLOR),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(APP_RADIUS),
            ),
          ),
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: BACKGROUND_COLOR,
          foregroundColor: TEXT_COLOR,
          centerTitle: false,
          titleTextStyle: GoogleFonts.overpass(
            color: TEXT_COLOR,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 72,
          backgroundColor: SURFACE_COLOR,
          indicatorColor: BUTTON_COLOR,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => GoogleFonts.overpass(
              color: states.contains(WidgetState.selected)
                  ? PRIMARY_COLOR
                  : MUTED_TEXT_COLOR,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? PRIMARY_COLOR
                  : MUTED_TEXT_COLOR,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: SURFACE_TINT_COLOR.withValues(alpha: 0.55),
          labelStyle: TextStyle(color: MUTED_TEXT_COLOR),
          hintStyle: TextStyle(color: MUTED_TEXT_COLOR.withValues(alpha: 0.75)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(APP_RADIUS),
            borderSide: BorderSide(color: OUTLINE_COLOR),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(APP_RADIUS),
            borderSide: BorderSide(color: OUTLINE_COLOR),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(APP_RADIUS),
            borderSide: BorderSide(color: PRIMARY_COLOR, width: 1.5),
          ),
        ),
        cardTheme: CardThemeData(
          color: SURFACE_COLOR,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(APP_RADIUS),
            side: BorderSide(color: OUTLINE_COLOR),
          ),
        ),
        drawerTheme: DrawerThemeData(backgroundColor: BACKGROUND_COLOR),
        dialogTheme: DialogThemeData(
          backgroundColor: SURFACE_COLOR,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(APP_RADIUS),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: TEXT_COLOR,
          contentTextStyle: const TextStyle(color: Colors.white),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(APP_RADIUS),
          ),
        ),
      ),
      home: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: Text(screenNames[selectedIndex]),
              actions: [
                if (selectedIndex == 1)
                  IconButton(
                    tooltip: 'Add journal entry',
                    icon: const Icon(Icons.add_circle_outline),
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
                    tooltip: 'Add beans',
                    icon: const Icon(Icons.add_circle_outline),
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
                padding: EdgeInsets.zero, // no extra padding from ListView
                children: [
                  Container(
                    color: BUTTON_COLOR,
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 22),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Settings',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),

                  StreamBuilder(
                    stream: auth.authStateChanges(),
                    initialData: auth.currentUser,
                    builder: (context, snap) {
                      final user = snap.data;
                      final signInText = user?.email ?? 'Sign In';
                      return ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(signInText),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AuthGate(
                                showSignOutWhenSignedIn: user != null,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            body: screens[selectedIndex], // Display selected screen
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onItemTapped,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.coffee_maker_outlined),
                  selectedIcon: Icon(Icons.coffee_maker),
                  label: 'Brew',
                ),
                NavigationDestination(
                  icon: Icon(Icons.book_outlined),
                  selectedIcon: Icon(Icons.book),
                  label: 'Journal',
                ),
                NavigationDestination(
                  icon: Icon(Icons.local_cafe_outlined),
                  selectedIcon: Icon(Icons.local_cafe),
                  label: 'Beans',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
