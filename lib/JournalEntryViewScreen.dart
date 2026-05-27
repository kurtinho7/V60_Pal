import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:v60pal/ApiClient.dart';
import 'package:v60pal/Theme.dart';
import 'package:v60pal/models/Beans.dart';
import 'package:v60pal/models/Journal.dart';
import 'package:v60pal/models/JournalEntry.dart';
import 'package:v60pal/models/Recipe.dart';
import 'package:v60pal/services/JournalEntryService.dart';

class JournalEntryViewScreen extends StatefulWidget {
  final JournalEntry journalEntry;
  const JournalEntryViewScreen({super.key, required this.journalEntry});

  @override
  State<JournalEntryViewScreen> createState() => _JournalEntryViewScreenState();
}

class _JournalEntryViewScreenState extends State<JournalEntryViewScreen> {
  late JournalEntry _entry;
  late final JournalService _journalSvc;
  bool _loadingFeedback = false;
  String? _feedbackError;
  Map<String, dynamic>? _aiProfile;

  @override
  void initState() {
    super.initState();
    _entry = widget.journalEntry;
    _journalSvc = JournalService(ApiClient(apiBaseUrl));
    _loadAiProfile();
  }

  Future<void> _loadAiProfile() async {
    if (_entry.id.isEmpty) return;
    try {
      final profile = await _journalSvc.getAiProfile();
      if (!mounted) return;
      setState(() {
        _aiProfile = profile;
      });
    } catch (e) {
      debugPrint('AI profile load failed: $e');
    }
  }

  Recipe? _recipeFor(JournalEntry entry) {
    final recipeName = entry.recipeId ?? entry.recipe?.name;
    if (recipeName == null || recipeName.isEmpty) return null;
    for (final recipe in RECIPES) {
      if (recipe.name == recipeName || recipe.id == recipeName) return recipe;
    }
    return entry.recipe;
  }

  Map<String, dynamic>? _recipeContext() {
    final recipe = _recipeFor(_entry);
    if (recipe == null) return null;
    return recipe.toJson();
  }

