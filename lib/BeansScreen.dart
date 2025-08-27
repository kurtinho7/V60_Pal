import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:v60pal/ApiClient.dart';
import 'package:v60pal/Theme.dart';
import 'package:v60pal/models/Beans.dart';
import 'package:v60pal/models/BeansList.dart';
import 'package:intl/intl.dart';
import 'package:v60pal/services/BeansService.dart';

enum BeansAction { edit, delete }

class BeansScreen extends StatefulWidget {
  const BeansScreen({super.key});

  @override
  State<BeansScreen> createState() => _BeansScreenState();
}

class _BeansScreenState extends State<BeansScreen> {
  // How many days until beans are considered "0% fresh".
  static const int freshnessWindowDays = 30;

  late ApiClient api;
  late BeansService beansSvc;

  TextEditingController editController = TextEditingController();

  @override
  void initState() {
    super.initState();
    api = ApiClient('http://10.0.2.2:3000');
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
    return Color.lerp(Colors.red, Colors.green, pct) ?? Colors.green;
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
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
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
      body: beans.isEmpty
          ? Center(
              child: Text(
                'No beans yet.\nTap + to add your first bag!',
                textAlign: TextAlign.center,
                style: TextStyle(color: TEXT_COLOR, fontSize: 16),
              ),
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
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final action = await showBeansActions(context, b);
                        if (action == null) return;

                        switch (action) {
                          case BeansAction.edit:
                            await showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(
                                  'Edit Beans Amount',
                                  style: TextStyle(color: TEXT_COLOR),
                                ),
                                content: TextField(
                                  controller: editController,
                                  style: TextStyle(color: TEXT_COLOR),
                                  decoration: InputDecoration(
                                    hintText: 'New Amount (g)',
                                    hintStyle: const TextStyle(
                                      color: Colors.white38,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () {
                                      print('${b.id} is the bean id');
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
                          color: Colors.white10,
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 6,
                              offset: Offset(0, 3),
                              color: Colors.black26,
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
                                      fontWeight: FontWeight.w700,
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
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white24),
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
                                color: TEXT_COLOR.withOpacity(0.85),
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
                                      backgroundColor: Colors.white.withOpacity(
                                        0.10,
                                      ),
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
                                        color: TEXT_COLOR.withValues(
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
                                        color: TEXT_COLOR,
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
                                  color: TEXT_COLOR,
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
