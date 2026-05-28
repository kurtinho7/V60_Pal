import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:v60pal/BrewTimerPage.dart';
import 'package:v60pal/Theme.dart';
import 'package:v60pal/models/Recipe.dart';
import 'package:v60pal/widgets/app_ui.dart';

class CustomizeRecipeScreen extends StatefulWidget {
  final Recipe recipe;

  const CustomizeRecipeScreen({super.key, required this.recipe});

  @override
  State<CustomizeRecipeScreen> createState() => _CustomizeRecipeScreenState();
}

class _CustomizeRecipeScreenState extends State<CustomizeRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _doseController;
  late final TextEditingController _waterController;
  late final TextEditingController _tempController;
  late final TextEditingController _grindController;
  final List<TextEditingController> _pourTimeControllers = [];
  final List<TextEditingController> _pourAmountControllers = [];

  @override
  void initState() {
    super.initState();
    final recipe = widget.recipe;
    _nameController = TextEditingController(text: '${recipe.name} Custom');
    _doseController = TextEditingController(
      text: _doseNumber(recipe.coffeeDose),
    );
    _waterController = TextEditingController(
      text: recipe.waterWeightGrams.toStringAsFixed(0),
    );
    _tempController = TextEditingController(text: recipe.waterTemp.toString());
    _grindController = TextEditingController(text: recipe.grindSize);

    for (var i = 0; i < recipe.pourSteps.length; i++) {
      _pourTimeControllers.add(
        TextEditingController(text: recipe.pourSteps[i].toString()),
      );
      _pourAmountControllers.add(
        TextEditingController(text: recipe.pourAmounts[i].toString()),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _waterController.dispose();
    _tempController.dispose();
    _grindController.dispose();
    for (final controller in _pourTimeControllers) {
      controller.dispose();
    }
    for (final controller in _pourAmountControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _doseNumber(String dose) {
    final match = RegExp(r'[\d.]+').firstMatch(dose);
    return match?.group(0) ?? dose;
  }

  String _formatDose(double value) {
    if (value == value.roundToDouble()) {
      return '${value.toStringAsFixed(0)}g';
    }
    return '${value.toStringAsFixed(1)}g';
  }

  String _formatTime(int totalSec) {
    final minutes = (totalSec ~/ 60).toString();
    final seconds = (totalSec % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _addPour() {
    final lastTime = _pourTimeControllers.isEmpty
        ? 45
        : int.tryParse(_pourTimeControllers.last.text) ?? 0;
    final lastAmount = _pourAmountControllers.isEmpty
        ? 60
        : int.tryParse(_pourAmountControllers.last.text) ?? 0;
    setState(() {
      _pourTimeControllers.add(
        TextEditingController(text: (lastTime + 45).toString()),
      );
      _pourAmountControllers.add(
        TextEditingController(text: (lastAmount + 50).toString()),
      );
    });
  }

  void _removePour(int index) {
    if (_pourTimeControllers.length <= 1) return;
    late final TextEditingController time;
    late final TextEditingController amount;
    setState(() {
      time = _pourTimeControllers.removeAt(index);
      amount = _pourAmountControllers.removeAt(index);
    });
    time.dispose();
    amount.dispose();
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  String? _positiveNumber(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) return 'Enter a positive number';
    return null;
  }

  String? _positiveInt(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) return 'Enter a positive number';
    return null;
  }

  String? _pourTimeValidator(String? value, int index) {
    final base = _positiveInt(value);
    if (base != null) return base;
    final current = int.parse(value!.trim());
    if (index > 0) {
      final previous = int.tryParse(_pourTimeControllers[index - 1].text);
      if (previous != null && current <= previous) {
        return 'Must be after previous pour';
      }
    }
    return null;
  }

  void _startBrew() {
    if (!_formKey.currentState!.validate()) return;

    final pourSteps = _pourTimeControllers
        .map((controller) => int.parse(controller.text.trim()))
        .toList();
    final pourAmounts = _pourAmountControllers
        .map((controller) => int.parse(controller.text.trim()))
        .toList();
    final dose = double.parse(_doseController.text.trim());

    final customizedRecipe = widget.recipe.copyWith(
      id: '${widget.recipe.id}-custom-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      coffeeDose: _formatDose(dose),
      waterWeightGrams: double.parse(_waterController.text.trim()),
      waterTemp: int.parse(_tempController.text.trim()),
      grindSize: _grindController.text.trim(),
      brewTime: _formatTime(pourSteps.last),
      pourSteps: pourSteps,
      pourAmounts: pourAmounts,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BrewTimerPage(recipe: customizedRecipe),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BACKGROUND_COLOR,
      appBar: AppBar(title: const Text('Customize Recipe')),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppSectionCard(
                color: BUTTON_COLOR.withValues(alpha: 0.65),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.recipe.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tune the preset for this brew.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: MUTED_TEXT_COLOR),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppSectionCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: appInputDecoration('Recipe name'),
                      textInputAction: TextInputAction.next,
                      validator: _requiredText,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _doseController,
                            decoration: appInputDecoration(
                              'Dose',
                              label: 'Dose g',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ],
                            validator: _positiveNumber,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _waterController,
                            decoration: appInputDecoration(
                              'Water',
                              label: 'Water g',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ],
                            validator: _positiveNumber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _tempController,
                            decoration: appInputDecoration(
                              'Temp',
                              label: 'Temp C',
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: _positiveInt,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _grindController,
                            decoration: appInputDecoration(
                              'Grind',
                              label: 'Grind',
                            ),
                            textInputAction: TextInputAction.next,
                            validator: _requiredText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Pour Schedule',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Add pour',
                          onPressed: _addPour,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_pourTimeControllers.length, (index) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == _pourTimeControllers.length - 1
                              ? 0
                              : 12,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 32,
                              height: 48,
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _pourTimeControllers[index],
                                decoration: appInputDecoration(
                                  'Seconds',
                                  label: 'At sec',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (value) =>
                                    _pourTimeValidator(value, index),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _pourAmountControllers[index],
                                decoration: appInputDecoration(
                                  'Target',
                                  label: 'To g',
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: _positiveInt,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              tooltip: 'Remove pour',
                              onPressed: _pourTimeControllers.length <= 1
                                  ? null
                                  : () => _removePour(index),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _startBrew,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Review and brew'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