  Future<void> _generateFeedback() async {
    if (_entry.id.isEmpty) {
      setState(() {
        _feedbackError =
            'Save this journal entry online before generating AI feedback.';
      });
      return;
    }

    setState(() {
      _loadingFeedback = true;
      _feedbackError = null;
    });

    try {
      final updated = await _journalSvc.generateAiFeedback(
        _entry.id,
        recipeContext: _recipeContext(),
      );
      if (!mounted) return;
      final entryJson = updated['entry'] is Map
          ? Map<String, dynamic>.from(updated['entry'] as Map)
          : updated;
      final updatedEntry = JournalEntry.fromApi(entryJson);
      final profile = updated['aiProfile'] is Map
          ? Map<String, dynamic>.from(updated['aiProfile'] as Map)
          : null;
      await context.read<Journal>().updateEntry(updatedEntry);
      if (!mounted) return;
      setState(() {
        _entry = updatedEntry;
        _aiProfile = profile ?? _aiProfile;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _feedbackError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingFeedback = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = _entry;
    final recipe = _recipeFor(entry);
    final recipeId = entry.recipeId?.isNotEmpty == true
        ? entry.recipeId!
        : 'Custom recipe';
    final rating = entry.rating ?? 0;
    final notes = entry.notes ?? '';
    final dose = entry.coffeeDose?.isNotEmpty == true
        ? entry.coffeeDose!
        : recipe?.coffeeDose ?? '0g';
    final water = entry.waterWeightGrams ?? recipe?.waterWeightGrams ?? 0;
    final time = entry.timeTaken ?? 0;
    final grind = entry.grindSetting ?? '';
    final temp = entry.waterTemp ?? 0;
    final beans =
        entry.beans ??
        Beans(
          id: '',
          name: '',
          origin: '',
          roastLevel: '',
          roastDate: DateTime(0, 0, 0, 0, 0, 0),
          weight: 0,
          notes: '',
        );

    return Material(
      color: BACKGROUND_COLOR,
      child: SafeArea(
        child: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionCard(
                  color: BUTTON_COLOR.withValues(alpha: 0.55),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rating',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          RatingBar(
                            ignoreGestures: true,
                            initialRating: rating,
                            minRating: 0.5,
                            direction: Axis.horizontal,
                            allowHalfRating: true,
                            itemCount: 5,
                            itemSize: 28,
                            itemPadding: const EdgeInsets.symmetric(
                              horizontal: 1,
                            ),
                            ratingWidget: RatingWidget(
                              full: Icon(Icons.star, color: PRIMARY_COLOR),
                              half: Icon(Icons.star_half, color: PRIMARY_COLOR),
                              empty: Icon(
                                Icons.star_border,
                                color: PRIMARY_COLOR,
                              ),
                            ),
                            onRatingUpdate: (_) {},
                          ),
                        ],
                      ),
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(notes),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text('Recipe', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _SectionCard(
                  child: Column(
                    children: [
                      _DetailRow(label: 'Recipe', value: recipeId),
                      _DetailRow(label: 'Dose', value: dose),
                      _DetailRow(
                        label: 'Water',
                        value:
                            '${water.toStringAsFixed(water.truncateToDouble() == water ? 0 : 1)}g',
                      ),
                      _DetailRow(label: 'Time Taken', value: '${time}s'),
                      _DetailRow(label: 'Grind Setting', value: grind),
                      _DetailRow(label: 'Water Temp', value: '$temp C'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text('Beans', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _SectionCard(
                  child: Column(
                    children: [
                      _DetailRow(
                        label: 'Beans',
                        value: beans.name.isEmpty
                            ? 'None selected'
                            : beans.name,
                      ),
                      if (beans.origin?.isNotEmpty == true)
                        _DetailRow(label: 'Origin', value: beans.origin!),
                      if (beans.roastLevel?.isNotEmpty == true)
                        _DetailRow(label: 'Roast', value: beans.roastLevel!),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'AI Feedback',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _AiFeedbackCard(
                  feedback: entry.aiFeedback,
                  model: entry.aiFeedbackModel,
                  generatedAt: entry.aiFeedbackGeneratedAt,
                  aiProfile: _aiProfile,
                  loading: _loadingFeedback,
                  error: _feedbackError,
                  onGenerate: _generateFeedback,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  final Color? color;

  const _SectionCard({required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? SURFACE_COLOR,
        border: Border.all(color: OUTLINE_COLOR),
        borderRadius: BorderRadius.circular(APP_RADIUS),
      ),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(color: MUTED_TEXT_COLOR, fontSize: 15),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              softWrap: true,
              style: TextStyle(color: TEXT_COLOR, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiFeedbackCard extends StatelessWidget {
  final Map<String, dynamic>? feedback;
  final String? model;
  final DateTime? generatedAt;
  final Map<String, dynamic>? aiProfile;
  final bool loading;
  final String? error;
  final VoidCallback onGenerate;

  const _AiFeedbackCard({
    required this.feedback,
    required this.model,
    required this.generatedAt,
    required this.aiProfile,
    required this.loading,
    required this.error,
    required this.onGenerate,
  });

  List<String> _stringList(String key) {
    return (aiProfile?[key] as List?)
            ?.whereType<String>()
            .where((item) => item.trim().isNotEmpty)
            .toList() ??
        [];
  }

  @override
  Widget build(BuildContext context) {
    final hasFeedback = feedback != null;
    final recommendations =
        (feedback?['recommendations'] as List?)
            ?.whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList() ??
        [];
    final nextRecipe = feedback?['nextBrewRecipe'] is Map
        ? Map<String, dynamic>.from(feedback!['nextBrewRecipe'] as Map)
        : <String, dynamic>{};
    final tastePreferences = _stringList('tastePreferences');
    final successfulPatterns = _stringList('successfulPatterns');
    final recurringIssues = _stringList('recurringIssues');
    final beanPreferences = _stringList('beanPreferences');
    final nextFocus = aiProfile?['nextFocus'] as String?;
    final hasProfile =
        tastePreferences.isNotEmpty ||
        successfulPatterns.isNotEmpty ||
        recurringIssues.isNotEmpty ||
        beanPreferences.isNotEmpty ||
        (nextFocus?.trim().isNotEmpty ?? false);

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasFeedback) ...[
            Text(
              feedback!['summary'] as String? ?? '',
              style: TextStyle(
                color: TEXT_COLOR,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              feedback!['tasteDiagnosis'] as String? ?? '',
              style: TextStyle(color: TEXT_COLOR.withValues(alpha: 0.86)),
            ),
            const SizedBox(height: 14),
            ...recommendations.map((rec) => _RecommendationTile(rec: rec)),
            if (nextRecipe.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Next Brew',
                style: TextStyle(
                  color: TEXT_COLOR,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              _DetailRow(
                label: 'Temp',
                value: '${nextRecipe['temperature'] ?? '-'}',
              ),
              _DetailRow(
                label: 'Grind',
                value: '${nextRecipe['grindSize'] ?? '-'}',
              ),
              _DetailRow(
                label: 'Time',
                value: '${nextRecipe['brewTime'] ?? '-'}',
              ),
              _DetailRow(
                label: 'Pours',
                value: '${nextRecipe['pours'] ?? '-'}',
              ),
              _DetailRow(
                label: 'Dose',
                value: '${nextRecipe['coffeeDose'] ?? '-'}',
              ),
              _DetailRow(
                label: 'Water',
                value: '${nextRecipe['waterAmount'] ?? '-'}',
              ),
            ],
            if (hasProfile) ...[
              const SizedBox(height: 14),
              _AiProfileSummary(
                tastePreferences: tastePreferences,
                successfulPatterns: successfulPatterns,
                recurringIssues: recurringIssues,
                beanPreferences: beanPreferences,
                nextFocus: nextFocus ?? '',
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Confidence: ${feedback!['confidence'] ?? '-'}',
              style: TextStyle(
                color: TEXT_COLOR.withValues(alpha: 0.68),
                fontSize: 12,
              ),
            ),
            if (model != null || generatedAt != null)
              Text(
                [
                  if (model != null) model,
                  if (generatedAt != null)
                    generatedAt!.toLocal().toString().split('.').first,
                ].join(' | '),
                style: TextStyle(
                  color: TEXT_COLOR.withValues(alpha: 0.52),
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 14),
          ] else ...[
            Text(
              'Get personalized ideas for your next brew based on this log.',
              style: TextStyle(color: TEXT_COLOR.withValues(alpha: 0.82)),
            ),
            if (hasProfile) ...[
              const SizedBox(height: 14),
              _AiProfileSummary(
                tastePreferences: tastePreferences,
                successfulPatterns: successfulPatterns,
                recurringIssues: recurringIssues,
                beanPreferences: beanPreferences,
                nextFocus: nextFocus ?? '',
              ),
            ],
          ],
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(error!, style: const TextStyle(color: Colors.redAccent)),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: loading ? null : onGenerate,
            icon: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              hasFeedback ? 'Regenerate Feedback' : 'Get AI Feedback',
            ),
          ),
        ],
      ),
    );
  }
}

class _AiProfileSummary extends StatelessWidget {
  final List<String> tastePreferences;
  final List<String> successfulPatterns;
  final List<String> recurringIssues;
  final List<String> beanPreferences;
  final String nextFocus;

  const _AiProfileSummary({
    required this.tastePreferences,
    required this.successfulPatterns,
    required this.recurringIssues,
    required this.beanPreferences,
    required this.nextFocus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BUTTON_COLOR.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OUTLINE_COLOR),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What I've learned",
            style: TextStyle(color: TEXT_COLOR, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _ProfileLine(label: 'Taste', values: tastePreferences),
          _ProfileLine(label: 'Works well', values: successfulPatterns),
          _ProfileLine(label: 'Watch', values: recurringIssues),
          _ProfileLine(label: 'Beans', values: beanPreferences),
          if (nextFocus.trim().isNotEmpty)
            _DetailRow(label: 'Next focus', value: nextFocus),
        ],
      ),
    );
  }
}

class _ProfileLine extends StatelessWidget {
  final String label;
  final List<String> values;

  const _ProfileLine({required this.label, required this.values});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    return _DetailRow(label: label, value: values.join(', '));
  }
}

class _RecommendationTile extends StatelessWidget {
  final Map<String, dynamic> rec;

  const _RecommendationTile({required this.rec});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${rec['parameter'] ?? 'Adjustment'}',
            style: TextStyle(color: TEXT_COLOR, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '${rec['currentValue'] ?? '-'} -> ${rec['suggestedChange'] ?? '-'}',
            style: TextStyle(color: PRIMARY_COLOR, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '${rec['reason'] ?? ''}',
            style: TextStyle(color: TEXT_COLOR.withValues(alpha: 0.82)),
          ),
        ],
      ),
    );
  }
}
