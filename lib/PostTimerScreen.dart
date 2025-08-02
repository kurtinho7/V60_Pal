import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:v60pal/Theme.dart';
import 'package:v60pal/models/JournalEntry.dart';
import 'package:v60pal/models/Recipe.dart';
import 'package:v60pal/models/Beans.dart';
import 'package:v60pal/models/Journal.dart';
import 'package:provider/provider.dart';
import 'package:v60pal/persistence/JournalStorage.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class PostTimerScreen extends StatefulWidget {
  final Recipe recipe;
  const PostTimerScreen({super.key, required this.recipe});
  @override
  State<PostTimerScreen> createState() => _PostTimerScreenState();
}

class _PostTimerScreenState extends State<PostTimerScreen> {
  Recipe get recipe => widget.recipe;

  double currentRating = 0;

  final TextEditingController myNotesController = TextEditingController();
  final TextEditingController myGrindController = TextEditingController();
  final TextEditingController myTempController = TextEditingController();

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
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () async {
              final journalEntry = JournalEntry(
                id: '',
                rating: currentRating.toString(),
                waterTemp: int.parse(myTempController.text),
                timeTaken: recipe.pourSteps.last,
                grindSetting: myGrindController.text,
                notes: myNotesController.text,
                beans: newBeans,
                recipe: recipe,
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
            SizedBox(height: 20),
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
                      Text("Rating", style: TextStyle(color: TEXT_COLOR)),
                      RatingBar(
                        initialRating: currentRating,
                        minRating: 0.5,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemPadding: const EdgeInsets.symmetric(horizontal: 2),
                        ratingWidget: RatingWidget(
                          full: Icon(Icons.star, color: Colors.amber),
                          half: Icon(Icons.star_half, color: Colors.amber),
                          empty: Icon(Icons.star_border, color: Colors.amber),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Dose",
                        style: TextStyle(color: TEXT_COLOR, fontSize: 15),
                      ),
                      Text(recipe.coffeeDose),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Water",
                        style: TextStyle(color: TEXT_COLOR, fontSize: 15),
                      ),
                      Text(
                        recipe.waterWeightGrams.toString(),
                        style: TextStyle(color: TEXT_COLOR, fontSize: 15),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Time Taken",
                        style: TextStyle(color: TEXT_COLOR, fontSize: 15),
                      ),
                      Text(
                        recipe.brewTime,
                        style: TextStyle(color: TEXT_COLOR, fontSize: 15),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Grind Setting",
                        style: TextStyle(color: TEXT_COLOR, fontSize: 15),
                      ),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Grind Setting',
                            hintStyle: TextStyle(color: Colors.white38),
                            hintTextDirection: TextDirection.rtl,
                          ),
                          controller: myGrindController,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(color: TEXT_COLOR),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Water Temp",
                        style: TextStyle(color: TEXT_COLOR, fontSize: 15),
                      ),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Temp',
                            hintStyle: TextStyle(color: Colors.white38),
                            hintTextDirection: TextDirection.rtl,
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
          ],
        ),
      ),
    );
  }
}
