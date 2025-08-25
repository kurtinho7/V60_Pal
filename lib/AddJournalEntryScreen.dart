import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:v60pal/ApiClient.dart';
import 'package:v60pal/Theme.dart';
import 'package:v60pal/models/JournalEntry.dart';
import 'package:v60pal/models/Recipe.dart';
import 'package:v60pal/models/Beans.dart';
import 'package:v60pal/models/Journal.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:v60pal/models/BeansList.dart';
import 'package:v60pal/services/JournalEntryService.dart';
import 'package:v60pal/services/BeansService.dart';

class AddJournalEntryScreen extends StatefulWidget {
  const AddJournalEntryScreen({super.key});
  @override
  State<AddJournalEntryScreen> createState() => AddJournalEntryScreenState();
}

class AddJournalEntryScreenState extends State<AddJournalEntryScreen> {
  double currentRating = 0;

  Beans? selectedBeans;

  Recipe? selectedRecipe;

  String? beansId;

  late final ApiClient api;
  late final JournalService journalSvc;
  late final BeansService beansSvc;

  final TextEditingController myNotesController = TextEditingController();
  final TextEditingController myGrindController = TextEditingController();
  final TextEditingController myTempController = TextEditingController();
  final TextEditingController myWaterController = TextEditingController();
  final TextEditingController myDoseController = TextEditingController();
  final TextEditingController myTimeController = TextEditingController();

  int? _parseTimeToSeconds(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    if (RegExp(r'^\d+$').hasMatch(t)) {
      // plain seconds
      return int.tryParse(t);
    }
    final parts = t.split(':');
    if (parts.length == 2) {
      final m = int.tryParse(parts[0]);
      final sec = int.tryParse(parts[1]);
      if (m != null && sec != null && sec >= 0 && sec < 60) {
        return m * 60 + sec;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    currentRating = 0;
    api = ApiClient('http://10.0.2.2:3000');
    journalSvc = JournalService(api);
    beansSvc = BeansService(api);
  }

  @override
  Widget build(BuildContext context) {
    final beansList = context.watch<BeansList>();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        actions: [
          IconButton(
            onPressed: () async {
              if (selectedRecipe == null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Must Select a Recipe')));
                return;
              }

              final newGrindSetting = (myGrindController.text.isEmpty)
                  ? ""
                  : myGrindController.text;
              final newNotes = (myNotesController.text.isEmpty)
                  ? ""
                  : myNotesController.text;
              final newTemp = (myTempController.text.isEmpty)
                  ? 0
                  : int.parse(myTempController.text);
              final ttxt = myTimeController.text.trim();
              final newTime = ttxt.isEmpty
                  ? 0
                  : (_parseTimeToSeconds(ttxt) ?? 0);

              final nullBeans = Beans(
                id: '',
                name: '',
                origin: '',
                roastLevel: '',
                roastDate: DateTime(0, 0, 0, 0, 0, 0),
                weight: 0,
                notes: '',
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

              // ignore: prefer_conditional_assignment
              if (selectedBeans == null) {
                selectedBeans = nullBeans;
                beansId = null;
              } else {
                beansId = selectedBeans!.id;
              }

              final journalEntry = JournalEntry(
                id: '',
                rating: currentRating,
                waterTemp: newTemp,
                timeTaken: newTime,
                grindSetting: newGrindSetting,
                notes: newNotes,
                beans: selectedBeans!,
                recipe: selectedRecipe!,
                date: DateTime.now(),
                recipeId: selectedRecipe!.name,
              );

              try {
                final res = await journalSvc.create(
                  rating: currentRating,
                  waterTemp: newTemp,
                  timeTaken: newTime,
                  grindSetting: newGrindSetting,
                  notes: newNotes,
                  beansId: beansId,
                  date: DateTime.now(),
                  recipeId: selectedRecipe!.name,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Created entry: ${res['_id']}')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    duration: Duration(minutes: 1),
                  ),
                );
              }

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
                    style: TextStyle(color: TEXT_COLOR),
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
                  DropdownButtonFormField(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Select a recipe',
                    ),
                    value: selectedRecipe,
                    items: RECIPES.map((recipe) {
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
                         debugPrint('picked: ${recipe?.id} ${recipe?.name}');
                          selectedRecipe = recipe;
                          debugPrint('matches item? ${RECIPES.any((x) => identical(x, recipe) || x == recipe)}');
                      });
                    },
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
                            hintText: 'Temp (\u00B0C)',
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
