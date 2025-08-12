import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:v60pal/Theme.dart';
import 'package:v60pal/models/JournalEntry.dart';
import 'package:v60pal/models/Recipe.dart';
import 'package:v60pal/models/Beans.dart';
import 'package:v60pal/models/Journal.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:v60pal/models/BeansList.dart';

class AddJournalEntryScreen extends StatefulWidget {
  const AddJournalEntryScreen({super.key});
  @override
  State<AddJournalEntryScreen> createState() => AddJournalEntryScreenState();
}

class AddJournalEntryScreenState extends State<AddJournalEntryScreen> {
  final List<Recipe> _recipes = [
    Recipe(
      id: '',
      name: "4:6 Method",
      waterWeightGrams: 300,
      waterTemp: 45,
      pourSteps: [45, 90, 135, 180, 225],
      coffeeDose: "20g",
      grindSize: "fine",
      brewTime: "1:50",
      pourAmounts: [60, 120, 180, 240, 300],
    ),
    Recipe(
      id: '',
      name: "James Hoffmann",
      waterWeightGrams: 250,
      waterTemp: 45,
      pourSteps: [45, 70, 90, 110, 180],
      coffeeDose: "15g",
      grindSize: "medium-fine",
      brewTime: "3:00",
      pourAmounts: [50, 100, 150, 200, 250],
    ),
    Recipe(
      id: '',
      name: "Scott Rao",
      waterWeightGrams: 340,
      waterTemp: 45,
      pourSteps: [60, 120, 180],
      coffeeDose: "20g",
      grindSize: "medium-fine",
      brewTime: "1:50",
      pourAmounts: [60, 210, 340],
    ),
    Recipe(
      id: '',
      name: "4:6",
      waterWeightGrams: 225,
      waterTemp: 45,
      pourSteps: [45, 45, 45, 45, 45],
      coffeeDose: "15g",
      grindSize: "fine",
      brewTime: "1:50",
      pourAmounts: [45, 45, 45, 45, 45],
    ),
    Recipe(
      id: '',
      name: "4:6",
      waterWeightGrams: 225,
      waterTemp: 45,
      pourSteps: [45, 45, 45, 45, 45],
      coffeeDose: "15g",
      grindSize: "fine",
      brewTime: "1:50",
      pourAmounts: [45, 45, 45, 45, 45],
    ),
    Recipe(
      id: '',
      name: "Onyx Method",
      waterWeightGrams: 250,
      waterTemp: 30,
      pourSteps: [30, 90, 150],
      coffeeDose: "15g",
      grindSize: "medium-fine",
      brewTime: "2:30",
      pourAmounts: [50, 150, 250],
    ),
    Recipe(
      id: '',
      name: "4:6",
      waterWeightGrams: 225,
      waterTemp: 45,
      pourSteps: [45, 45, 45, 45, 45],
      coffeeDose: "15g",
      grindSize: "fine",
      brewTime: "1:50",
      pourAmounts: [45, 45, 45, 45, 45],
    ),
  ];
  double currentRating = 0;

  Beans? selectedBeans;

  Recipe? selectedRecipe;

