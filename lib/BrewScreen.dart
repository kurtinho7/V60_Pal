import 'package:flutter/material.dart';
import 'package:v60pal/BrewTimerPage.dart';
import 'package:v60pal/Theme.dart';
import 'package:v60pal/models/Recipe.dart';
import 'package:v60pal/widgets/app_ui.dart';

class BrewScreen extends StatefulWidget {
  const BrewScreen({super.key});

  @override
  State<BrewScreen> createState() => _BrewScreenState();
}

class _BrewScreenState extends State<BrewScreen> {
  final List<IconData> _icons = [
    Icons.filter_alt_outlined,
    Icons.auto_awesome_outlined,
    Icons.water_drop_outlined,
    Icons.spa_outlined,
    Icons.local_drink_outlined,
    Icons.coffee_outlined,
    Icons.science_outlined,
    Icons.timelapse_outlined,
    Icons.all_inclusive,
  ];

  int _selectedIndex = 0;

  Recipe get _selectedRecipe => RECIPES[_selectedIndex];

  void _onBrewPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BrewTimerPage(recipe: _selectedRecipe),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BACKGROUND_COLOR,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverToBoxAdapter(
                child: AppSectionCard(
                  color: BUTTON_COLOR.withValues(alpha: 0.65),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(APP_RADIUS),
                        ),
                        child: Icon(
                          Icons.coffee_maker_outlined,
                          color: PRIMARY_COLOR,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose a recipe',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Select a brew profile, then start the guided timer.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: MUTED_TEXT_COLOR),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid.builder(
                itemCount: RECIPES.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisExtent: 150,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (context, i) {
                  final selected = i == _selectedIndex;
                  final recipe = RECIPES[i];
                  return _RecipeTile(
                    recipe: recipe,
                    icon: _icons[i],
                    selected: selected,
                    onTap: () => setState(() => _selectedIndex = i),
                  );
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverToBoxAdapter(
                child: AppSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedRecipe.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          AppMetricChip(
                            icon: Icons.scale_outlined,
                            label: _selectedRecipe.coffeeDose,
                          ),
                          AppMetricChip(
                            icon: Icons.water_drop_outlined,
                            label:
                                '${_selectedRecipe.waterWeightGrams.toStringAsFixed(0)}g',
                            color: SECONDARY_COLOR,
                          ),
                          AppMetricChip(
                            icon: Icons.timer_outlined,
                            label: _selectedRecipe.brewTime,
                            color: WARNING_COLOR,
                          ),
                          AppMetricChip(
                            icon: Icons.grain_outlined,
                            label: _selectedRecipe.grindSize,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _onBrewPressed,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start brew'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeTile extends StatelessWidget {
  final Recipe recipe;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RecipeTile({
    required this.recipe,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      onTap: onTap,
      color: selected ? BUTTON_COLOR : SURFACE_COLOR,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? PRIMARY_COLOR : SURFACE_TINT_COLOR,
                  borderRadius: BorderRadius.circular(APP_RADIUS),
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : PRIMARY_COLOR,
                  size: 22,
                ),
              ),
              const Spacer(),
              if (selected)
                Icon(Icons.check_circle, color: PRIMARY_COLOR, size: 20),
            ],
          ),
          const Spacer(),
          Text(
            recipe.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            '${recipe.coffeeDose} / ${recipe.waterWeightGrams.toStringAsFixed(0)}g water',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: MUTED_TEXT_COLOR,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
