import 'package:flutter/material.dart';
import 'package:v60pal/Theme.dart';
import 'package:v60pal/TimerScreen.dart';
import 'package:v60pal/models/Recipe.dart';
import 'package:v60pal/widgets/app_ui.dart';

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
    final recipe = widget.recipe;
    return Scaffold(
      backgroundColor: BACKGROUND_COLOR,
      appBar: AppBar(title: Text(recipe.name)),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSectionCard(
                color: BUTTON_COLOR.withValues(alpha: 0.65),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Review the recipe, then start the guided pour timer.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: MUTED_TEXT_COLOR),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _RecipeFact(
                    icon: Icons.water_drop_outlined,
                    label: 'Water',
                    value: '${recipe.waterWeightGrams.toStringAsFixed(0)}g',
                  ),
                  _RecipeFact(
                    icon: Icons.scale_outlined,
                    label: 'Dose',
                    value: recipe.coffeeDose,
                  ),
                  _RecipeFact(
                    icon: Icons.grain_outlined,
                    label: 'Grind',
                    value: recipe.grindSize,
                  ),
                  _RecipeFact(
                    icon: Icons.timer_outlined,
                    label: 'Time',
                    value: recipe.brewTime,
                  ),
                  _RecipeFact(
                    icon: Icons.thermostat_outlined,
                    label: 'Temp',
                    value: '${recipe.waterTemp} C',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pour schedule',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(recipe.pourSteps.length, (index) {
                      final time = recipe.pourSteps[index];
                      final amount = recipe.pourAmounts[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == recipe.pourSteps.length - 1 ? 0 : 10,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: BUTTON_COLOR,
                              foregroundColor: PRIMARY_COLOR,
                              child: Text('${index + 1}'),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text('Pour to ${amount}g')),
                            Text(
                              _formatTime(time),
                              style: TextStyle(
                                color: MUTED_TEXT_COLOR,
                                fontWeight: FontWeight.w700,
                              ),
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
                onPressed: _onStartPress,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start timer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int totalSec) {
    final minutes = (totalSec ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSec % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _RecipeFact extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _RecipeFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: AppSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: PRIMARY_COLOR),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: MUTED_TEXT_COLOR),
            ),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
