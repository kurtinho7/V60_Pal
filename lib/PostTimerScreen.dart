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

class PostTimerScreen extends StatefulWidget {
  final Recipe recipe;
  const PostTimerScreen({super.key, required this.recipe});
  @override
  State<PostTimerScreen> createState() => _PostTimerScreenState();
}

class _PostTimerScreenState extends State<PostTimerScreen> {
  Recipe get recipe => widget.recipe;

  double currentRating = 0;

  Beans? selectedBeans;


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
    final beansList = context.watch<BeansList>();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () async {
              final newGrindSetting = (myGrindController.text.isEmpty)? "": myGrindController.text;
              final newNotes = (myNotesController.text.isEmpty)? "": myNotesController.text;
              final newTemp = (myTempController.text.isEmpty)? 0: int.parse(myTempController.text);

              final journalEntry = JournalEntry(
                id: '',
                rating: currentRating.toString(),
                waterTemp: newTemp,
                timeTaken: recipe.pourSteps.last,
                grindSetting: newGrindSetting,
                notes: newNotes,
                beans: newBeans,
                recipe: recipe,
                date: DateTime.now(),
              );

              final fakeBeans = Beans(id: "", name: "Johan", origin: "Colombia", roastLevel: "Medium");

              Journal journal = context.read<Journal>();

              await journal.addEntry(journalEntry);

              await beansList.addEntry(fakeBeans);

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
              "Enjoy Your Brew!",
              style: TextStyle(color: TEXT_COLOR, fontSize: 35),
            ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Dose",
                        style: TextStyle(color: TEXT_COLOR, fontSize: 18),
                      ),
                      Text(
                        recipe.coffeeDose,
                        style: TextStyle(color: TEXT_COLOR, fontSize: 18),
                      ),
                    ],
                  ),
                  SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Water",
                        style: TextStyle(color: TEXT_COLOR, fontSize: 18),
                      ),
                      Text(
                        recipe.waterWeightGrams.toString(),
                        style: TextStyle(color: TEXT_COLOR, fontSize: 18),
                      ),
                    ],
                  ),
                  SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Time Taken",
                        style: TextStyle(color: TEXT_COLOR, fontSize: 18),
                      ),
                      Text(
                        recipe.brewTime,
                        style: TextStyle(color: TEXT_COLOR, fontSize: 18),
                      ),
                    ],
                  ),
                  SizedBox(height: 18),

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
                  SizedBox(height: 18),

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
            SizedBox(height: 18),
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
                      hint: (selectedBeans == null)? Text('Select a Bean'): Text(selectedBeans!.name),
                      value: selectedBeans,
                      menuWidth: 400,
                      items: beansList.entries.map((bean) {
                        return DropdownMenuItem<Beans>(
                          value: bean,
                          child: Text(
                            bean.name, style: TextStyle(color: TEXT_COLOR),
                          ), // show whatever field makes sense
                        );
                      }).toList(),
                      onChanged: (Beans? beans) {
                        setState(() {
                          selectedBeans = beans;
                        });
                      }
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