  final TextEditingController myNotesController = TextEditingController();
  final TextEditingController myGrindController = TextEditingController();
  final TextEditingController myTempController = TextEditingController();
  final TextEditingController myWaterController = TextEditingController();
  final TextEditingController myDoseController = TextEditingController();
  final TextEditingController myTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    currentRating = 0;
  }

  Beans newBeans = Beans(
    id: "",
    name: "Johan",
    origin: "Columbua",
    roastLevel: "medium",
  );

  @override
  Widget build(BuildContext context) {
    final beansList = context.watch<BeansList>();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            onPressed: () async {
              final newGrindSetting = (myGrindController.text.isEmpty)
                  ? ""
                  : myGrindController.text;
              final newNotes = (myNotesController.text.isEmpty)
                  ? ""
                  : myNotesController.text;
              final newTemp = (myTempController.text.isEmpty)
                  ? 0
                  : int.parse(myTempController.text);
              final newTime = (myTimeController.text.isEmpty)
                  ? 0
                  : int.parse(myTimeController.text);

              final nullBeans = Beans(
                id: "",
                name: "",
                origin: "",
                roastLevel: "",
              );

              final nullRecipe = Recipe(
                id: '',
                name: "",
                waterWeightGrams: 0,
                waterTemp: 0,
                pourSteps: [],
                coffeeDose: "",
                grindSize: "",
                brewTime: "",
                pourAmounts: [],
              );

              selectedBeans ??= nullBeans;

              selectedRecipe ??= nullRecipe;

              final journalEntry = JournalEntry(
                id: '',
                rating: currentRating.toString(),
                waterTemp: newTemp,
                timeTaken: newTime,
                grindSetting: newGrindSetting,
                notes: newNotes,
                beans: selectedBeans!,
                recipe: selectedRecipe!,
                date: DateTime.now(),
              );

              Journal journal = context.read<Journal>();

              await journal.addEntry(journalEntry);

              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: Icon(Icons.done),
            tooltip: 'Done',
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "New Journal Entry",
              style: TextStyle(color: TEXT_COLOR, fontSize: 35),
            ),
            SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white10,
                border: Border.all(color: Colors.white),
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
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Rating",
                        style: TextStyle(color: TEXT_COLOR, fontSize: 18),
                      ),
                      RatingBar(
                        initialRating: currentRating,
                        minRating: 0.5,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemPadding: const EdgeInsets.symmetric(horizontal: 2),
                        ratingWidget: RatingWidget(
                          full: Icon(Icons.star, color: PRIMARY_COLOR),
                          half: Icon(Icons.star_half, color: PRIMARY_COLOR),
                          empty: Icon(Icons.star_border, color: PRIMARY_COLOR),
                        ),
                        onRatingUpdate: (rating) {
                          setState(() {
                            currentRating = rating;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Notes',
                      hintStyle: TextStyle(color: Colors.white38),
                    ),
                    controller: myNotesController,
                  ),
                ],
              ),
            ),
            SizedBox(height: 10), // Spacing between fields
            Text("Recipe", style: TextStyle(color: TEXT_COLOR, fontSize: 20)),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white10,
                border: Border.all(color: Colors.white),
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
                children: [
                  SizedBox(
                    width: 500,
                    child: DropdownButton<Recipe>(
                      hint: (selectedRecipe == null)
                          ? Text('Select a Recipe')
                          : Text(selectedRecipe!.name),
                      value: selectedRecipe,
                      menuWidth: 400,
                      items: _recipes.map((recipe) {
                        return DropdownMenuItem<Recipe>(
                          value: recipe,
                          child: Text(
                            recipe.name,
                            style: TextStyle(color: TEXT_COLOR),
                          ), // show whatever field makes sense
                        );
                      }).toList(),
                      onChanged: (Recipe? recipe) {
                        setState(() {
                          selectedRecipe = recipe;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Dose",
                        style: TextStyle(color: TEXT_COLOR, fontSize: 18),
                      ),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Dose (g)',
                            hintStyle: TextStyle(color: Colors.white38),
                            hintTextDirection: TextDirection.rtl,
                            border: InputBorder.none,
                          ),
                          controller: myDoseController,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(color: TEXT_COLOR),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Water",
                        style: TextStyle(color: TEXT_COLOR, fontSize: 18),
                      ),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Water (g)',
                            hintStyle: TextStyle(color: Colors.white38),
                            hintTextDirection: TextDirection.rtl,
                            border: InputBorder.none,
                          ),
                          controller: myWaterController,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(color: TEXT_COLOR),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Time Taken",
                        style: TextStyle(color: TEXT_COLOR, fontSize: 18),
                      ),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Time',
                            hintStyle: TextStyle(color: Colors.white38),
                            hintTextDirection: TextDirection.rtl,
                            border: InputBorder.none,
                          ),
                          controller: myTimeController,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(color: TEXT_COLOR),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Grind Setting",
                        style: TextStyle(color: TEXT_COLOR, fontSize: 18),
                      ),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Grind Setting',
                            hintStyle: TextStyle(color: Colors.white38),
                            hintTextDirection: TextDirection.rtl,
                            border: InputBorder.none,
                          ),
                          controller: myGrindController,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(color: TEXT_COLOR),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Water Temp",
                        style: TextStyle(color: TEXT_COLOR, fontSize: 18),
                      ),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Temp',
                            hintStyle: TextStyle(color: Colors.white38),
                            hintTextDirection: TextDirection.rtl,
                            border: InputBorder.none,
                          ),
                          controller: myTempController,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(color: TEXT_COLOR),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly, // only 0–9
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text("Beans", style: TextStyle(color: TEXT_COLOR, fontSize: 20)),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white10,
                border: Border.all(color: Colors.white),
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
                children: [
                  SizedBox(
                    width: 500,
                    child: DropdownButton<Beans>(
                      hint: (selectedBeans == null)
                          ? Text('Select a Bean')
                          : Text(selectedBeans!.name),
                      value: selectedBeans,
                      menuWidth: 400,
                      items: beansList.entries.map((bean) {
                        return DropdownMenuItem<Beans>(
                          value: bean,
                          child: Text(
                            bean.name,
                            style: TextStyle(color: TEXT_COLOR),
                          ), // show whatever field makes sense
                        );
                      }).toList(),
                      onChanged: (Beans? beans) {
                        setState(() {
                          selectedBeans = beans;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
