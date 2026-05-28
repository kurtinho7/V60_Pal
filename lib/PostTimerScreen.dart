import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:v60pal/ApiClient.dart';
import 'package:v60pal/Theme.dart';
import 'package:v60pal/models/BrewGuardrails.dart';
import 'package:v60pal/models/JournalEntry.dart';
import 'package:v60pal/models/Recipe.dart';
import 'package:v60pal/models/Beans.dart';
import 'package:v60pal/models/Journal.dart';
import 'package:provider/provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:v60pal/models/BeansList.dart';
import 'package:v60pal/services/BeansService.dart';
import 'package:v60pal/services/JournalEntryService.dart';
import 'package:v60pal/widgets/app_ui.dart';

class PostTimerScreen extends StatefulWidget {
  final Recipe recipe;
  const PostTimerScreen({super.key, required this.recipe});
  @override
  State<PostTimerScreen> createState() => _PostTimerScreenState();
}

class _PostTimerScreenState extends State<PostTimerScreen> {
  Recipe get recipe => widget.recipe;

  double currentRating = 0;

  String? beansId;

  Beans? selectedBeans;
  late final ApiClient api;
  late final JournalService journalSvc;
  late final BeansService beansSvc;
  bool _saving = false;
  final TextEditingController myNotesController = TextEditingController();
  final TextEditingController myGrindController = TextEditingController();
  final TextEditingController myTempController = TextEditingController();

  @override
  void initState() {
    super.initState();
    currentRating = 0;
    api = ApiClient(apiBaseUrl);
    journalSvc = JournalService(api);
    beansSvc = BeansService(api);
    myTempController.text =
        BrewGuardrails.isPlausibleWaterTemp(recipe.waterTemp)
        ? recipe.waterTemp.toString()
        : '';
    myGrindController.text = recipe.grindSize;
  }

  @override
  Widget build(BuildContext context) {
    final beansList = context.watch<BeansList>();
    return Scaffold(
      backgroundColor: BACKGROUND_COLOR,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.done),
            tooltip: 'Done',
            onPressed: _saving
                ? null
                : () async {
                    setState(() {
                      _saving = true;
                    });

                    final newGrindSetting = (myGrindController.text.isEmpty)
                        ? recipe.grindSize
                        : myGrindController.text;
                    final newNotes = (myNotesController.text.isEmpty)
                        ? ""
                        : myNotesController.text;
                    final newTemp = BrewGuardrails.parseWaterTemp(
                      myTempController.text,
                    );

                    final nullBeans = Beans(
                      id: '',
                      name: '',
                      origin: '',
                      roastLevel: '',
                      roastDate: DateTime(0, 0, 0, 0, 0, 0),
                      weight: 0,
                      notes: '',
                    );

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
                      timeTaken: recipe.pourSteps.last,
                      coffeeDose: recipe.coffeeDose,
                      waterWeightGrams: recipe.waterWeightGrams,
                      grindSetting: newGrindSetting,
                      pourCount: recipe.pourSteps.length,
                      pourPattern: recipe.pourAmounts.join(', '),
                      notes: newNotes,
                      beans: selectedBeans!,
                      recipe: recipe,
                      date: DateTime.now(),
                      recipeId: recipe.name,
                    );

                    try {
                      final journal = context.read<Journal>();
                      await journal.addEntry(journalEntry);
                      if (!context.mounted) return;
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    } catch (e) {
                      if (!context.mounted) return;
                      setState(() {
                        _saving = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Could not save entry locally: $e'),
                          duration: Duration(minutes: 1),
                        ),
                      );
                      return;
                    }

                    unawaited(
                      journalSvc
                          .create(
                            rating: currentRating,
                            waterTemp: newTemp,
                            timeTaken: recipe.pourSteps.last,
                            coffeeDose: recipe.coffeeDose,
                            waterWeightGrams: recipe.waterWeightGrams,
                            grindSetting: newGrindSetting,
                            pourCount: recipe.pourSteps.length,
                            pourPattern: recipe.pourAmounts.join(', '),
                            notes: newNotes,
                            beansId: beansId,
                            date: DateTime.now(),
                            recipeId: recipe.name,
                          )
                          .timeout(const Duration(seconds: 5))
                          .catchError((e) {
                            debugPrint('Background journal sync failed: $e');
                            return <String, dynamic>{};
                          }),
                    );
                  },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppPageTitle(
              title: 'Enjoy Your Brew',
              subtitle: 'Capture a few details while the cup is fresh.',
            ),
            SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: SURFACE_COLOR,
                border: Border.all(color: OUTLINE_COLOR),
                borderRadius: BorderRadius.circular(APP_RADIUS),
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
                        style: Theme.of(context).textTheme.titleSmall,
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
                    decoration: InputDecoration(hintText: 'Notes'),
                    controller: myNotesController,
                  ),
                ],
              ),
            ),
            SizedBox(height: 10), // Spacing between fields
            Text("Recipe", style: Theme.of(context).textTheme.titleMedium),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: SURFACE_COLOR,
                border: Border.all(color: OUTLINE_COLOR),
                borderRadius: BorderRadius.circular(APP_RADIUS),
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
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        recipe.coffeeDose,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                  SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Water",
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        recipe.waterWeightGrams.toString(),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                  SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Time Taken",
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        recipe.brewTime,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                  SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Grind Setting",
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Grind Setting',
                            hintTextDirection: TextDirection.rtl,
                          ),
                          controller: myGrindController,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
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
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Temp',
                            hintTextDirection: TextDirection.rtl,
                          ),
                          controller: myTempController,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly, // only 0–9
                          ],
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  if (myTempController.text.trim().isNotEmpty &&
                      !BrewGuardrails.isPlausibleWaterTemp(
                        int.tryParse(myTempController.text),
                      )) ...[
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: WARNING_COLOR,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Use ${BrewGuardrails.minPlausibleWaterTempC}-${BrewGuardrails.maxPlausibleWaterTempC} C, or leave blank.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: WARNING_COLOR,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  ...BrewGuardrails.recipeWarnings(recipe).map(
                    (warning) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: WARNING_COLOR,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              warning,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: WARNING_COLOR,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 18),
            Text("Beans", style: Theme.of(context).textTheme.titleMedium),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: SURFACE_COLOR,
                border: Border.all(color: OUTLINE_COLOR),
                borderRadius: BorderRadius.circular(APP_RADIUS),
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
