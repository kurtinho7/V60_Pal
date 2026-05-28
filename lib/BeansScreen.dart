import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:v60pal/ApiClient.dart';
import 'package:v60pal/Theme.dart';
import 'package:v60pal/models/BeanMemory.dart';
import 'package:v60pal/models/Beans.dart';
import 'package:v60pal/models/BeansList.dart';
import 'package:intl/intl.dart';
import 'package:v60pal/services/BeansService.dart';
import 'package:v60pal/widgets/app_ui.dart';

enum BeansAction { memory, compare, edit, delete }

class BeansScreen extends StatefulWidget {
  const BeansScreen({super.key});

  @override
  State<BeansScreen> createState() => _BeansScreenState();
}

class _BeansScreenState extends State<BeansScreen> {
  // How many days until beans are considered "0% fresh".
  static const int freshnessWindowDays = 45;

  late ApiClient api;
  late BeansService beansSvc;

  TextEditingController editController = TextEditingController();

  @override
  void initState() {
    super.initState();
    api = ApiClient(apiBaseUrl);
    beansSvc = BeansService(api);
  }

  double _freshnessPercent(DateTime roastDate) {
    final now = DateTime.now();
    // Normalize to date (drop time) to avoid small negative/positive drift
    final today = DateTime(now.year, now.month, now.day);
    final r = DateTime(roastDate.year, roastDate.month, roastDate.day);
    final daysSinceRoast = today.difference(r).inDays;
    final raw = (freshnessWindowDays - daysSinceRoast) / freshnessWindowDays;
    return raw.clamp(0.0, 1.0);
  }

  Color _freshnessColor(double pct) {
    // 0 => red, 1 => green
    return Color.lerp(const Color(0xFFB45D4B), SUCCESS_COLOR, pct) ??
        SUCCESS_COLOR;
  }

  String _ageLabel(DateTime roastDate) {
    final days = DateTime.now()
        .difference(DateTime(roastDate.year, roastDate.month, roastDate.day))
        .inDays;
    if (days <= 0) return 'Roasted today';
    if (days == 1) return 'Roasted 1 day ago';
    return 'Roasted $days days ago';
  }

