import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:v60pal/ApiClient.dart';
import 'package:v60pal/Theme.dart';
import 'package:v60pal/models/Beans.dart';
import 'package:v60pal/models/BeansList.dart';
import 'package:v60pal/models/Journal.dart';
import 'package:v60pal/models/JournalEntry.dart';
import 'package:v60pal/models/Recipe.dart';
import 'package:v60pal/services/BeansService.dart';
import 'package:v60pal/services/JournalEntryService.dart';
import 'package:v60pal/widgets/app_ui.dart';

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

  @override
  void initState() {
    super.initState();
    api = ApiClient(apiBaseUrl);
    journalSvc = JournalService(api);
    beansSvc = BeansService(api);
  }

  @override
  void dispose() {
    myNotesController.dispose();
    myGrindController.dispose();
    myTempController.dispose();
    myWaterController.dispose();
    myDoseController.dispose();
    myTimeController.dispose();
    super.dispose();
  }

  int? _parseTimeToSeconds(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    if (RegExp(r'^\d+$').hasMatch(t)) return int.tryParse(t);
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

  double? _parseGrams(String s) {
    final match = RegExp(r'\d+(\.\d+)?').firstMatch(s.trim());
    if (match == null) return null;
    return double.tryParse(match.group(0)!);
  }

  Future<void> _save() async {
    if (selectedRecipe == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Must Select a Recipe')));
      return;
    }

    final newGrindSetting = myGrindController.text.trim();
    final newNotes = myNotesController.text.trim();
    final newTemp = myTempController.text.isEmpty
        ? 0
        : int.parse(myTempController.text);
    final newDose = myDoseController.text.trim().isEmpty
        ? selectedRecipe?.coffeeDose
        : myDoseController.text.trim();
    final newWater = myWaterController.text.trim().isEmpty
        ? selectedRecipe?.waterWeightGrams
        : _parseGrams(myWaterController.text);
    final newTime = myTimeController.text.trim().isEmpty
        ? 0
        : (_parseTimeToSeconds(myTimeController.text.trim()) ?? 0);

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

    var journalEntry = JournalEntry(
      id: '',
      rating: currentRating,
      waterTemp: newTemp,
      timeTaken: newTime,
      coffeeDose: newDose,
      waterWeightGrams: newWater,
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
        coffeeDose: newDose,
        waterWeightGrams: newWater,
        grindSetting: newGrindSetting,
        notes: newNotes,
        beansId: beansId,
        date: DateTime.now(),
        recipeId: selectedRecipe!.name,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Created entry: ${res['_id']}')));
      journalEntry = JournalEntry.fromApi(res);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), duration: Duration(minutes: 1)),
      );
    }

    try {
      final journal = context.read<Journal>();
      await journal.addEntry(journalEntry);
      if (!context.mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save entry locally: $e'),
          duration: const Duration(minutes: 1),
        ),
      );
    }
  }

  Widget _formRow({
    required String label,
    required TextEditingController controller,
    required String hint,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: appInputDecoration(hint),
          inputFormatters: inputFormatters,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final beansList = context.watch<BeansList>();
    return Scaffold(
      backgroundColor: BACKGROUND_COLOR,
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.done),
            tooltip: 'Done',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppPageTitle(
              title: 'New Journal Entry',
              subtitle: 'Record what changed and how the cup tasted.',
            ),
            const SizedBox(height: 16),
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Taste', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 14),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Text(
                        'Rating',
                        style: Theme.of(context).textTheme.labelLarge,
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
                          setState(() => currentRating = rating);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    decoration: appInputDecoration('Notes'),
                    controller: myNotesController,
                    minLines: 2,
                    maxLines: 5,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recipe',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<Recipe>(
                    isExpanded: true,
                    decoration: appInputDecoration('Select a recipe'),
                    value: selectedRecipe,
                    items: RECIPES.map((recipe) {
                      return DropdownMenuItem<Recipe>(
                        value: recipe,
                        child: Text(recipe.name),
                      );
                    }).toList(),
                    onChanged: (Recipe? recipe) {
                      setState(() => selectedRecipe = recipe);
                    },
                  ),
                  const SizedBox(height: 14),
                  _formRow(
                    label: 'Dose',
                    controller: myDoseController,
                    hint: 'Dose (g)',
                  ),
                  const SizedBox(height: 14),
                  _formRow(
                    label: 'Water',
                    controller: myWaterController,
                    hint: 'Water (g)',
                  ),
                  const SizedBox(height: 14),
                  _formRow(
                    label: 'Time Taken',
                    controller: myTimeController,
                    hint: 'Time, e.g. 2:45',
                  ),
                  const SizedBox(height: 14),
                  _formRow(
                    label: 'Grind Setting',
                    controller: myGrindController,
                    hint: 'Medium fine',
                  ),
                  const SizedBox(height: 14),
                  _formRow(
                    label: 'Water Temp',
                    controller: myTempController,
                    hint: 'Temp (C)',
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Beans', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<Beans>(
                    isExpanded: true,
                    decoration: appInputDecoration('Select a bean'),
                    value: selectedBeans,
                    items: beansList.entries.map((bean) {
                      return DropdownMenuItem<Beans>(
                        value: bean,
                        child: Text(bean.name),
                      );
                    }).toList(),
                    onChanged: (Beans? beans) {
                      setState(() => selectedBeans = beans);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
