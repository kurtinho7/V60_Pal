import 'package:flutter/material.dart';
import 'package:v60pal/TimerScreen.dart';
import 'package:v60pal/main.dart';
import 'package:v60pal/models/Recipe.dart';

class BrewTimerPage extends StatefulWidget {
  final Recipe recipe;

  const BrewTimerPage({super.key, required this.recipe});

  @override
  State<BrewTimerPage> createState() => _BrewTimerPageState();
}

class _BrewTimerPageState extends State<BrewTimerPage> {
  void _onStartPress() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimerScreen(recipe: widget.recipe),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String name = widget.recipe.name;
    double water = widget.recipe.waterWeightGrams;
    String dose = widget.recipe.coffeeDose;
    List<int> pourSteps = widget.recipe.pourSteps;
    String brewTime = widget.recipe.brewTime;
    String grindSize = widget.recipe.grindSize;
    return Scaffold(
      appBar: AppBar(title: Text(name), centerTitle: true),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white10,
                border: Border.all(color: Colors.black45),
                borderRadius: BorderRadius.circular(4.0),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 4,
                    offset: Offset(0, 2),
                    color: Colors.black12,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // left‑align
                children: [
                  Text(
                    'WATER',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4), // space between title & body
                  Text('$water', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white10,
                border: Border.all(color: Colors.black45),
                borderRadius: BorderRadius.circular(4.0),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 4,
                    offset: Offset(0, 2),
                    color: Colors.black12,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // left‑align
                children: [
                  Text(
                    'DOSE',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4), // space between title & body
                  Text(dose, style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white10,
                border: Border.all(color: Colors.black45),
                borderRadius: BorderRadius.circular(4.0),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 4,
                    offset: Offset(0, 2),
                    color: Colors.black12,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // left‑align
                children: [
                  Text(
                    'GRIND SIZE',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4), // space between title & body
                  Text(grindSize, style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white10,
                border: Border.all(color: Colors.black45),
                borderRadius: BorderRadius.circular(4.0),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 4,
                    offset: Offset(0, 2),
                    color: Colors.black12,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // left‑align
                children: [
                  Text(
                    'BREW TIME',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4), // space between title & body
                  Text(brewTime, style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            SizedBox(height: 40,),
            SizedBox(
              width: double.infinity,
              height: 300.0,
              child: RawMaterialButton(
                onPressed: _onStartPress,
                elevation: 2.0,
                fillColor: Colors.white,
                constraints: BoxConstraints(minWidth: 300.0, minHeight: 300.0),
                padding: EdgeInsets.all(15.0),
                shape: CircleBorder(),
                child: Text("START", style: TextStyle(fontSize: 70),),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
