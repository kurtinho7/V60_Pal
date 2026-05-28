import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:v60pal/ApiClient.dart';
import 'package:v60pal/Theme.dart';
import 'package:v60pal/models/Beans.dart';
import 'package:v60pal/models/BeansList.dart';
import 'package:v60pal/models/BrewGuardrails.dart';
import 'package:v60pal/models/Journal.dart';
import 'package:v60pal/models/JournalEntry.dart';
import 'package:v60pal/models/Recipe.dart';
import 'package:v60pal/services/BeansService.dart';
import 'package:v60pal/services/JournalEntryService.dart';
import 'package:v60pal/widgets/app_ui.dart';

class AddJournalEntryScreen extends StatefulWidget {
  final JournalEntry? sourceEntry;
  final Map<String, dynamic>? plannedAdjustment;

  const AddJournalEntryScreen({
    super.key,
    this.sourceEntry,
    this.plannedAdjustment,
  });

  @override
  State<AddJournalEntryScreen> createState() => AddJournalEntryScreenState();
}

class AddJournalEntryScreenState extends State<AddJournalEntryScreen> {
  double currentRating = 0;
  Beans? selectedBeans;
  Recipe? selectedRecipe;
  String? beansId;
  String? selectedPourPattern;
  String? selectedFilterType;
  String? selectedBrewerSize;
  String? selectedBrewerMaterial;
  String? selectedWaterSource;
  bool agitationSwirled = false;
  bool agitationStirred = false;
  final Map<String, Set<String>> selectedTastingFeedback = {
    'flavor': <String>{},
    'body': <String>{},
    'finish': <String>{},
    'intensity': <String>{},
    'defects': <String>{},
  };

  static const Map<String, List<String>> tastingFeedbackOptions = {
    'flavor': ['sour', 'sweet', 'bitter'],
    'body': ['thin', 'heavy'],
    'finish': ['dry', 'clean'],
    'intensity': ['weak', 'intense'],
    'defects': ['astringent', 'muddy', 'hollow'],
  };

  static const List<String> pourPatternOptions = [
    'center',
    'spiral',
    'pulse',
    'single pour',
    'mixed',
  ];

  static const List<String> filterTypeOptions = [
    'paper',
    'bleached paper',
    'natural paper',
    'cloth',
    'metal',
  ];

  static const List<String> brewerSizeOptions = ['01', '02', '03'];

  static const List<String> brewerMaterialOptions = [
    'ceramic',
    'plastic',
    'glass',
    'metal',
  ];

  static const List<String> waterSourceOptions = [
    'tap',
    'filtered',
    'bottled',
    'distilled + minerals',
    'custom',
  ];

  late final ApiClient api;
  late final JournalService journalSvc;
  late final BeansService beansSvc;

  final TextEditingController myNotesController = TextEditingController();
  final TextEditingController myGrindController = TextEditingController();
  final TextEditingController myTempController = TextEditingController();
  final TextEditingController myWaterController = TextEditingController();
  final TextEditingController myDoseController = TextEditingController();
  final TextEditingController myTimeController = TextEditingController();
  final TextEditingController myBloomTimeController = TextEditingController();
  final TextEditingController myBloomWaterController = TextEditingController();
  final TextEditingController myPourCountController = TextEditingController();
  final TextEditingController myAgitationNotesController =
      TextEditingController();
  final TextEditingController myGrinderModelController =
      TextEditingController();
  final TextEditingController myGrinderBurrsController =
      TextEditingController();
  final TextEditingController myGrinderScaleController =
      TextEditingController();
  final TextEditingController myWaterProfileController =
      TextEditingController();
  final TextEditingController myDrawdownController = TextEditingController();

  @override
  void initState() {
    super.initState();
    api = ApiClient(apiBaseUrl);
    journalSvc = JournalService(api);
    beansSvc = BeansService(api);
    _prefillFromSource();
  }

