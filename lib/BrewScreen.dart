import 'package:flutter/material.dart';
import 'package:v60pal/Theme.dart';
import 'package:v60pal/models/Recipe.dart';
import 'package:v60pal/BrewTimerPage.dart';



class BrewScreen extends StatefulWidget {
  const BrewScreen({super.key});

  @override
  State<BrewScreen> createState() => _BrewScreenState();
}

class _BrewScreenState extends State<BrewScreen> {
  // Your six icons
  final List<IconData> _icons = [
    Icons.local_cafe,
    Icons.coffee_maker,
    Icons.free_breakfast,
    Icons.emoji_food_beverage,
    Icons.wb_twilight,
    Icons.thermostat,
    Icons.adb_rounded,
    Icons.accessible_forward_outlined,
    Icons.adjust,
  ];


  // Only one selected at a time; -1 means “none”
  int _selectedIndex = -1;

  void _onIconTap(int idx) {
    setState(() {
      // If you tap the already-selected icon, deselect it.
      // Otherwise, make this the one and only selection.
      _selectedIndex = (_selectedIndex == idx) ? -1 : idx;
    });
  }

  void _onBrewPressed() {
    if (_selectedIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a recipe first!"),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    // Do your brew action for _icons[_selectedIndex]…
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BrewTimerPage(recipe: RECIPES[_selectedIndex]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 60,
                crossAxisSpacing: 16,
                children: List.generate(RECIPES.length, (i) {
                  final selected = i == _selectedIndex;
                  return Column(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          fixedSize: const Size(80, 85),
                          backgroundColor: selected
                              ? Colors.blueAccent
                              : Colors.white10,
                          foregroundColor: selected
                              ? Colors.white
                              : Colors.white,
                        ),
                        onPressed: () => _onIconTap(i),
                        child: Icon(_icons[i], size: 32),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        RECIPES[i].name,
                        style: TextStyle(
                          fontSize: 12,
                          color: selected ? Colors.blueAccent : Colors.white54,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 220,
              child: RawMaterialButton(
                onPressed: _onBrewPressed,
                elevation: 2.0,
                fillColor: Colors.white10,
                constraints: BoxConstraints(minWidth: 300.0, minHeight: 300.0),
                padding: EdgeInsets.all(15.0),
                shape: CircleBorder(),
                child: Text('BREW', style: TextStyle(fontSize: 50, color: Colors.white),),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
