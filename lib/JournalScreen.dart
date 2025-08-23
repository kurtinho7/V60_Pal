import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:v60pal/JournalEntryViewScreen.dart';
import 'package:v60pal/Theme.dart';
import 'package:v60pal/models/JournalEntry.dart';
import 'package:v60pal/models/Journal.dart';
import 'package:v60pal/services/BeansService.dart';
import 'package:v60pal/services/JournalEntryService.dart';

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
    api = ApiClient('http://10.0.2.2:3000'); // replace in prod
    beansSvc = BeansService(api);
    journalSvc = JournalService(api);
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      // If you also want to sync the provider here, expose a Journal.reloadFromApi()
      await Future<void>.delayed(const Duration(milliseconds: 250)); // tiny grace for nicer spinner
    } catch (e) {
      error = e.toString();
    } finally {
      if (!mounted) return;
      setState(() { loading = false; });
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final journal = context.watch<Journal>();
    final entries = List<JournalEntry>.from(journal.entries.reversed); // newest first

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Builder(
            builder: (_) {
              if (loading) {
                return const _JournalSkeletonList();
              }
              if (error != null) {
                return _ErrorState(
                  message: error!,
                  onRetry: _load,
                );
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
                    key: Key('jrnl-${entry.date.toIso8601String()}'),
                    direction: DismissDirection.endToStart,
                    dismissThresholds: const { DismissDirection.endToStart: 0.35 },
                    background: const SizedBox.shrink(),
                    secondaryBackground: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerRight,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.delete, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Delete Entry', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    confirmDismiss: (dir) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete this entry?'),
                          content: const Text('This cannot be undone (unless you tap UNDO).'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                          ],
                        ),
                      ) ?? false;
                    },
                    onDismissed: (_) => _deleteAt(context, entries.length - 1 - i),
                    child: _JournalCard(
                      month: MONTHS[entry.date.month],
                      day: entry.date.day.toString(),
                      title: recipeLabel,
                      rating: entry.rating!,
                      tempC: entry.waterTemp!,
                      timeSec: entry.timeTaken!,
                      grind: entry.grindSetting!,
                      notes: entry.notes!,
                      onTap: () {
                        Navigator.push(
                          context,
                          ModalBottomSheetRoute(
                            builder: (context) => JournalEntryViewScreen(journalEntry: entry),
                            isScrollControlled: true,
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
  final int tempC;
  final int timeSec;
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
    final duration = Duration(seconds: timeSec);
    final mm = duration.inMinutes.remainder(60).toString().padLeft(1, '0');
    final ss = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white10,
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(blurRadius: 6, offset: Offset(0, 3), color: Colors.black26)],
        ),
        padding: const EdgeInsets.all(14),
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
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right),
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
                            filled ? Icons.star : (half ? Icons.star_half : Icons.star_border),
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
                      _SpecChip(icon: Icons.local_fire_department, label: '${tempC > 0 ? '$tempC°C' : '—'}'),
                      _SpecChip(icon: Icons.timer_outlined, label: timeSec > 0 ? '$mm:$ss' : '—'),
                      _SpecChip(icon: Icons.settings, label: grind.isNotEmpty ? grind : '—'),
                    ],
                  ),
                  // Notes (one line)
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      notes,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: TEXT_COLOR.withOpacity(0.85), fontSize: 13),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(month, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
          Text(day, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
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
        color: Colors.white12,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
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
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            const Icon(Icons.coffee_outlined, size: 56),
            const SizedBox(height: 12),
            Text('No journal entries yet', style: TextStyle(color: TEXT_COLOR, fontSize: 16)),
            const SizedBox(height: 6),
            Text('Add one from the brew screen after your next cup ☕', style: TextStyle(color: Colors.white70)),
          ],
        ),
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
            Text('Something went wrong', style: TextStyle(color: TEXT_COLOR, fontSize: 16)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
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
          color: Colors.white10,
          border: Border.all(color: Colors.white12),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemCount: 6,
    );
  }
}