  @override
  void dispose() {
    myNotesController.dispose();
    myGrindController.dispose();
    myTempController.dispose();
    myWaterController.dispose();
    myDoseController.dispose();
    myTimeController.dispose();
    myBloomTimeController.dispose();
    myBloomWaterController.dispose();
    myPourCountController.dispose();
    myAgitationNotesController.dispose();
    myGrinderModelController.dispose();
    myGrinderBurrsController.dispose();
    myGrinderScaleController.dispose();
    myWaterProfileController.dispose();
    myDrawdownController.dispose();
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

  Map<String, dynamic>? _tastingFeedbackBody() {
    final body = <String, dynamic>{};
    for (final entry in selectedTastingFeedback.entries) {
      if (entry.value.isNotEmpty) {
        body[entry.key] = entry.value.toList()..sort();
      }
    }
    return body.isEmpty ? null : body;
  }

  String _formatGrams(double? grams) {
    if (grams == null || grams == 0) return '';
    return grams.toStringAsFixed(grams.truncateToDouble() == grams ? 0 : 1);
  }

  String _formatTime(int? seconds) {
    if (seconds == null || seconds == 0) return '';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _validateTempText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return BrewGuardrails.isPlausibleWaterTemp(int.tryParse(trimmed))
        ? null
        : 'Use ${BrewGuardrails.minPlausibleWaterTempC}-${BrewGuardrails.maxPlausibleWaterTempC} C, or leave blank.';
  }

  Recipe? _recipeFor(JournalEntry entry) {
    final recipeName = entry.recipeId ?? entry.recipe?.name;
    if (recipeName == null || recipeName.isEmpty) return null;
    for (final recipe in RECIPES) {
      if (recipe.name == recipeName || recipe.id == recipeName) return recipe;
    }
    return entry.recipe;
  }

  void _prefillFromSource() {
    final source = widget.sourceEntry;
    if (source == null) return;

    selectedRecipe = _recipeFor(source);
    selectedBeans = source.beans;
    beansId = source.beansId ?? source.beans?.id;
    myGrindController.text = source.grindSetting ?? '';
    myTempController.text = source.waterTemp == null || source.waterTemp == 0
        ? ''
        : source.waterTemp.toString();
    myDoseController.text = source.coffeeDose ?? '';
    myWaterController.text = _formatGrams(source.waterWeightGrams);
    myTimeController.text = _formatTime(source.timeTaken);
    myBloomTimeController.text = _formatTime(source.bloomTimeSeconds);
    myBloomWaterController.text = _formatGrams(source.bloomWaterGrams);
    myPourCountController.text = source.pourCount?.toString() ?? '';
    selectedPourPattern = source.pourPattern;
    agitationSwirled = source.agitationSwirled ?? false;
    agitationStirred = source.agitationStirred ?? false;
    myAgitationNotesController.text = source.agitationNotes ?? '';
    selectedFilterType = source.filterType;
    selectedBrewerSize = source.brewerSize;
    selectedBrewerMaterial = source.brewerMaterial;
    myGrinderModelController.text = source.grinderModel ?? '';
    myGrinderBurrsController.text = source.grinderBurrs ?? '';
    myGrinderScaleController.text = source.grinderGrindScale ?? '';
    selectedWaterSource = source.waterSource;
    myWaterProfileController.text = source.waterProfile ?? '';
    myDrawdownController.text = _formatTime(source.drawdownTimeSeconds);

    final adjustment = widget.plannedAdjustment;
    if (adjustment == null) return;
    final target = '${adjustment['targetValue'] ?? ''}'.trim();
    final variable = '${adjustment['variable'] ?? ''}'.toLowerCase();
    if (target.isEmpty) return;

    if (variable.contains('grind')) {
      myGrindController.text = target;
    } else if (variable.contains('temp')) {
      final temp = RegExp(r'\d+').firstMatch(target)?.group(0);
      myTempController.text = temp ?? target;
    } else if (variable.contains('time')) {
      myTimeController.text = target;
    } else if (variable.contains('dose')) {
      myDoseController.text = target;
    } else if (variable.contains('water') || variable.contains('ratio')) {
      myWaterController.text = target;
    }

    myNotesController.text = [
      'Testing one change: ${adjustment['variable'] ?? 'Adjustment'} ${adjustment['currentValue'] ?? ''} -> $target.',
      if ('${adjustment['reason'] ?? ''}'.trim().isNotEmpty)
        '${adjustment['reason']}',
    ].join('\n');
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
    final newTemp = BrewGuardrails.parseWaterTemp(myTempController.text);
    final newDose = myDoseController.text.trim().isEmpty
        ? selectedRecipe?.coffeeDose
        : myDoseController.text.trim();
    final newWater = myWaterController.text.trim().isEmpty
        ? selectedRecipe?.waterWeightGrams
        : _parseGrams(myWaterController.text);
    final newTime = BrewGuardrails.positiveSeconds(
      _parseTimeToSeconds(myTimeController.text.trim()),
    );
    final newTastingFeedback = _tastingFeedbackBody();
    final newBloomTime = myBloomTimeController.text.trim().isEmpty
        ? null
        : _parseTimeToSeconds(myBloomTimeController.text.trim());
    final newBloomWater = myBloomWaterController.text.trim().isEmpty
        ? null
        : _parseGrams(myBloomWaterController.text);
    final newPourCount = myPourCountController.text.trim().isEmpty
        ? null
        : int.tryParse(myPourCountController.text.trim());
    final newAgitationNotes = _blankToNull(myAgitationNotesController.text);
    final newGrinderModel = _blankToNull(myGrinderModelController.text);
    final newGrinderBurrs = _blankToNull(myGrinderBurrsController.text);
    final newGrinderScale = _blankToNull(myGrinderScaleController.text);
    final newWaterProfile = _blankToNull(myWaterProfileController.text);
    final newDrawdownTime = myDrawdownController.text.trim().isEmpty
        ? null
        : _parseTimeToSeconds(myDrawdownController.text.trim());

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
      bloomTimeSeconds: newBloomTime,
      bloomWaterGrams: newBloomWater,
      pourCount: newPourCount,
      pourPattern: selectedPourPattern,
      agitationSwirled: agitationSwirled,
      agitationStirred: agitationStirred,
      agitationNotes: newAgitationNotes,
      filterType: selectedFilterType,
      brewerSize: selectedBrewerSize,
      brewerMaterial: selectedBrewerMaterial,
      grinderModel: newGrinderModel,
      grinderBurrs: newGrinderBurrs,
      grinderGrindScale: newGrinderScale,
      waterSource: selectedWaterSource,
      waterProfile: newWaterProfile,
      drawdownTimeSeconds: newDrawdownTime,
      notes: newNotes,
      tastingFeedback: newTastingFeedback,
      guidedAdjustment: widget.plannedAdjustment,
      plannedAdjustment: widget.plannedAdjustment,
      comparisonSourceEntryId: widget.sourceEntry?.id,
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
        bloomTimeSeconds: newBloomTime,
        bloomWaterGrams: newBloomWater,
        pourCount: newPourCount,
        pourPattern: selectedPourPattern,
        agitationSwirled: agitationSwirled,
        agitationStirred: agitationStirred,
        agitationNotes: newAgitationNotes,
        filterType: selectedFilterType,
        brewerSize: selectedBrewerSize,
        brewerMaterial: selectedBrewerMaterial,
        grinderModel: newGrinderModel,
        grinderBurrs: newGrinderBurrs,
        grinderGrindScale: newGrinderScale,
        waterSource: selectedWaterSource,
        waterProfile: newWaterProfile,
        drawdownTimeSeconds: newDrawdownTime,
        notes: newNotes,
        tastingFeedback: newTastingFeedback,
        guidedAdjustment: widget.plannedAdjustment,
        plannedAdjustment: widget.plannedAdjustment,
        comparisonSourceEntryId: widget.sourceEntry?.id,
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
    String? Function(String)? validator,
  }) {
    final error = validator?.call(controller.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: appInputDecoration(hint),
          inputFormatters: inputFormatters,
          onChanged: validator == null ? null : (_) => setState(() {}),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: WARNING_COLOR),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  error,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: WARNING_COLOR,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _dropdownRow({
    required String label,
    required String hint,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          decoration: appInputDecoration(hint),
          initialValue: value != null && options.contains(value) ? value : null,
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _tastingFeedbackGroup(String group, List<String> options) {
    final selected = selectedTastingFeedback[group] ?? <String>{};
    final label = group[0].toUpperCase() + group.substring(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (value) {
                setState(() {
                  final values = selectedTastingFeedback[group] ?? <String>{};
                  if (value) {
                    values.add(option);
                  } else {
                    values.remove(option);
                  }
                  selectedTastingFeedback[group] = values;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final beansList = context.watch<BeansList>();
    final selectedBeanValue = selectedBeans == null
        ? null
        : beansList.entries
              .where((bean) => bean.id == selectedBeans!.id)
              .cast<Beans?>()
              .firstWhere((bean) => bean != null, orElse: () => null);
    final recipeWarnings = selectedRecipe == null
        ? const <String>[]
        : BrewGuardrails.recipeWarnings(selectedRecipe!);
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
                  ...tastingFeedbackOptions.entries.expand(
                    (entry) => [
                      _tastingFeedbackGroup(entry.key, entry.value),
                      const SizedBox(height: 14),
                    ],
                  ),
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
                    initialValue: selectedRecipe,
                    items: RECIPES.map((recipe) {
                      return DropdownMenuItem<Recipe>(
                        value: recipe,
                        child: Text(recipe.name),
                      );
                    }).toList(),
                    onChanged: (Recipe? recipe) {
                      setState(() {
                        selectedRecipe = recipe;
                        if (recipe != null &&
                            BrewGuardrails.isPlausibleWaterTemp(
                              recipe.waterTemp,
                            ) &&
                            myTempController.text.trim().isEmpty) {
                          myTempController.text = recipe.waterTemp.toString();
                        }
                      });
                    },
                  ),
                  if (recipeWarnings.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ...recipeWarnings.map(
                      (warning) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: WARNING_COLOR,
                            ),
                            const SizedBox(width: 6),
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
                    validator: _validateTempText,
                  ),
                  const SizedBox(height: 14),
                  _formRow(
                    label: 'Bloom Time',
                    controller: myBloomTimeController,
                    hint: 'Time, e.g. 0:45',
                  ),
                  const SizedBox(height: 14),
                  _formRow(
                    label: 'Bloom Water',
                    controller: myBloomWaterController,
                    hint: 'Bloom water (g)',
                  ),
                  const SizedBox(height: 14),
                  _formRow(
                    label: 'Number of Pours',
                    controller: myPourCountController,
                    hint: 'Pours',
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 14),
                  _dropdownRow(
                    label: 'Pour Pattern',
                    hint: 'Select a pattern',
                    value: selectedPourPattern,
                    options: pourPatternOptions,
                    onChanged: (value) {
                      setState(() => selectedPourPattern = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Agitation',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Swirl'),
                    value: agitationSwirled,
                    onChanged: (value) {
                      setState(() => agitationSwirled = value ?? false);
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Stir'),
                    value: agitationStirred,
                    onChanged: (value) {
                      setState(() => agitationStirred = value ?? false);
                    },
                  ),
                  _formRow(
                    label: 'Agitation Notes',
                    controller: myAgitationNotesController,
                    hint: 'e.g. swirl after bloom',
                  ),
                  const SizedBox(height: 14),
                  _formRow(
                    label: 'Drawdown Time',
                    controller: myDrawdownController,
                    hint: 'Drawdown, e.g. 3:10',
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
                    'Equipment & Water',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  _dropdownRow(
                    label: 'Filter Type',
                    hint: 'Select a filter',
                    value: selectedFilterType,
                    options: filterTypeOptions,
                    onChanged: (value) {
                      setState(() => selectedFilterType = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  _dropdownRow(
                    label: 'Brewer Size',
                    hint: 'Select a size',
                    value: selectedBrewerSize,
                    options: brewerSizeOptions,
                    onChanged: (value) {
                      setState(() => selectedBrewerSize = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  _dropdownRow(
                    label: 'Brewer Material',
                    hint: 'Select a material',
                    value: selectedBrewerMaterial,
                    options: brewerMaterialOptions,
                    onChanged: (value) {
                      setState(() => selectedBrewerMaterial = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  _formRow(
                    label: 'Grinder Model',
                    controller: myGrinderModelController,
                    hint: 'e.g. Comandante C40',
                  ),
                  const SizedBox(height: 14),
                  _formRow(
                    label: 'Burrs',
                    controller: myGrinderBurrsController,
                    hint: 'e.g. stock steel, SSP MP',
                  ),
                  const SizedBox(height: 14),
                  _formRow(
                    label: 'Grind Scale',
                    controller: myGrinderScaleController,
                    hint: 'e.g. clicks, 0-10, microns',
                  ),
                  const SizedBox(height: 14),
                  _dropdownRow(
                    label: 'Water Source',
                    hint: 'Select a source',
                    value: selectedWaterSource,
                    options: waterSourceOptions,
                    onChanged: (value) {
                      setState(() => selectedWaterSource = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  _formRow(
                    label: 'Water Profile',
                    controller: myWaterProfileController,
                    hint: 'e.g. TWW light roast, 80 ppm',
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
                    initialValue: selectedBeanValue,
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
