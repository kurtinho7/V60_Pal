import 'package:flutter/material.dart';
import 'package:v60pal/JournalEntryViewScreen.dart';
import 'package:v60pal/Theme.dart';
import 'package:v60pal/models/BrewGuardrails.dart';
import 'package:v60pal/models/JournalEntry.dart';
import 'package:v60pal/models/Journal.dart';
import 'package:v60pal/services/BeansService.dart';
import 'package:v60pal/services/JournalEntryService.dart';
import 'package:v60pal/widgets/app_ui.dart';

import 'ApiClient.dart';
import 'package:provider/provider.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  late final ApiClient api;
  late final BeansService beansSvc;
  late final JournalService journalSvc;

  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    api = ApiClient(apiBaseUrl); // replace in prod
    beansSvc = BeansService(api);
    journalSvc = JournalService(api);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      // If you also want to sync the provider here, expose a Journal.reloadFromApi()
      await Future<void>.delayed(
        const Duration(milliseconds: 250),
      ); // tiny grace for nicer spinner
    } catch (e) {
      error = e.toString();
    } finally {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _deleteAt(BuildContext context, int reversedIndex) async {
    final journal = context.read<Journal>();
    final removed = journal.entries[journal.entries.length - 1 - reversedIndex];
    final removedIdx = reversedIndex;

    // Optimistic local removal
    await journal.removeEntry(removedIdx);
    try {
      if (removed.id.isNotEmpty) {
        await journalSvc.delete(removed.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Entry deleted'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              // naive undo to end; adapt if you want same position
              await journal.addEntry(removed);
            },
          ),
        ),
      );
    } catch (e) {
      // rollback on API failure
      await journal.addEntry(removed);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final journal = context.watch<Journal>();
    final entries = List<JournalEntry>.from(journal.entries); // newest first

    return Scaffold(
      backgroundColor: BACKGROUND_COLOR,
      body: RefreshIndicator(
        onRefresh: _load,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Builder(
            builder: (_) {
              if (loading) {
                return const _JournalSkeletonList();
              }
              if (error != null) {
                return _ErrorState(message: error!, onRetry: _load);
              }
              if (entries.isEmpty) {
                return const _EmptyState();
              }

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final entry = entries[i];
                  final recipeLabel = entry.recipeId?.isNotEmpty == true
                      ? entry.recipeId!
                      : 'Custom recipe';

                  return Dismissible(
                    key: ValueKey(
                      entry.id.isNotEmpty
                          ? entry.id
                          : '${entry.date.microsecondsSinceEpoch}_${i}',
                    ),
                    direction: DismissDirection.endToStart,
                    dismissThresholds: const {
                      DismissDirection.endToStart: 0.35,
                    },
                    background: const SizedBox.shrink(),
                    secondaryBackground: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(APP_RADIUS),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerRight,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.delete, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Delete Entry',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    confirmDismiss: (dir) async {
                      final ok =
                          await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text('Delete this entry?'),
                              content: Text(
                                'This cannot be undone (unless you tap UNDO).',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          ) ??
                          false;

                      if (!ok) return false;

                      _deleteAt(context, entries.length - 1 - i);

                      return true;
                    },
                    onDismissed: (_) {},
                    child: _JournalCard(
                      month: MONTHS[entry.date.month - 1],
                      day: entry.date.day.toString(),
                      title: recipeLabel,
                      rating: entry.rating ?? 0,
                      tempC: entry.waterTemp,
                      timeSec: entry.timeTaken,
                      grind: entry.grindSetting ?? '',
                      notes: entry.notes ?? '',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                JournalEntryViewScreen(journalEntry: entry),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _JournalCard extends StatelessWidget {
  final String month;
  final String day;
  final String title;
  final double rating;
  final int? tempC;
  final int? timeSec;
  final String grind;
  final String notes;
  final VoidCallback onTap;

  const _JournalCard({
    required this.month,
    required this.day,
    required this.title,
    required this.rating,
    required this.tempC,
    required this.timeSec,
    required this.grind,
    required this.notes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final duration = Duration(seconds: timeSec ?? 0);
    final mm = duration.inMinutes.remainder(60).toString().padLeft(1, '0');
    final ss = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(APP_RADIUS),
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
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DateBadge(month: month.substring(0, 3).toUpperCase(), day: day),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: TEXT_COLOR,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: MUTED_TEXT_COLOR),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Rating
                  if (rating > 0)
                    Row(
                      children: List.generate(5, (i) {
                        final filled = rating >= i + 1;
                        final half = !filled && (rating - i) >= 0.5;
                        return Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: Icon(
                            filled
                                ? Icons.star
                                : (half ? Icons.star_half : Icons.star_border),
                            size: 16,
                            color: PRIMARY_COLOR,
                          ),
                        );
                      }),
                    ),
                  if (rating > 0) const SizedBox(height: 8),
                  // Chips row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SpecChip(
                        icon: Icons.local_fire_department,
                        label: BrewGuardrails.isPlausibleWaterTemp(tempC)
                            ? '$tempC°C'
                            : '—',
                      ),
                      _SpecChip(
                        icon: Icons.timer_outlined,
                        label: (timeSec ?? 0) > 0 ? '$mm:$ss' : '—',
                      ),
                      _SpecChip(
                        icon: Icons.settings,
                        label: grind.isNotEmpty ? grind : '—',
                      ),
                    ],
                  ),
                  // Notes (one line)
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      notes,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: TEXT_COLOR.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  final String month;
  final String day;
  const _DateBadge({required this.month, required this.day});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: BUTTON_COLOR,
        borderRadius: BorderRadius.circular(APP_RADIUS),
        border: Border.all(color: OUTLINE_COLOR),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            month,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: PRIMARY_COLOR,
            ),
          ),
          Text(
            day,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: TEXT_COLOR,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SpecChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: SURFACE_TINT_COLOR,
        borderRadius: BorderRadius.circular(APP_RADIUS),
        border: Border.all(color: OUTLINE_COLOR),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: PRIMARY_COLOR),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: TEXT_COLOR,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppEmptyState(
        icon: Icons.coffee_outlined,
        title: 'No journal entries yet',
        message: 'Add one from the brew screen after your next cup.',
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: MUTED_TEXT_COLOR),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _JournalSkeletonList extends StatelessWidget {
  const _JournalSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (_, __) => Container(
        height: 96,
        decoration: BoxDecoration(
          color: SURFACE_COLOR,
          border: Border.all(color: OUTLINE_COLOR),
          borderRadius: BorderRadius.circular(APP_RADIUS),
        ),
      ),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemCount: 6,
    );
  }
}