  Future<void> _deleteAt(String id) async {
    final beansList = context.read<BeansList>();
    final removedIndex = beansList.entries.indexWhere((b) => b.id == id);
    final removed = beansList.entries[removedIndex];

    // Optimistic local removal
    await beansList.removeEntry(removed.id);
    try {
      if (removed.id.isNotEmpty) {
        await beansSvc.delete(removed.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Entry deleted'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              // naive undo to end; adapt if you want same position
              await beansList.addEntry(removed);
            },
          ),
        ),
      );
    } catch (e) {
      // rollback on API failure
      await beansList.addEntry(removed);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  void editBeans(String id) async {
    if (editController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Must Input an Amount')));
      return;
    }

    final newAmount = editController.text;
    final newAmountInt = int.parse(newAmount);

    beansSvc.update(id, weight: newAmountInt);
    final beansList = context.read<BeansList>();
    await beansList.editEntry(id, newAmountInt);
  }

  String _formatRating(double? rating) {
    if (rating == null) return '—';
    return rating.toStringAsFixed(rating % 1 == 0 ? 0 : 1);
  }

  String _formatSeconds(int? seconds) {
    if (seconds == null || seconds <= 0) return '—';
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return '$minutes:${remainder.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat.yMMMd().format(date);
  }

  String _formatGrams(double? grams) {
    if (grams == null || grams <= 0) return '—';
    return '${grams.toStringAsFixed(grams.truncateToDouble() == grams ? 0 : 1)}g';
  }

  String _formatTaste(BeanBrewSummary brew) {
    final labels = <String>[];
    final feedback = brew.tastingFeedback;
    if (feedback != null) {
      for (final value in feedback.values) {
        if (value is List) {
          labels.addAll(value.map((item) => item.toString()));
        } else if (value != null && value.toString().trim().isNotEmpty) {
          labels.add(value.toString());
        }
      }
    }
    if (labels.isNotEmpty) return labels.take(4).join(', ');
    return brew.notes?.trim().isNotEmpty == true ? brew.notes!.trim() : '—';
  }

  String _formatRecipeValue(dynamic value) {
    if (value == null) return '—';
    if (value is Map) {
      return value.values
          .where((item) => item != null && item.toString().trim().isNotEmpty)
          .join(' · ');
    }
    return value.toString();
  }

  Widget _memoryMetric(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: PRIMARY_COLOR),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '$label $value',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: TEXT_COLOR, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _memorySection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: TEXT_COLOR,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _brewSummary(BeanBrewSummary? brew) {
    if (brew == null) {
      return Text(
        'No brew logged yet.',
        style: TextStyle(color: MUTED_TEXT_COLOR, fontSize: 13),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _memoryMetric('Rating', _formatRating(brew.rating), Icons.star),
            _memoryMetric(
              'Temp',
              '${brew.waterTempC ?? '—'} C',
              Icons.thermostat,
            ),
            _memoryMetric(
              'Time',
              _formatSeconds(brew.brewTimeSeconds),
              Icons.timer_outlined,
            ),
            _memoryMetric('Grind', brew.grindSetting ?? '—', Icons.grain),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          [
            if ((brew.recipeName?.isNotEmpty ?? false)) brew.recipeName,
            if ((brew.coffeeDose?.isNotEmpty ?? false)) brew.coffeeDose,
            if (brew.waterWeightGrams != null)
              '${brew.waterWeightGrams!.round()}g water',
            if (brew.pourCount != null) '${brew.pourCount} pours',
            _formatDate(brew.date),
          ].whereType<String>().join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: MUTED_TEXT_COLOR, fontSize: 12),
        ),
        if ((brew.notes?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 8),
          Text(
            brew.notes!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: TEXT_COLOR, fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _recommendedBrew(BeanRecommendedBrew? recommendation) {
    if (recommendation == null) {
      return Text(
        'No recommendation yet.',
        style: TextStyle(color: MUTED_TEXT_COLOR, fontSize: 13),
      );
    }

    final recipe = recommendation.recipe ?? const {};
    final isAiRecipe = recommendation.source == 'ai-feedback';
    final values = isAiRecipe
        ? [
            'Temp ${_formatRecipeValue(recipe['temperature'])}',
            'Grind ${_formatRecipeValue(recipe['grindSize'])}',
            'Time ${_formatRecipeValue(recipe['brewTime'])}',
            'Pours ${_formatRecipeValue(recipe['pours'])}',
            'Dose ${_formatRecipeValue(recipe['coffeeDose'])}',
            'Water ${_formatRecipeValue(recipe['waterAmount'])}',
          ]
        : [
            if (recipe['rating'] != null)
              'Rating ${_formatRecipeValue(recipe['rating'])}',
            if (recipe['waterTempC'] != null)
              'Temp ${_formatRecipeValue(recipe['waterTempC'])} C',
            if (recipe['grindSetting'] != null)
              'Grind ${_formatRecipeValue(recipe['grindSetting'])}',
            if (recipe['brewTimeSeconds'] != null)
              'Time ${_formatSeconds((recipe['brewTimeSeconds'] as num).toInt())}',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .where((value) => !value.endsWith('—'))
              .map(
                (value) => Chip(
                  label: Text(value),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: BUTTON_COLOR,
                  side: BorderSide(color: OUTLINE_COLOR),
                ),
              )
              .toList(),
        ),
        if ((recommendation.reason?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 8),
          Text(
            recommendation.reason!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: MUTED_TEXT_COLOR, fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _triedValues(BeanTriedSummary tried) {
    final labels = [
      ...tried.recipes.map((value) => 'Recipe $value'),
      ...tried.temperaturesC.map((value) => '$value C'),
      ...tried.grindSettings.map((value) => 'Grind $value'),
      ...tried.brewTimesSeconds.map((value) => _formatSeconds(value)),
      ...tried.coffeeDoses,
      ...tried.waterAmountsGrams.map((value) => '${value}g water'),
      ...tried.pourCounts.map((value) => '$value pours'),
    ].where((value) => value.trim().isNotEmpty && value != '—').take(18);

    if (labels.isEmpty) {
      return Text(
        'No recipe variables recorded yet.',
        style: TextStyle(color: MUTED_TEXT_COLOR, fontSize: 13),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: labels
          .map(
            (value) => Chip(
              label: Text(value),
              visualDensity: VisualDensity.compact,
              backgroundColor: SURFACE_TINT_COLOR,
              side: BorderSide(color: OUTLINE_COLOR),
            ),
          )
          .toList(),
    );
  }

  Widget _compareCell(String value, {bool header = false, double width = 118}) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        maxLines: header ? 2 : 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: header ? TEXT_COLOR : MUTED_TEXT_COLOR,
          fontSize: header ? 12 : 13,
          fontWeight: header ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }

  Widget _comparisonRow(String label, List<String> values) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: OUTLINE_COLOR)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _compareCell(label, header: true, width: 92),
          ...values.map(_compareCell),
        ],
      ),
    );
  }

  Widget _lastBrewsComparison(List<BeanBrewSummary> brews) {
    if (brews.isEmpty) {
      return Text(
        'No brews logged yet.',
        style: TextStyle(color: MUTED_TEXT_COLOR, fontSize: 13),
      );
    }

    final columns = brews.take(3).toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 92 + (118 * columns.length).toDouble(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _comparisonRow(
              'Brew',
              columns
                  .map(
                    (brew) =>
                        '${_formatDate(brew.date)}\n${brew.recipeName ?? 'Custom'}',
                  )
                  .toList(),
            ),
            _comparisonRow(
              'Grind',
              columns.map((brew) => brew.grindSetting ?? '—').toList(),
            ),
            _comparisonRow(
              'Temp',
              columns.map((brew) => '${brew.waterTempC ?? '—'} C').toList(),
            ),
            _comparisonRow(
              'Time',
              columns
                  .map((brew) => _formatSeconds(brew.brewTimeSeconds))
                  .toList(),
            ),
            _comparisonRow(
              'Ratio',
              columns.map((brew) => brew.ratio ?? '—').toList(),
            ),
            _comparisonRow(
              'Dose',
              columns.map((brew) => brew.coffeeDose ?? '—').toList(),
            ),
            _comparisonRow(
              'Water',
              columns
                  .map((brew) => _formatGrams(brew.waterWeightGrams))
                  .toList(),
            ),
            _comparisonRow(
              'Rating',
              columns.map((brew) => _formatRating(brew.rating)).toList(),
            ),
            _comparisonRow('Taste', columns.map(_formatTaste).toList()),
          ],
        ),
      ),
    );
  }

  Future<void> _showBeanMemory(Beans bean) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          expand: false,
          builder: (ctx, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surface,
                borderRadius: BorderRadius.circular(APP_RADIUS),
                border: Border.all(color: OUTLINE_COLOR),
              ),
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: FutureBuilder<BeanMemory>(
                future: beansSvc.memory(bean.id),
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Could not load recipe memory.',
                        style: TextStyle(color: MUTED_TEXT_COLOR),
                      ),
                    );
                  }

                  final memory = snapshot.data!;
                  return ListView(
                    controller: scrollController,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              memory.bean.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: TEXT_COLOR,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _memoryMetric(
                            'Brews',
                            '${memory.brewCount}',
                            Icons.coffee,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _memorySection('Recommended next brew', [
                        _recommendedBrew(memory.recommendedNextBrew),
                      ]),
                      const SizedBox(height: 20),
                      _memorySection('Best-rated brew', [
                        _brewSummary(memory.bestRatedBrew),
                      ]),
                      const SizedBox(height: 20),
                      _memorySection('Last brew', [
                        _brewSummary(memory.lastBrew),
                      ]),
                      const SizedBox(height: 20),
                      _memorySection('Already tried', [
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _memoryMetric(
                              'Average',
                              _formatRating(memory.tried.averageRating),
                              Icons.trending_up,
                            ),
                            _memoryMetric(
                              'Best',
                              _formatRating(memory.tried.bestRating),
                              Icons.workspace_premium_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _triedValues(memory.tried),
                      ]),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showBeanComparison(Beans bean) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.68,
          minChildSize: 0.42,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.surface,
                borderRadius: BorderRadius.circular(APP_RADIUS),
                border: Border.all(color: OUTLINE_COLOR),
              ),
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: FutureBuilder<BeanMemory>(
                future: beansSvc.memory(bean.id),
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Could not load brew comparison.',
                        style: TextStyle(color: MUTED_TEXT_COLOR),
                      ),
                    );
                  }

                  final memory = snapshot.data!;
                  return ListView(
                    controller: scrollController,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Compare last 3',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: TEXT_COLOR,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _memoryMetric(
                            'Brews',
                            '${memory.lastBrews.length}',
                            Icons.compare_arrows,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        memory.bean.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: MUTED_TEXT_COLOR, fontSize: 13),
                      ),
                      const SizedBox(height: 18),
                      _lastBrewsComparison(memory.lastBrews),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<BeansAction?> showBeansActions(BuildContext context, Beans bean) {
    return showModalBottomSheet<BeansAction>(
      context: context,
      useSafeArea: true,
      isScrollControlled: false,
      showDragHandle: true, // optional (Flutter 3.13+)
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sheet card
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(APP_RADIUS),
                  border: Border.all(color: OUTLINE_COLOR),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.auto_awesome_outlined),
                      title: const Text('Recipe memory'),
                      onTap: () => Navigator.pop(ctx, BeansAction.memory),
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(Icons.compare_arrows),
                      title: const Text('Compare last 3'),
                      onTap: () => Navigator.pop(ctx, BeansAction.compare),
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: const Text('Edit'),
                      onTap: () => Navigator.pop(ctx, BeansAction.edit),
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      title: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                      onTap: () => Navigator.pop(ctx, BeansAction.delete),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Cancel button
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(APP_RADIUS),
                  border: Border.all(color: OUTLINE_COLOR),
                ),
                child: ListTile(
                  leading: const Icon(Icons.close),
                  title: const Text('Cancel'),
                  onTap: () => Navigator.pop(ctx, null),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final beansList = context.watch<BeansList>();
    final beans = List<Beans>.from(beansList.entries)
      ..sort((a, b) => b.roastDate.compareTo(a.roastDate)); // newest first

    return Scaffold(
      backgroundColor: BACKGROUND_COLOR,
      body: beans.isEmpty
          ? const AppEmptyState(
              icon: Icons.local_cafe_outlined,
              title: 'No beans yet',
              message: 'Tap + to add your first bag.',
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                // Simple responsive columns
                final maxWidth = constraints.maxWidth;
                int crossAxisCount = 2;
                if (maxWidth >= 1200) {
                  crossAxisCount = 5;
                } else if (maxWidth >= 900) {
                  crossAxisCount = 4;
                } else if (maxWidth >= 650) {
                  crossAxisCount = 3;
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisExtent: 210,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: beans.length,
                  itemBuilder: (context, index) {
                    final b = beans[index];
                    final pct = _freshnessPercent(b.roastDate);
                    final color = _freshnessColor(pct);
                    final pctText = '${(pct * 100).round()}%';
                    final roastDateStr = DateFormat.yMMMd().format(b.roastDate);

                    return InkWell(
                      borderRadius: BorderRadius.circular(APP_RADIUS),
                      onTap: () async {
                        final action = await showBeansActions(context, b);
                        if (action == null) return;
                        if (!context.mounted) return;

                        switch (action) {
                          case BeansAction.memory:
                            await _showBeanMemory(b);
                            break;
                          case BeansAction.compare:
                            await _showBeanComparison(b);
                            break;
                          case BeansAction.edit:
                            await showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('Edit Beans Amount'),
                                content: TextField(
                                  controller: editController,
                                  decoration: const InputDecoration(
                                    hintText: 'New Amount (g)',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () {
                                      editBeans(b.id);
                                      Navigator.pop(ctx, false);
                                    },
                                    child: const Text('Confirm'),
                                  ),
                                ],
                              ),
                            );
                            break;
                          case BeansAction.delete:
                            // TODO: Handle this case.
                            final ok =
                                await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete beans?'),
                                    content: Text(
                                      'This will remove "${b.name.isNotEmpty ? b.name : 'these beans'}".',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false;
                            if (ok) {
                              _deleteAt(b.id);
                            }
                            break;
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: SURFACE_COLOR,
                          border: Border.all(color: OUTLINE_COLOR),
                          borderRadius: BorderRadius.circular(APP_RADIUS),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                              color: Colors.black.withValues(alpha: 0.04),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    b.name.isNotEmpty
                                        ? b.name
                                        : 'Unnamed Beans',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: TEXT_COLOR,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: BUTTON_COLOR,
                                    borderRadius: BorderRadius.circular(
                                      APP_RADIUS,
                                    ),
                                    border: Border.all(color: OUTLINE_COLOR),
                                  ),
                                  child: Text(
                                    (b.roastLevel?.isNotEmpty ?? false)
                                        ? b.roastLevel!
                                        : '—',
                                    style: TextStyle(
                                      color: TEXT_COLOR,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Subheader
                            Text(
                              b.origin!.isNotEmpty
                                  ? b.origin!
                                  : 'Origin unknown',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: MUTED_TEXT_COLOR,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Freshness bar + label
                            Tooltip(
                              message:
                                  'Freshness decays linearly over $freshnessWindowDays days from roast date.',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: pct,
                                      minHeight: 10,
                                      backgroundColor: SURFACE_TINT_COLOR,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        color,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Freshness: $pctText',
                                    style: TextStyle(
                                      color: TEXT_COLOR,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    // <-- lets the right label shrink/ellipsis instead of overflowing
                                    child: Text(
                                      _ageLabel(b.roastDate),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        color: MUTED_TEXT_COLOR.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.scale,
                                        size: 16,
                                        color: PRIMARY_COLOR,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        (b.weight! > 0) ? '${b.weight} g' : '—',
                                        style: TextStyle(
                                          color: TEXT_COLOR,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(),

                            // Footer line (roast date + weight)
                            Row(
                              children: [
                                Icon(
                                  Icons.local_fire_department,
                                  size: 16,
                                  color: PRIMARY_COLOR,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  roastDateStr,
                                  style: TextStyle(
                                    color: TEXT_COLOR,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
